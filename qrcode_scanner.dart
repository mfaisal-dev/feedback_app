import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

class QrcodeScanner extends StatefulWidget {
  const QrcodeScanner({super.key});

  @override
  State<QrcodeScanner> createState() => _QrcodeScannerState();
}

class _QrcodeScannerState extends State<QrcodeScanner> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final ImagePicker _picker = ImagePicker();

  bool isScanning = true; // Prevents duplicate scan alerts

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code Scanner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white,),
            onPressed: () async {
              await controller.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white,),
            onPressed: () async {
              await controller.switchCamera();
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF2A2A72)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (!isScanning) return;
              isScanning = false;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final scannedData = barcodes.first.rawValue ?? "Unknown Data";
                HapticFeedback.vibrate(); // Vibrate on scan
                _showScanResult(scannedData);
              }
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text("Scan from Gallery"),
                    onPressed: _scanFromGallery,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text("Cancel Scan"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final BarcodeCapture? result = await controller.analyzeImage(image.path);

      if (result != null && result.barcodes.isNotEmpty) {
        final scannedData = result.barcodes.first.rawValue ?? "Unknown Data";
        _showScanResult(scannedData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No QR code found in the image!")),
        );
      }
    }
  }

  void _showScanResult(String scannedData) {
    bool isUrl = _isValidUrl(scannedData);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Scan Result"),
          content: SelectableText(scannedData), // Allows text selection
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: scannedData));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Copied to Clipboard!")),
                );
              },
              child: const Text("Copy"),
            ),
            if (isUrl)
              TextButton(
                onPressed: () {
                  launchUrl(Uri.parse(scannedData));
                },
                child: const Text("Open in Browser"),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                isScanning = true; // Allow scanning again
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  bool _isValidUrl(String scannedData) {
    return Uri.tryParse(scannedData)?.hasAbsolutePath ?? false &&
        (scannedData.startsWith("http://") || scannedData.startsWith("https://"));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
