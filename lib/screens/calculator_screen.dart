import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/calculator_data.dart';
import '../services/calculator_service.dart';
import 'pdf_generation_screen.dart';
import 'settings_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  CalculatorConfig? _config;
  String? _selectedSize;
  String? _selectedFitting;
  bool _isLoading = true;
  double _pipeLength = 1.0; // Default 1 meter
  final _additionalPriceController = TextEditingController();
  final _discountController = TextEditingController();
  final _pipeLengthController = TextEditingController();
  StreamSubscription<CalculatorConfig?>? _configSubscription;

  // Read discount/additional from the synced config
  double get _discountPercentage => _config?.discountPercentage ?? 0.0;
  double get _additionalPricePercentage =>
      _config?.additionalPricePercentage ?? 0.0;

  @override
  void initState() {
    super.initState();
    _pipeLengthController.text = _pipeLength.toString();
    _loadConfig();
    // Subscribe to real-time config updates from Firebase
    _configSubscription = CalculatorService.configStream().listen(
      (config) {
        if (config != null && mounted) {
          setState(() {
            _config = config;
            _isLoading = false;
            // Reset fitting selection if the selected size no longer exists
            if (_selectedSize != null &&
                !config.sizes.any((s) => s.size == _selectedSize)) {
              _selectedSize = null;
              _selectedFitting = null;
            }
            // Reset fitting if it no longer exists under the selected size
            if (_selectedSize != null && _selectedFitting != null) {
              final sizeData =
                  config.sizes
                      .where((s) => s.size == _selectedSize)
                      .firstOrNull;
              if (sizeData != null &&
                  !sizeData.fittings.any(
                    (f) => f.fitting == _selectedFitting,
                  )) {
                _selectedFitting = null;
              }
            }
          });
        }
      },
      onError: (e) {
        print('Config stream error: $e');
      },
    );
  }

  Future<void> _loadConfig() async {
    try {
      var config = await CalculatorService.loadConfig();
      if (config == null) {
        config = CalculatorService.getDefaultConfig();
        await CalculatorService.saveConfig(config);
      }
      print('Loaded config with ${config.sizes.length} sizes');
      if (mounted) {
        // Check if widget is still mounted before setState
        setState(() {
          _config = config;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading config: $e');
      if (mounted) {
        // Check if widget is still mounted before setState
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading configuration: $e')),
        );
      }
    }
  }

  void _onSizeChanged(String? size) {
    setState(() {
      _selectedSize = size;
      _selectedFitting = null; // Reset fitting when size changes
    });
  }

  void _onFittingChanged(String? fitting) {
    setState(() {
      _selectedFitting = fitting;
    });
  }

  static Route<T> _createRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  void _resetCalculation() {
    setState(() {
      _selectedSize = null;
      _selectedFitting = null;
      _pipeLength = 1.0;
      _pipeLengthController.text = _pipeLength.toString();
      _additionalPriceController.clear();
      _discountController.clear();
      // Reset discount & additional in config and sync to Firebase
      if (_config != null) {
        _config!.discountPercentage = 0.0;
        _config!.additionalPricePercentage = 0.0;
        CalculatorService.saveConfig(_config!);
      }
    });

    // Show a brief confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Calculator reset successfully'),
          ],
        ),
        backgroundColor: const Color(0xFF27AE60),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  double get _total {
    if (_config == null || _selectedSize == null || _selectedFitting == null)
      return 0.0;

    final sizeData = _getSelectedSizeData()!;
    final fittingData = _getSelectedFittingData()!;

    double baseTotal = CalculatorService.calculateTotal(
      sizeData.price,
      fittingData.price,
      _config!.profitMargin,
      _pipeLength,
    );

    // Apply additional price percentage
    baseTotal += baseTotal * (_additionalPricePercentage / 100);

    // Apply discount
    baseTotal -= baseTotal * (_discountPercentage / 100);

    return baseTotal;
  }

  bool get _hasAdjustments {
    return _additionalPricePercentage != 0.0 || _discountPercentage != 0.0;
  }

  double get _baseTotal {
    if (_config == null || _selectedSize == null || _selectedFitting == null)
      return 0.0;

    final sizeData = _getSelectedSizeData()!;
    final fittingData = _getSelectedFittingData()!;

    return CalculatorService.calculateTotal(
      sizeData.price,
      fittingData.price,
      _config!.profitMargin,
      _pipeLength,
    );
  }

  double get _discountAmount {
    return _baseTotal * (_discountPercentage / 100);
  }

  double get _additionalAmount {
    return _baseTotal * (_additionalPricePercentage / 100);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFF1C40F)),
          ),
        ),
      );
    }

    if (_config == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
            ),
          ),
          child: const Center(
            child: Text(
              'Failed to load configuration',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      );
    }

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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
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
                                'HATIM TRADING CO.',
                                style: TextStyle(
                                  color: Color(0xFF2C3E50),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'CALCULATOR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () {
                                if (_config == null) return;
                                Navigator.push(
                                  context,
                                  _createRoute(
                                    PdfGenerationScreen(config: _config!),
                                  ),
                                );
                              },
                              tooltip: 'Generate Price List PDF',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: _resetCalculation,
                              tooltip: 'Reset Calculator',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  _createRoute(
                                    SettingsScreen(config: _config!),
                                  ),
                                );
                                if (result != null) {
                                  // Reload config asynchronously
                                  _loadConfig();
                                }
                              },
                              tooltip: 'Settings',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter the pipe size and fitting. The total price will be calculated automatically.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Size Selection
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
                              const Text(
                                'Select Pipe Size',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedSize,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    hintText: 'Choose Pipe size',
                                    hintStyle: TextStyle(color: Colors.grey),
                                  ),
                                  items:
                                      _config!.sizes.map((size) {
                                        return DropdownMenuItem(
                                          value: size.size,
                                          child: Text(
                                            size.size,
                                            style: const TextStyle(
                                              color: Color(0xFF2C3E50),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: _onSizeChanged,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Fittings Selection
                        if (_selectedSize != null) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C3E50),
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
                                const Text(
                                  'Select Fitting',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF1C40F),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedFitting,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      hintText: 'Choose fitting type',
                                      hintStyle: TextStyle(color: Colors.grey),
                                    ),
                                    items:
                                        _getSelectedSizeData()!.fittings
                                            .where((f) => f.price > 0)
                                            .map((fitting) {
                                              return DropdownMenuItem(
                                                value: fitting.fitting,
                                                child: Text(
                                                  fitting.fitting,
                                                  style: const TextStyle(
                                                    color: Color(0xFF2C3E50),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                    onChanged: _onFittingChanged,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Pipe Length Input
                        if (_selectedSize != null &&
                            _selectedFitting != null) ...[
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
                                    Text(
                                      'Pipe Length',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: TextFormField(
                                    controller: _pipeLengthController,
                                    keyboardType: TextInputType.number,
                                    onTapOutside: (_) {
                                      FocusScope.of(context).unfocus();
                                    },
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
                                      hintText: 'Enter pipe length',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      suffixText: 'meters',
                                      prefixIcon: Icon(
                                        Icons.straighten,
                                        color: Color(0xFF9B59B6),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _pipeLength =
                                            double.tryParse(value) ?? 1.0;
                                        if (_pipeLength <= 0) _pipeLength = 1.0;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Total Price Display
                        if (_selectedSize != null &&
                            _selectedFitting != null) ...[
                          Container(
                            constraints: const BoxConstraints(minHeight: 180),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Total Price',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '₹${_total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_hasAdjustments) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (_discountPercentage > 0) ...[
                                          const Icon(
                                            Icons.local_offer,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Discount ${_discountPercentage.toStringAsFixed(1)}% Applied',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 80), // Space for FAB
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                _hasAdjustments
                    ? [const Color(0xFFE74C3C), const Color(0xFFC0392B)]
                    : [const Color(0xFFF1C40F), const Color(0xFFF39C12)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAdjustmentsDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            children: [
              const Icon(Icons.tune, color: Colors.white, size: 28),
              if (_hasAdjustments)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '!',
                      style: TextStyle(
                        color: Color(0xFFE74C3C),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPriceListDialog() {
    if (_config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration is not ready yet')),
      );
      return;
    }

    final customerNameController = TextEditingController();
    final discountController = TextEditingController(text: '0');
    final additionalController = TextEditingController(text: '0');
    final profitMarginController = TextEditingController(
      text: (_config!.profitMargin * 100).toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Text(
              'Generate Personalized Price List',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          titlePadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                TextField(
                  controller: customerNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    hintText: 'Enter customer name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Discount (%)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixText: '%',
                    prefixIcon: const Icon(
                      Icons.local_offer_outlined,
                      color: Color(0xFFE74C3C),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: additionalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Additional Amount (%)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixText: '%',
                    prefixIcon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: profitMarginController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Profit Margin (%)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixText: '%',
                    prefixIcon: const Icon(
                      Icons.trending_up,
                      color: Color(0xFFF39C12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1C40F).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1C40F)),
                  ),
                  child: const Text(
                    'These values are only for this PDF and will not update app settings or live rates.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF2C3E50)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
                onPressed: () async {
                  final customerName = customerNameController.text.trim();
                  if (customerName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter customer name'),
                      ),
                    );
                    return;
                  }

                  final discount = (double.tryParse(discountController.text) ??
                          0.0)
                      .clamp(0.0, 100.0);
                  final additional =
                      (double.tryParse(additionalController.text) ?? 0.0).clamp(
                        0.0,
                        100.0,
                      );
                  final marginPercent =
                      (double.tryParse(profitMarginController.text) ?? 0.0)
                          .clamp(0.0, 300.0);

                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                  }

                  await _generateAndSharePriceListPdf(
                    customerName: customerName,
                    discountPercentage: discount,
                    additionalPercentage: additional,
                    profitMarginFraction: marginPercent / 100,
                  );
                },
                child: const Text(
                  'Generate & Share',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateAndSharePriceListPdf({
    required String customerName,
    required double discountPercentage,
    required double additionalPercentage,
    required double profitMarginFraction,
  }) async {
    if (_config == null) return;

    final pdf = pw.Document();
    final rows = <List<String>>[];
    final generatedOn = _formatDate(DateTime.now());
    const shopName = 'HATIM TRADING CO.';
    const leftAddress =
        'SHOP No.7, Nikisha Arcade, Below Canara Bank, Goddev Fatak Road, Bhayandar (East)';
    const rightAddress =
        'SHOP No.3, Priti Apt, Near Meera Banquet Hall, Mira Bhayander Road, Bhayandar (East)';
    pw.MemoryImage? logoImage;

    try {
      final logoBytes = await rootBundle.load('assets/shop_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      print('Failed to load shop logo for PDF: $e');
    }

    for (final size in _config!.sizes) {
      for (final fitting in size.fittings) {
        final basePrice = CalculatorService.calculateTotal(
          size.price,
          fitting.price,
          profitMarginFraction,
          1.0,
        );
        final withAdditional =
            basePrice + (basePrice * (additionalPercentage / 100));
        final finalPrice =
            withAdditional - (withAdditional * (discountPercentage / 100));
        rows.add([
          size.size,
          fitting.fitting,
          'Rs ${finalPrice.toStringAsFixed(2)}',
        ]);
      }
    }

    final primary = PdfColor.fromInt(0xFF2C3E50);
    final secondary = PdfColor.fromInt(0xFF34495E);
    final accent = PdfColor.fromInt(0xFFF1C40F);
    final white = PdfColor.fromInt(0xFFFFFFFF);
    final lightBg = PdfColor.fromInt(0xFFF6F8FA);

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      buildBackground:
          (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Center(
              child: pw.Transform.rotate(
                angle: -0.55,
                child: pw.Opacity(
                  opacity: 0.08,
                  child: pw.Text(
                    'CONFIDENTIAL',
                    style: pw.TextStyle(
                      color: PdfColors.grey500,
                      fontSize: 72,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header:
            (context) => pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                'CONFIDENTIAL',
                style: pw.TextStyle(
                  color: PdfColors.red700,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
        footer:
            (context) => pw.Container(
              margin: const pw.EdgeInsets.only(top: 12),
              padding: const pw.EdgeInsets.only(top: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey300, width: 0.7),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      leftAddress,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(
                        'Page ${context.pageNumber} of ${context.pagesCount}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        rightAddress,
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        build: (context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primary,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 48,
                          height: 48,
                          margin: const pw.EdgeInsets.only(right: 12),
                          padding: const pw.EdgeInsets.all(4),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.all(
                              pw.Radius.circular(8),
                            ),
                          ),
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                      pw.Expanded(
                        child: pw.Text(
                          shopName,
                          style: pw.TextStyle(
                            color: accent,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Personalized Price List',
                    style: pw.TextStyle(
                      color: white,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Prepared for $customerName',
                    style: pw.TextStyle(color: white, fontSize: 12),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Date: $generatedOn',
                    style: pw.TextStyle(color: white, fontSize: 11),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: secondary,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                'All rates are per 1 meter and include your personalized pricing.',
                style: pw.TextStyle(color: white, fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const ['Pipe Size', 'Fitting', 'Final Price'],
              data: rows,
              headerStyle: pw.TextStyle(
                color: primary,
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
              ),
              headerDecoration: pw.BoxDecoration(color: accent),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              rowDecoration: pw.BoxDecoration(color: lightBg),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                1: const pw.FlexColumnWidth(2.8),
                2: const pw.FlexColumnWidth(1.2),
              },
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: primary, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                'Thank you, $customerName. We are happy to serve you.',
                style: pw.TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ];
        },
      ),
    );

    try {
      final bytes = await pdf.save();
      final safeName = customerName.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'htc_hosepipe_price_list_${safeName.toLowerCase()}_${generatedOn.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  void _showAdjustmentsDialog() {
    _additionalPriceController.text = _additionalPricePercentage
        .toStringAsFixed(1);
    _discountController.text = _discountPercentage.toStringAsFixed(1);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Text(
              'Price Adjustments',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          titlePadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                TextField(
                  controller: _additionalPriceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Additional Price (%)',
                    hintText: 'Enter additional percentage',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixText: '%',
                    prefixIcon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Discount (%)',
                    hintText: 'Enter discount percentage',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixText: '%',
                    prefixIcon: const Icon(
                      Icons.remove_circle_outline,
                      color: Color(0xFFE74C3C),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_hasAdjustments)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1C40F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF1C40F)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFFF39C12),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Price adjustments will sync to all devices',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_config != null) {
                  setState(() {
                    _config!.additionalPricePercentage = 0.0;
                    _config!.discountPercentage = 0.0;
                  });
                  CalculatorService.saveConfig(_config!);
                }
                Navigator.of(context).pop();
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: Color(0xFFE74C3C)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
                onPressed: () {
                  if (_config != null) {
                    final additional = (double.tryParse(
                              _additionalPriceController.text,
                            ) ??
                            0.0)
                        .clamp(0.0, 100.0);
                    final discount =
                        (double.tryParse(_discountController.text) ?? 0.0)
                            .clamp(0.0, 100.0);
                    setState(() {
                      _config!.additionalPricePercentage = additional;
                      _config!.discountPercentage = discount;
                    });
                    // Save & auto-upload to Firebase
                    CalculatorService.saveConfig(_config!);
                  }
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Apply Changes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    _additionalPriceController.dispose();
    _discountController.dispose();
    _pipeLengthController.dispose();
    super.dispose();
  }

  SizeData? _getSelectedSizeData() {
    if (_selectedSize == null || _config == null) return null;
    return _config!.sizes.firstWhere((size) => size.size == _selectedSize);
  }

  FittingPrice? _getSelectedFittingData() {
    if (_selectedFitting == null || _selectedSize == null || _config == null)
      return null;
    final sizeData = _getSelectedSizeData()!;
    return sizeData.fittings.firstWhere(
      (fitting) => fitting.fitting == _selectedFitting,
    );
  }
}
