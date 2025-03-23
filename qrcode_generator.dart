import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class QrcodeGenerator extends StatefulWidget {
  const QrcodeGenerator({super.key});

  @override
  State<QrcodeGenerator> createState() => _QrcodeGeneratorState();
}

class _QrcodeGeneratorState extends State<QrcodeGenerator> {
  String? qrData;
  GlobalKey globalKey = GlobalKey(); // Key for capturing the QR code image
  Color qrColor = Colors.blue; // Default QR code color
  Color qrBackgroundColor = Colors.white; // Default QR code background color

  // ✅ Request storage permissions (Android)
  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final androidVersion = int.parse(Platform.operatingSystemVersion.split('.')[0]);

      if (androidVersion >= 33) {
        // Android 13+ uses READ_MEDIA_IMAGES permission
        final status = await Permission.photos.request();
        return status.isGranted;
      } else if (androidVersion >= 30) {
        // Android 11 & 12 require MANAGE_EXTERNAL_STORAGE permission
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      } else {
        // Android 10 and below
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true; // iOS does not require storage permission
  }

  // ✅ Capture QR Code as an image
  Future<File?> _captureQRImage() async {
    try {
      RenderRepaintBoundary boundary = globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Ensure QR code is rendered before capturing
      await Future.delayed(const Duration(milliseconds: 300));

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      File file = File('${directory.path}/qr_code.png');
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      print('Error capturing QR code image: $e');
      return null;
    }
  }

  // ✅ Share QR Code Image
  Future<void> _shareQRImage() async {
    File? qrFile = await _captureQRImage();
    if (qrFile != null) {
      await Share.shareXFiles([XFile(qrFile.path)]);
    }
  }


  // ✅ Clear Input and QR Code
  void _clearQRCode() {
    setState(() {
      qrData = null;
    });
  }

  // ✅ Change QR Code Color
  void _changeQRColor() async {
    final Color? newColor = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose QR Code Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: qrColor,
              onColorChanged: (color) {
                setState(() {
                  qrColor = color;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, qrColor),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (newColor != null) {
      setState(() {
        qrColor = newColor;
      });
    }
  }

  // ✅ Change QR Code Background Color
  void _changeQRBackgroundColor() async {
    final Color? newColor = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose QR Code Background Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: qrBackgroundColor,
              onColorChanged: (color) {
                setState(() {
                  qrBackgroundColor = color;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, qrBackgroundColor),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (newColor != null) {
      setState(() {
        qrBackgroundColor = newColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        centerTitle: true,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF2A2A72)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Input Field for QR Data
              TextField(
                onSubmitted: (event) {
                  setState(() {
                    qrData = event;
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter text to generate QR code',
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.text_fields, color: Colors.white70),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ QR Code Display
              if (qrData != null)
                RepaintBoundary(
                  key: globalKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: qrBackgroundColor, // Custom background color
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PrettyQr(
                      data: qrData!,
                      errorCorrectLevel: QrErrorCorrectLevel.M,
                      typeNumber: null,
                      roundEdges: true,
                      elementColor: qrColor, // Custom QR code color
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // ✅ Action Buttons
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _shareQRImage,
                    icon: const Icon(Icons.share),
                    label: const Text('Share QR Code'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _clearQRCode,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _changeQRColor,
                    icon: const Icon(Icons.color_lens),
                    label: const Text('Change QR Color'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _changeQRBackgroundColor,
                    icon: const Icon(Icons.format_paint),
                    label: const Text('Change Background Color'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Simple Color Picker Widget
class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.pickerColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildColorOption(Colors.blue),
            _buildColorOption(Colors.red),
            _buildColorOption(Colors.green),
            _buildColorOption(Colors.yellow),
            _buildColorOption(Colors.purple),
            _buildColorOption(Colors.orange),
            _buildColorOption(Colors.black),
            _buildColorOption(Colors.white),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Selected Color: ${selectedColor.toString()}',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
        widget.onColorChanged(color);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selectedColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}