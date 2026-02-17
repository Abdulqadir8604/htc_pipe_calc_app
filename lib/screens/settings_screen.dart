import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/calculator_data.dart';
import '../services/calculator_service.dart';
import '../services/hive_service.dart';

class SettingsScreen extends StatefulWidget {
  final CalculatorConfig config;

  const SettingsScreen({super.key, required this.config});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late CalculatorConfig _config;
  final _profitMarginController = TextEditingController();
  final _discountController = TextEditingController();
  final _additionalPriceController = TextEditingController();
  bool _isUpdateAvailable = false;

  @override
  void initState() {
    super.initState();
    _config = CalculatorConfig(
      profitMargin: widget.config.profitMargin,
      version: widget.config.version,
      discountPercentage: widget.config.discountPercentage,
      additionalPricePercentage: widget.config.additionalPricePercentage,
      sizes:
          widget.config.sizes
              .map(
                (s) => SizeData(
                  size: s.size,
                  price: s.price,
                  fittings:
                      s.fittings
                          .map(
                            (f) => FittingPrice(
                              fitting: f.fitting,
                              price: f.price,
                            ),
                          )
                          .toList(),
                ),
              )
              .toList(),
    );
    _profitMarginController.text = (_config.profitMargin * 100).toStringAsFixed(
      0,
    );
    _discountController.text = _config.discountPercentage.toStringAsFixed(1);
    _additionalPriceController.text = _config.additionalPricePercentage
        .toStringAsFixed(1);
    _checkForUpdate();
  }

  void _checkForUpdate() {
    final newConfig = HiveService.getDefaultConfig();
    if (newConfig.version > _config.version) {
      setState(() {
        _isUpdateAvailable = true;
      });
    }
  }

  @override
  void dispose() {
    _profitMarginController.dispose();
    _discountController.dispose();
    _additionalPriceController.dispose();
    super.dispose();
  }

  void _updateProfitMargin() async {
    final value = double.tryParse(_profitMarginController.text);
    if (value != null && value >= 0 && value <= 100) {
      setState(() {
        _config.profitMargin = value / 100;
      });
      await CalculatorService.updateProfitMargin(value / 100);
    }
  }

  void _updateSizePrice(int sizeIndex, double newPrice) async {
    setState(() {
      _config.sizes[sizeIndex].price = newPrice;
    });
    await CalculatorService.updateSizePrice(
      _config.sizes[sizeIndex].size,
      newPrice,
    );
  }

  void _updateFittingPrice(
    int sizeIndex,
    int fittingIndex,
    double newPrice,
  ) async {
    setState(() {
      _config.sizes[sizeIndex].fittings[fittingIndex].price = newPrice;
    });
    await CalculatorService.updateFittingPrice(
      _config.sizes[sizeIndex].size,
      _config.sizes[sizeIndex].fittings[fittingIndex].fitting,
      newPrice,
    );
  }

  void _saveSettings() async {
    await CalculatorService.saveConfig(_config);
    if (!mounted) return;
    Navigator.pop(context, _config);
  }

