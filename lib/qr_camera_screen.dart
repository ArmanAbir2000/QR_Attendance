import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_screen.dart';

class QRCameraScreen extends StatefulWidget {
  @override
  State<QRCameraScreen> createState() => _QRCameraScreenState();
}

class _QRCameraScreenState extends State<QRCameraScreen> {
  String? _qrCode;
  Position? _currentPosition;
  String? _userId;
  bool _isUserIdEntered = false;

  final TextEditingController _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  void _fetchLocation() async {
    if (await Geolocator.isLocationServiceEnabled() &&
        await Geolocator.checkPermission() != LocationPermission.denied &&
        await Geolocator.checkPermission() !=
            LocationPermission.deniedForever) {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied.")),
      );
    }
  }

  void _processQRCode(String qrCode) {
    setState(() {
      _qrCode = qrCode;
    });

    if (_currentPosition != null && _userId != null) {
      String locationDetails =
          "Latitude: ${_currentPosition!.latitude}, Longitude: ${_currentPosition!.longitude}";

      _sendAttendanceData(qrCode);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid User ID.")),
      );
    }
  }

  Future<void> _sendAttendanceData(String qrCode) async {
    try {
      final response = await http.post(
        Uri.parse('http://your-server-address/save_attendance.php'),
        body: {
          'qr_code': qrCode,
          'user_id': _userId!,
          'latitude': _currentPosition!.latitude.toString(),
          'longitude': _currentPosition!.longitude.toString(),
        },
      );

      final responseBody = jsonDecode(response.body);
      if (responseBody['response'] == 'true') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance saved successfully")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseBody['message'] ?? "Error")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("An error occurred while saving attendance")),
      );
    }
  }

  void _submitUserId() {
    if (_userIdController.text.isNotEmpty) {
      setState(() {
        _userId = _userIdController.text.trim();
        _isUserIdEntered = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid User ID.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
      ),
      body: _isUserIdEntered
          ? Column(
              children: [
                Expanded(
                  child: MobileScanner(
                    onDetect: (BarcodeCapture barcodeCapture) {
                      final List<Barcode> barcodes = barcodeCapture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          _processQRCode(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Enter User ID",
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      labelText: "User ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitUserId,
                    child: const Text("Submit"),
                  ),
                ],
              ),
            ),
    );
  }
}
