import 'package:flutter/material.dart';
import 'otp_input_field.dart'; // Widget OTP personnalisé

class OtpScreen extends StatefulWidget {
  final String phone;

  OtpScreen({required this.phone});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String otp = '';

  void _onOtpCompleted(String value) {
    setState(() => otp = value);
    // Simuler validation automatique
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Code OTP saisi : $value")),
    );
    // TODO: Ajouter logique backend et navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Saisir le code OTP")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Un code a été envoyé au numéro ${widget.phone}",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 32),
            OtpInputField(
              length: 6,
              onCompleted: _onOtpCompleted,
            ),
          ],
        ),
      ),
    );
  }
}