  Future<void> _pushLocalTruthToFirebase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Push Local Rates to Firebase'),
            content: const Text(
              'This will overwrite Firebase rates with your local dataset values. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Overwrite'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await CalculatorService.pushLocalTruthToFirebase();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local rates pushed to Firebase successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Push failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _updateConfig() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Update'),
          content: const Text(
            'Are you sure you want to update the configuration? Your price modifications will be preserved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final newConfig = await HiveService.updateAndGetConfig();
                if (!mounted) return;
                if (newConfig != null) {
                  setState(() {
                    _config = newConfig;
                    _isUpdateAvailable = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Configuration updated successfully.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetToCodeDefaultRates() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Reset Rates To Code Defaults'),
            content: const Text(
              'This will replace all current local rates with getDefaultConfig() values. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Reset'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final defaultConfig = HiveService.getDefaultConfig();
    await CalculatorService.saveConfig(defaultConfig);
    if (!mounted) return;

    setState(() {
      _config = CalculatorConfig(
        profitMargin: defaultConfig.profitMargin,
        version: defaultConfig.version,
        discountPercentage: defaultConfig.discountPercentage,
        additionalPricePercentage: defaultConfig.additionalPricePercentage,
        sizes:
            defaultConfig.sizes
                .map(
                  (s) => SizeData(
                    size: s.size,
                    price: s.price,
                    fittings:
                        s.fittings
                            .map(
                              (f) => FittingPrice(
                                fitting: f.fitting,
                                price: f.price,
                              ),
                            )
                            .toList(),
                  ),
                )
                .toList(),
      );
      _profitMarginController.text = (_config.profitMargin * 100)
          .toStringAsFixed(0);
      _discountController.text = _config.discountPercentage.toStringAsFixed(1);
      _additionalPriceController.text = _config.additionalPricePercentage
          .toStringAsFixed(1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code default rates applied successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1C40F),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'SETTINGS',
                              style: TextStyle(
                                color: Color(0xFF2C3E50),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Price Configuration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (kDebugMode)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.cloud_upload,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Push Local Truth to Firebase',
                          onPressed: _pushLocalTruthToFirebase,
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(
                          Icons.save,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Profit Margin Setting
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF1C40F), Color(0xFFF39C12)],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.trending_up,
                                      color: Color(0xFF2C3E50),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Profit Margin Configuration',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: TextFormField(
                                    controller: _profitMarginController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      suffixText: '%',
                                      hintText:
                                          'Enter profit margin percentage',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      prefixIcon: Icon(
                                        Icons.percent,
                                        color: Color(0xFFF39C12),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                    onChanged: (_) => _updateProfitMargin(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Discount & Additional Price
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.tune,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Price Adjustments',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Synced across all devices',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Additional %',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: TextFormField(
                                              controller:
                                                  _additionalPriceController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                suffixText: '%',
                                                prefixIcon: Icon(
                                                  Icons.add_circle_outline,
                                                  color: Color(0xFF27AE60),
                                                  size: 20,
                                                ),
                                              ),
                                              style: const TextStyle(
                                                color: Color(0xFF2C3E50),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              onChanged: (value) {
                                                final v = (double.tryParse(
                                                          value,
                                                        ) ??
                                                        0.0)
                                                    .clamp(0.0, 100.0);
                                                setState(() {
                                                  _config.additionalPricePercentage =
                                                      v;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Discount %',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: TextFormField(
                                              controller: _discountController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                suffixText: '%',
                                                prefixIcon: Icon(
                                                  Icons.remove_circle_outline,
                                                  color: Color(0xFFE74C3C),
                                                  size: 20,
                                                ),
                                              ),
                                              style: const TextStyle(
                                                color: Color(0xFF2C3E50),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              onChanged: (value) {
                                                final v = (double.tryParse(
                                                          value,
                                                        ) ??
                                                        0.0)
                                                    .clamp(0.0, 100.0);
                                                setState(() {
                                                  _config.discountPercentage =
                                                      v;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Equipment Prices Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C3E50),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.build,
                                  color: Color(0xFFF1C40F),
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Equipment & Fitting Prices',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Price Settings List
                          ..._config.sizes.asMap().entries.map((sizeEntry) {
                            final sizeIndex = sizeEntry.key;
                            final size = sizeEntry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: ExpansionTile(
                                  backgroundColor: Colors.white,
                                  collapsedBackgroundColor: Colors.white,
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  childrenPadding: const EdgeInsets.all(0),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3498DB),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          size.size,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 21,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF27AE60),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '₹${size.price.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Container(
                                      color: const Color(0xFFF8F9FA),
                                      child: Column(
                                        children: [
                                          // Size Price Editor
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFE8F4FD),
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Color(0xFFDEE2E6),
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.straighten,
                                                  color: Color(0xFF3498DB),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    '${size.size} Base Price (PPM)',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF2C3E50),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: TextFormField(
                                                    initialValue: size.price
                                                        .toStringAsFixed(0),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter.allow(
                                                        RegExp(
                                                          r'^\d+\.?\d{0,2}',
                                                        ),
                                                      ),
                                                    ],
                                                    decoration: InputDecoration(
                                                      prefixText: '₹',
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 8,
                                                          ),
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                    ),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF27AE60),
                                                    ),
                                                    onChanged: (value) {
                                                      final price =
                                                          double.tryParse(
                                                            value,
                                                          );
                                                      if (price != null &&
                                                          price >= 0) {
                                                        _updateSizePrice(
                                                          sizeIndex,
                                                          price,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Fittings
                                          ...size.fittings.asMap().entries.map((
                                            entry,
                                          ) {
                                            final fittingIndex = entry.key;
                                            final fitting = entry.value;
                                            return Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color:
                                                    fittingIndex.isEven
                                                        ? Colors.white
                                                        : const Color(
                                                          0xFFF8F9FA,
                                                        ),
                                                border: const Border(
                                                  bottom: BorderSide(
                                                    color: Color(0xFFE9ECEF),
                                                    width: 0.5,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.settings,
                                                    color: Color(0xFF6C757D),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      fitting.fitting,
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF495057,
                                                        ),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 120,
                                                    child: TextFormField(
                                                      initialValue: fitting
                                                          .price
                                                          .toStringAsFixed(0),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.allow(
                                                          RegExp(
                                                            r'^\d+\.?\d{0,2}',
                                                          ),
                                                        ),
                                                      ],
                                                      decoration: InputDecoration(
                                                        prefixText: '₹',
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                      ),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFF2C3E50,
                                                        ),
                                                      ),
                                                      onChanged: (value) {
                                                        final price =
                                                            double.tryParse(
                                                              value,
                                                            );
                                                        if (price != null &&
                                                            price >= 0) {
                                                          _updateFittingPrice(
                                                            sizeIndex,
                                                            fittingIndex,
                                                            price,
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                          if (_isUpdateAvailable)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF3498DB),
                                    Color(0xFF2980B9),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: TextButton.icon(
                                onPressed: _updateConfig,
                                icon: const Icon(
                                  Icons.update,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Update Configuration',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextButton.icon(
                              onPressed: _resetToCodeDefaultRates,
                              icon: const Icon(
                                Icons.restart_alt,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Reset To Code Default Rates',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
