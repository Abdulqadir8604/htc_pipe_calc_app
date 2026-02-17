import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/calculator_data.dart';
import '../services/calculator_service.dart';

class PdfGenerationScreen extends StatefulWidget {
  final CalculatorConfig config;

  const PdfGenerationScreen({super.key, required this.config});

  @override
  State<PdfGenerationScreen> createState() => _PdfGenerationScreenState();
}

class _PdfGenerationScreenState extends State<PdfGenerationScreen> {
  static const List<String> _orderedFittingTypes = ['ST+ST', 'ST+90', '90+90'];
  static const List<int> _lengthOptionsMm = [
    300,
    500,
    750,
    1000,
    1250,
    1500,
    1750,
    2000,
  ];

  int _currentStep = 0;
  final _customerNameController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _additionalController = TextEditingController(text: '0');
  late final TextEditingController _profitMarginController;
  final Set<String> _selectedPipeSizes = <String>{};
  final Set<int> _selectedLengthsMm = <int>{};

  @override
  void initState() {
    super.initState();
    _profitMarginController = TextEditingController(
      text: (widget.config.profitMargin * 100).toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _discountController.dispose();
    _additionalController.dispose();
    _profitMarginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      appBar: AppBar(
        title: const Text('Generate Price List PDF'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF39C12),
              onPrimary: Color(0xFF2C3E50),
              secondary: Color(0xFFF1C40F),
              onSecondary: Color(0xFF2C3E50),
            ),
          ),
          child: Stepper(
            elevation: 0,
            margin: const EdgeInsets.all(12),
            connectorColor: WidgetStateProperty.all(
              const Color(0xFFF1C40F).withValues(alpha: 0.6),
            ),
            stepIconBuilder: (stepIndex, stepState) {
              final isCurrent = _currentStep == stepIndex;
              final isComplete = _currentStep > stepIndex;
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isComplete || isCurrent
                          ? const Color(0xFFF1C40F)
                          : Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                    color: const Color(0xFFF1C40F),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      color:
                          isComplete || isCurrent
                              ? const Color(0xFF2C3E50)
                              : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepTapped: (index) => setState(() => _currentStep = index),
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (context, details) {
              final isLast = _currentStep == 2;
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isLast
                                ? const Color(0xFF27AE60)
                                : const Color(0xFFF1C40F),
                        foregroundColor:
                            isLast ? Colors.white : const Color(0xFF2C3E50),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(isLast ? 'Preview PDF' : 'Next'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      child: Text(_currentStep == 0 ? 'Cancel' : 'Previous'),
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text(
                  'Customer & Price Inputs',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                isActive: _currentStep >= 0,
                state:
                    _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: _buildStepOne(),
              ),
              Step(
                title: const Text(
                  'Pipe Size Selection',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                isActive: _currentStep >= 1,
                state:
                    _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: _buildStepTwo(),
              ),
              Step(
                title: const Text(
                  'Fitting Length Selection (mm)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                isActive: _currentStep >= 2,
                state: StepState.indexed,
                content: _buildStepThree(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepOne() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customerNameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Customer Name',
                hintText: 'Enter customer name',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF2C3E50),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Price Adjustments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Discount',
                      suffixText: '%',
                      prefixIcon: const Icon(Icons.local_offer_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF2C3E50),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _additionalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Additional',
                      suffixText: '%',
                      prefixIcon: const Icon(Icons.add_circle_outline),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF2C3E50),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _profitMarginController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Profit Margin',
                suffixText: '%',
                prefixIcon: const Icon(Icons.trending_up),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF2C3E50),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFF1C40F).withValues(alpha: 0.15),
                border: Border.all(
                  color: const Color(0xFFF1C40F).withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFF2C3E50)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These values are for PDF only and do not update app rates.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF2C3E50)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTwo() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Pipe Sizes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  '${_selectedPipeSizes.length} selected',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        _selectedPipeSizes.isEmpty
                            ? Colors.red
                            : const Color(0xFF27AE60),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  widget.config.sizes.map((size) {
                    final isSelected = _selectedPipeSizes.contains(size.size);
                    return FilterChip(
                      label: Text(size.size),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (checked) {
                        setState(() {
                          if (checked) {
                            _selectedPipeSizes.add(size.size);
                          } else {
                            _selectedPipeSizes.remove(size.size);
                          }
                        });
                      },
                      selectedColor: const Color(
                        0xFFF1C40F,
                      ).withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color:
                            isSelected
                                ? const Color(0xFF2C3E50)
                                : const Color(0xFF6C757D),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color:
                              isSelected
                                  ? const Color(0xFFF39C12)
                                  : const Color(0xFFDEE2E6),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepThree() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Fitting Lengths',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  '${_selectedLengthsMm.length} selected',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        _selectedLengthsMm.isEmpty
                            ? Colors.red
                            : const Color(0xFF27AE60),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _lengthOptionsMm.map((mm) {
                    final isSelected = _selectedLengthsMm.contains(mm);
                    return FilterChip(
                      label: Text('$mm mm'),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (checked) {
                        setState(() {
                          if (checked) {
                            _selectedLengthsMm.add(mm);
                          } else {
                            _selectedLengthsMm.remove(mm);
                          }
                        });
                      },
                      selectedColor: const Color(
                        0xFFF1C40F,
                      ).withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color:
                            isSelected
                                ? const Color(0xFF2C3E50)
                                : const Color(0xFF6C757D),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color:
                              isSelected
                                  ? const Color(0xFFF39C12)
                                  : const Color(0xFFDEE2E6),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_customerNameController.text.trim().isEmpty) {
        _showMessage('Please enter customer name');
        return;
      }
      setState(() => _currentStep = 1);
      return;
    }

    if (_currentStep == 1) {
      if (_selectedPipeSizes.isEmpty) {
        _showMessage('Select at least one pipe size');
        return;
      }
      setState(() => _currentStep = 2);
      return;
    }

    if (_selectedLengthsMm.isEmpty) {
      _showMessage('Select at least one fitting length');
      return;
    }

    _openPdfPreview();
  }

  void _onStepCancel() {
    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _currentStep -= 1);
  }

  Future<void> _openPdfPreview() async {
    final customerName = _customerNameController.text.trim();
    final discount = (double.tryParse(_discountController.text) ?? 0.0).clamp(
      0.0,
      100.0,
    );
    final additional = (double.tryParse(_additionalController.text) ?? 0.0)
        .clamp(0.0, 100.0);
    final profitFraction =
        ((double.tryParse(_profitMarginController.text) ?? 0).clamp(
          0.0,
          300.0,
        )) /
        100;

    // Build grouped data:
    // Map<PipeSize, Map<BspSubtype, Map<FittingType, Map<Length, Price>>>>
    final pivotData = <String, Map<String, Map<String, Map<int, double>>>>{};
    final selectedSizes =
        widget.config.sizes
            .where((s) => _selectedPipeSizes.contains(s.size))
            .toList();

    for (final size in selectedSizes) {
      final bspFittings =
          size.fittings
              .where(
                (f) => f.fitting.toUpperCase().contains('BSP') && f.price > 0,
              )
              .toList();

      if (bspFittings.isEmpty) continue;

      pivotData[size.size] = {};

      for (final fitting in bspFittings) {
        final parsed = _parseBspSubtypeAndType(fitting.fitting);
        if (parsed == null) continue;
        final subtype = parsed.$1;
        final fittingType = parsed.$2;

        pivotData[size.size]!.putIfAbsent(
          subtype,
          () => <String, Map<int, double>>{},
        );
        pivotData[size.size]![subtype]!.putIfAbsent(
          fittingType,
          () => <int, double>{},
        );

        for (final mm in _selectedLengthsMm.toList()..sort()) {
          final lengthMeters = mm / 1000.0;
          final basePrice = CalculatorService.calculateTotal(
            size.price,
            fitting.price,
            profitFraction,
            lengthMeters,
          );
          final withAdditional = basePrice + (basePrice * (additional / 100));
          final finalPrice =
              withAdditional - (withAdditional * (discount / 100));
          pivotData[size.size]![subtype]![fittingType]![mm] = finalPrice;
        }
      }

      if (pivotData[size.size]!.isEmpty) {
        pivotData.remove(size.size);
      }
    }

    if (pivotData.isEmpty) {
      _showMessage(
        'No BSP fitting rows found for selected pipe sizes. Please change selection.',
      );
      return;
    }

    final generatedOn = _formatDate(DateTime.now());
    final safeName = customerName.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => _PdfPreviewScreen(
              title: 'PDF Preview',
              fileName:
                  'htc_bsp_price_list_${safeName.toLowerCase()}_${generatedOn.replaceAll(' ', '_')}.pdf',
              onBuildPdf:
                  (format) => _buildPdfBytes(
                    format: format,
                    pivotData: pivotData,
                    fittingTypes: _orderedFittingTypes,
                    selectedLengths: _selectedLengthsMm.toList()..sort(),
                    customerName: customerName,
                    generatedOn: generatedOn,
                  ),
            ),
      ),
    );
  }

  Future<Uint8List> _buildPdfBytes({
    required PdfPageFormat format,
    required Map<String, Map<String, Map<String, Map<int, double>>>> pivotData,
    required List<String> fittingTypes,
    required List<int> selectedLengths,
    required String customerName,
    required String generatedOn,
  }) async {
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/shop_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    const shopName = 'HATIM TRADING CO.';
    const leftAddress =
        'SHOP No.7, Nikisha Arcade, Below Canara Bank, Goddev Fatak Road, Bhayandar (East)';
    const rightAddress =
        'SHOP No.3, Priti Apt, Near Meera Banquet Hall, Mira Bhayander Road, Bhayandar (East)';

    final primary = PdfColor.fromInt(0xFF2C3E50);
    final secondary = PdfColor.fromInt(0xFF34495E);
    final accent = PdfColor.fromInt(0xFFF1C40F);
    final white = PdfColor.fromInt(0xFFFFFFFF);
    final lightBg = PdfColor.fromInt(0xFFF6F8FA);

    final pdf = pw.Document();
    final pageTheme = pw.PageTheme(
      pageFormat: format,
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
        build:
            (context) => [
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: primary,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
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
                      'BSP Price List',
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
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Text(
                  'Only BSP fittings are included. Lengths are selected in mm.',
                  style: pw.TextStyle(color: white, fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 16),
              // Generate grouped tables:
              // Pipe Size -> BSP Subtype -> ST+ST / ST+90 / 90+90
              ...pivotData.entries.expand((entry) {
                final pipeSize = entry.key;
                final subtypeGroups = entry.value;

                return subtypeGroups.entries.expand((subEntry) {
                  final subtype = subEntry.key;
                  final sizeData = subEntry.value;

                  final tableRows = <List<String>>[];
                  for (final mm in selectedLengths) {
                    final row = <String>['$mm'];
                    for (final fittingType in fittingTypes) {
                      final price = sizeData[fittingType]?[mm];
                      row.add(price != null ? price.toStringAsFixed(0) : '-');
                    }
                    tableRows.add(row);
                  }

                  return [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: primary,
                        borderRadius: const pw.BorderRadius.vertical(
                          top: pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Text(
                        'SIZE: $pipeSize | $subtype',
                        style: pw.TextStyle(
                          color: white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Table(
                      border: pw.TableBorder.all(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1),
                        for (var i = 0; i < fittingTypes.length; i++)
                          i + 1: const pw.FlexColumnWidth(1.2),
                      },
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: accent),
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'LENGTH\n(mm)',
                                style: pw.TextStyle(
                                  color: primary,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            ...fittingTypes.map(
                              (type) => pw.Container(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  type,
                                  style: pw.TextStyle(
                                    color: primary,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...tableRows.asMap().entries.map((rowEntry) {
                          final isEven = rowEntry.key % 2 == 0;
                          return pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: isEven ? lightBg : PdfColors.white,
                            ),
                            children:
                                rowEntry.value
                                    .map(
                                      (cell) => pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 4,
                                        ),
                                        child: pw.Text(
                                          cell,
                                          style: const pw.TextStyle(
                                            fontSize: 9,
                                            color: PdfColors.black,
                                          ),
                                          textAlign: pw.TextAlign.center,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          );
                        }),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                  ];
                });
              }),
            ],
      ),
    );

    return pdf.save();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  String? _mapFittingType(String fittingName) {
    final upper = fittingName.toUpperCase();
    if (upper.contains('ST+ST')) return 'ST+ST';
    if (upper.contains('ST+90')) return 'ST+90';
    if (upper.contains('90+90')) return '90+90';
    return null;
  }

  (String, String)? _parseBspSubtypeAndType(String fittingName) {
    final upper = fittingName.toUpperCase().trim();
    if (!upper.contains('BSP')) return null;

    final type = _mapFittingType(upper);
    if (type == null) return null;

    final typeIndex = upper.indexOf(type);
    if (typeIndex <= 0) return null;

    final beforeType = upper.substring(0, typeIndex).trim();
    final bspIndex = beforeType.lastIndexOf('BSP');
    if (bspIndex == -1) return null;

    final subtype = beforeType.substring(0, bspIndex + 3).trim();
    if (subtype.isEmpty) return null;

    return (subtype, type);
  }
}

class _PdfPreviewScreen extends StatefulWidget {
  final String title;
  final String fileName;
  final Future<Uint8List> Function(PdfPageFormat format) onBuildPdf;

  const _PdfPreviewScreen({
    required this.title,
    required this.fileName,
    required this.onBuildPdf,
  });

  @override
  State<_PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<_PdfPreviewScreen> {
  static const double _basePageWidth = 700;
  double _zoom = 1.0;
  double _zoomAtScaleStart = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onScaleStart: (_) {
          _zoomAtScaleStart = _zoom;
        },
        onScaleUpdate: (details) {
          setState(() {
            _zoom = (_zoomAtScaleStart * details.scale).clamp(0.6, 3.0);
          });
        },
        child: PdfPreview(
          pdfFileName: widget.fileName,
          build: widget.onBuildPdf,
          allowPrinting: true,
          allowSharing: true,
          canChangePageFormat: true,
          maxPageWidth: _basePageWidth * _zoom,
        ),
      ),
    );
  }
}
