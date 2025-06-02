import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomScannerScreen extends StatefulWidget {
  const CustomScannerScreen({super.key});

  @override
  State<CustomScannerScreen> createState() => _CustomScannerScreenState();
}

class _CustomScannerScreenState extends State<CustomScannerScreen> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal, // Adjust for faster/slower detection
    returnImage: false, // Set to true if you need the scanned image
  );
  bool _isFlashlightOn = false;
  // String _scanResult = 'No barcode detected'; // This is not used here, can be removed

  // Define a constant for the scan window size for easier modification
  static const double _scanWindowWidth = 300.0; // Increased from 250
  static const double _scanWindowHeight = 300.0; // Increased from 150

  @override
  void initState() {
    super.initState();
    _requestCameraPermission(); // Request permission when screen initializes
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      // If permission is denied, you might want to show a message or pop the screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to scan barcodes.')),
        );
        // Navigator.pop(context); // Option to pop if permission is crucial
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
      body: Stack(
        children: [
          // MobileScanner widget as the base layer
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? scannedValue = barcodes.first.rawValue;
                if (scannedValue != null && scannedValue.isNotEmpty) {
                  // Vibrate on successful scan
                  HapticFeedback.lightImpact(); // Requires import 'package:flutter/services.dart';

                  // Stop the camera, return the result and pop the screen
                  cameraController.stop();
                  Navigator.pop(context, scannedValue);
                }
              }
            },
            // Define a transparent scan window to allow our custom overlay
            // This also helps mobile_scanner focus detection on this area
            scanWindow: Rect.fromCenter(
              center: MediaQuery.of(context).size.center(Offset.zero),
              width: _scanWindowWidth, // Use the constant
              height: _scanWindowHeight, // Use the constant
            ),
          ),

          // Custom UI Overlay
          // Close Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.pop(context); // Close the scanner without a result
              },
            ),
          ),

          // Title
          const Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Text(
              'Scan QR Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Dashed Scan Frame and Horizontal Line
          Center(
            child: Container(
              width: _scanWindowWidth, // Use the constant for the container's width
              height: _scanWindowHeight, // Use the constant for the container's height
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent), // Container itself is transparent
              ),
              child: CustomPaint(
                painter: DashedBorderPainter(),
                child: Center(
                  child: Container(
                    height: 2, // Thickness of the horizontal line
                    width: _scanWindowWidth - 40, // Adjust width based on new scan window width
                    color: Colors.white, // Color of the horizontal line
                  ),
                ),
              ),
            ),
          ),

          // Instruction Text
          Positioned(
            bottom: 150, // Position above the flashlight button
            left: 0,
            right: 0,
            child: Text(
              'Align QR code within the frame to scan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
              ),
            ),
          ),

          // Toggle Flashlight Button
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3), // Match app's primary color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                setState(() {
                  _isFlashlightOn = !_isFlashlightOn;
                  cameraController.toggleTorch(); // Toggle the flashlight
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isFlashlightOn ? Icons.flash_on : Icons.flash_off),
                  const SizedBox(width: 10),
                  Text(_isFlashlightOn ? 'Flashlight On' : 'Toggle Flashlight'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for the dashed border (same as before)
class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double dashWidth = 10;
    const double dashSpace = 8;
    double startX = 0;
    double startY = 0;

    // Top border
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }

    // Right border
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width, startY), Offset(size.width, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }

    startX = size.width;
    startY = size.height;

    // Bottom border
    while (startX > 0) {
      canvas.drawLine(Offset(startX, size.height), Offset(startX - dashWidth, size.height), paint);
      startX -= dashWidth + dashSpace;
    }

    // Left border
    while (startY > 0) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY - dashWidth), paint);
      startY -= dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}