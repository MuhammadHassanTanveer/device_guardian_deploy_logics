import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../util/dimensions.dart';
import '../util/styles.dart';
import 'scanner_overlay_painters.dart';

/// QR/Barcode Scanner Dialog Widget
/// Opens a dialog with camera scanner to scan QR codes and barcodes
class QrScannerDialogWidget extends StatefulWidget {
  final String title;
  final Function(String) onScanned;

  const QrScannerDialogWidget({
    super.key,
    required this.title,
    required this.onScanned,
  });

  @override
  State<QrScannerDialogWidget> createState() => _QrScannerDialogWidgetState();
}

class _QrScannerDialogWidgetState extends State<QrScannerDialogWidget>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _scannerController;
  bool _isScanned = false;
  bool _hasError = false;
  bool _isTorchOn = false;
  String? _errorMessage;

  // Animation controller for scanning line
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Setup scanning line animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() {
        _isScanned = true;
      });

      final String scannedValue = barcodes.first.rawValue!;

      // Show success animation briefly before closing
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onScanned(scannedValue);
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<void> _toggleTorch() async {
    if (_scannerController == null) return;
    try {
      await _scannerController!.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (e) {
      // Torch not available
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),

            // Scanner View
            Flexible(
              child: Container(
                margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildContent(),
                  ),
                ),
              ),
            ),

            // Instructions and Controls
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusLarge),
          topRight: Radius.circular(Dimensions.radiusLarge),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              widget.title,
              style: robotoBold(context).copyWith(
                color: Colors.white,
                fontSize: Dimensions.fontSizeLarge(context),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return _buildErrorView();
    }
    if (_isScanned) {
      return _buildSuccessView();
    }
    return _buildScannerView();
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        bottom: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        children: [
          Text(
            'Position the QR code or barcode within the frame',
            textAlign: TextAlign.center,
            style: robotoRegular(context).copyWith(
              fontSize: Dimensions.fontSizeSmall(context),
              color: Theme.of(context).hintColor,
            ),
          ),
          Text(
            'QR کوڈ یا بارکوڈ کو فریم کے اندر رکھیں',
            textAlign: TextAlign.center,
            style: robotoRegular(context).copyWith(
              fontSize: Dimensions.fontSizeSmall(context),
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Torch Toggle Button
          if (!_hasError && !_isScanned)
            ElevatedButton.icon(
              onPressed: _toggleTorch,
              icon: Icon(
                _isTorchOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              label: Text(
                'Flash فلیش',
                style: robotoRegular(context).copyWith(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    // Create controller here - it will be attached when MobileScanner builds
    _scannerController ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = min(constraints.maxWidth, constraints.maxHeight) - 40;
        final topOffset = (constraints.maxHeight - scanAreaSize) / 2;
        final leftOffset = (constraints.maxWidth - scanAreaSize) / 2;

        return Stack(
          children: [
            // Camera View - autoStart is true by default
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return _buildCameraErrorView(error);
              },
            ),

            // Overlay with cutout
            CustomPaint(
              painter: ScannerOverlayPainter(
                borderColor: Theme.of(context).primaryColor,
                overlayColor: Colors.black.withValues(alpha: 0.5),
              ),
              child: const SizedBox.expand(),
            ),

            // Scanning Line Animation
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  top: topOffset + 10 + (_animation.value * (scanAreaSize - 20)),
                  left: leftOffset + 10,
                  right: leftOffset + 10,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Theme.of(context).primaryColor.withValues(alpha: 0.8),
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Corner Decorations
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: CornerPainter(
                color: Theme.of(context).primaryColor,
                strokeWidth: 4,
                cornerLength: 30,
              ),
            ),

            // Pulsing corners animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: PulsingCornerPainter(
                    color: Theme.of(context).primaryColor.withValues(
                          alpha: 0.3 + (_animation.value * 0.4),
                        ),
                    strokeWidth: 2,
                    cornerLength: 30,
                    offset: _animation.value * 5,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCameraErrorView(MobileScannerException error) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text(
                'Camera Error',
                style: robotoBold(context).copyWith(
                  color: Colors.white,
                  fontSize: Dimensions.fontSizeLarge(context),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                error.errorDetails?.message ?? 'Unable to access camera',
                textAlign: TextAlign.center,
                style: robotoRegular(context).copyWith(
                  color: Colors.white70,
                  fontSize: Dimensions.fontSizeSmall(context),
                ),
              ),
              Text(
                'کیمرہ تک رسائی نہیں ہو سکی۔',
                textAlign: TextAlign.center,
                style: robotoRegular(context).copyWith(
                  color: Colors.white70,
                  fontSize: Dimensions.fontSizeSmall(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              'Scanned Successfully!',
              style: robotoBold(context).copyWith(
                color: Colors.white,
                fontSize: Dimensions.fontSizeLarge(context),
              ),
            ),
            Text(
              'کامیابی سے اسکین ہوگیا!',
              style: robotoRegular(context).copyWith(
                color: Colors.white,
                fontSize: Dimensions.fontSizeDefault(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text(
                'Camera Error',
                style: robotoBold(context).copyWith(
                  color: Colors.white,
                  fontSize: Dimensions.fontSizeLarge(context),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                _errorMessage ?? 'Unable to access camera. Please check camera permissions.',
                textAlign: TextAlign.center,
                style: robotoRegular(context).copyWith(
                  color: Colors.white70,
                  fontSize: Dimensions.fontSizeSmall(context),
                ),
              ),
              Text(
                'کیمرہ تک رسائی نہیں ہو سکی۔ براہ کرم کیمرہ کی اجازت چیک کریں۔',
                textAlign: TextAlign.center,
                style: robotoRegular(context).copyWith(
                  color: Colors.white70,
                  fontSize: Dimensions.fontSizeSmall(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to show QR scanner dialog
Future<void> showQrScannerDialog({
  required BuildContext context,
  required String title,
  required Function(String) onScanned,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => QrScannerDialogWidget(
      title: title,
      onScanned: onScanned,
    ),
  );
}


