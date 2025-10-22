import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/calculator_data.dart';
import '../services/calculator_service.dart';
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
  double _additionalPricePercentage = 0.0;
  double _discountPercentage = 0.0;
  double _pipeLength = 1.0; // Default 1 meter
  final _additionalPriceController = TextEditingController();
  final _discountController = TextEditingController();
  final _pipeLengthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pipeLengthController.text = _pipeLength.toString();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = CalculatorService.loadConfig();
      setState(() {
        _config = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
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

  double get _total {
    if (_config == null || _selectedSize == null || _selectedFitting == null) return 0.0;
    
    final sizeData = _getSelectedSizeData()!;
    final fittingData = _getSelectedFittingData()!;
    
    double baseTotal = CalculatorService.calculateTotal(sizeData.price, fittingData.price, _config!.profitMargin, _pipeLength);
    
    // Apply additional price percentage
    baseTotal += baseTotal * (_additionalPricePercentage / 100);
    
    // Apply discount
    baseTotal -= baseTotal * (_discountPercentage / 100);
    
    return baseTotal;
  }

  bool get _hasAdjustments {
    return _additionalPricePercentage != 0.0 || _discountPercentage != 0.0;
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsScreen(config: _config!),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _config = CalculatorService.loadConfig();
                                _selectedSize = null;
                                _selectedFitting = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter the pipe size and fitting. The total price will be calculated automatically.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
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
                    padding: const EdgeInsets.all(20),
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
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    hintText: 'Choose Pipe size',
                                    hintStyle: TextStyle(color: Colors.grey),
                                  ),
                                  items: _config!.sizes.map((size) {
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
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      hintText: 'Choose fitting type',
                                      hintStyle: TextStyle(color: Colors.grey),
                                    ),
                                    items: _getSelectedSizeData()!.fittings.map((fitting) {
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
                        if (_selectedSize != null && _selectedFitting != null) ...[
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
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      hintText: 'Enter pipe length',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      suffixText: 'meters',
                                      prefixIcon: Icon(Icons.straighten, color: Color(0xFF9B59B6)),
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _pipeLength = double.tryParse(value) ?? 1.0;
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
                        if (_selectedSize != null && _selectedFitting != null) ...[
                          Container(
                            height: 200,
                            padding: const EdgeInsets.all(30),
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
                                // if (_hasAdjustments)
                                //   Container(
                                //     margin: const EdgeInsets.only(top: 12),
                                //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                //     decoration: BoxDecoration(
                                //       color: Colors.white.withOpacity(0.2),
                                //       borderRadius: BorderRadius.circular(15),
                                //     ),
                                //     child: const Text(
                                //       'Adjustments applied',
                                //       style: TextStyle(
                                //         color: Colors.white,
                                //         fontSize: 12,
                                //         fontWeight: FontWeight.w500,
                                //       ),
                                //     ),
                                //   ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 100), // Extra space for FAB
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
            colors: _hasAdjustments 
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

  void _showAdjustmentsDialog() {
    _additionalPriceController.text = _additionalPricePercentage.toStringAsFixed(1);
    _discountController.text = _discountPercentage.toStringAsFixed(1);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          titlePadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              TextField(
                controller: _additionalPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Additional Price (%)',
                  hintText: 'Enter additional percentage',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixText: '%',
                  prefixIcon: const Icon(Icons.add_circle_outline, color: Color(0xFF27AE60)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Discount (%)',
                  hintText: 'Enter discount percentage',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixText: '%',
                  prefixIcon: const Icon(Icons.remove_circle_outline, color: Color(0xFFE74C3C)),
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
                      Icon(Icons.info_outline, color: Color(0xFFF39C12), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Price adjustments are currently active',
                          style: TextStyle(fontSize: 12, color: Color(0xFF2C3E50)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _additionalPricePercentage = 0.0;
                  _discountPercentage = 0.0;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Clear All', style: TextStyle(color: Color(0xFFE74C3C))),
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
                  setState(() {
                    _additionalPricePercentage = double.tryParse(_additionalPriceController.text) ?? 0.0;
                    _discountPercentage = double.tryParse(_discountController.text) ?? 0.0;
                    
                    // Ensure values are within reasonable bounds
                    _additionalPricePercentage = _additionalPricePercentage.clamp(0.0, 100.0);
                    _discountPercentage = _discountPercentage.clamp(0.0, 100.0);
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Apply Changes', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
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
    if (_selectedFitting == null || _selectedSize == null || _config == null) return null;
    final sizeData = _getSelectedSizeData()!;
    return sizeData.fittings.firstWhere((fitting) => fitting.fitting == _selectedFitting);
  }
}