import 'package:flutter/material.dart';

class OtpInputField extends StatefulWidget {
  final int length;
  final void Function(String) onCompleted;

  OtpInputField({this.length = 6, required this.onCompleted});

  @override
  _OtpInputFieldState createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNodes.forEach((node) => node.dispose());
    _controllers.forEach((ctrl) => ctrl.dispose());
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      // Si coller, répartir les caractères
      for (int i = 0; i < value.length && i + index < widget.length; i++) {
        _controllers[i + index].text = value[i];
      }
      int nextIndex = index + value.length;
      if (nextIndex < widget.length) {
        _focusNodes[nextIndex].requestFocus();
      } else {
        _submitOtp();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index + 1 != widget.length) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _submitOtp();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _submitOtp() {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length == widget.length && !otp.contains('')) {
      widget.onCompleted(otp);
    }
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 48,
      height: 56,
      margin: EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal, width: 2),
          ),
        ),
        onChanged: (value) => _onChanged(value, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) => _buildOtpBox(index)),
    );
  }
}
