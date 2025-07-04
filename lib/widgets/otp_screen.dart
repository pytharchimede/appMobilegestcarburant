import 'package:flutter/material.dart';
import 'otp_input_field.dart';

class OtpScreen extends StatefulWidget {
  final String phone;

  OtpScreen({required this.phone});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  bool _isLoading = false;
  String _otp = '';
  bool _autoSubmit = false; // true = soumission auto, false = bouton visible

  void _onOtpCompleted(String value) async {
    setState(() {
      _otp = value;
      if (_autoSubmit) _isLoading = true;
    });

    if (_autoSubmit) {
      await _validateOtp();
    }
  }

  Future<void> _validateOtp() async {
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Montant rechargé avec succès !")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Saisir le code OTP")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "Un code a été envoyé au numéro ${widget.phone}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 32),
            if (_isLoading)
              CircularProgressIndicator()
            else
              Column(
                children: [
                  OtpInputField(
                    length: 4,
                    enabled: !_isLoading,
                    onCompleted: _onOtpCompleted,
                    onChanged: (value) {
                      setState(() {
                        _otp = value;
                      });
                    },
                  ),
                  if (!_autoSubmit) SizedBox(height: 24),
                  if (!_autoSubmit)
                    ElevatedButton(
                      onPressed: (_otp.length == 4 && !_isLoading)
                          ? () async {
                              setState(() {
                                _isLoading = true;
                              });
                              await _validateOtp();
                            }
                          : null,
                      child: Text("Valider"),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
