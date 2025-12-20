import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kitaid1/features/verification/verification_page.dart';
import 'package:kitaid1/utilities/constant/color.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR for Verification'),
        backgroundColor: mycolors.Primary,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;

          final barcode = capture.barcodes.first;
          final raw = barcode.rawValue;

          if (raw == null) return;

          // ✅ Only handle KitaID verification QR
          if (!raw.contains('"type":"kitaid_verify"')) return;

          _handled = true;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerificationPage(qrData: raw),
            ),
          );
        },
      ),
    );
  }
}
