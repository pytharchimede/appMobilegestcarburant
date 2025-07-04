import 'package:flutter/material.dart';

class PhoneNumberDialog extends StatefulWidget {
  final Function(String phone) onValidPhone;

  PhoneNumberDialog({required this.onValidPhone});

  @override
  _PhoneNumberDialogState createState() => _PhoneNumberDialogState();
}

class _PhoneNumberDialogState extends State<PhoneNumberDialog> {
  final _formKey = GlobalKey<FormState>();
  String phone = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Gérant(e) de la station"),
      content: Form(
        key: _formKey,
        child: TextFormField(
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(hintText: "Ex: 07 12 34 56 78"),
          validator: (value) {
            if (value == null || value.isEmpty) return "Numéro requis";
            if (!RegExp(r'^(01|05|07|25|27)\d{8}$')
                .hasMatch(value.replaceAll(' ', '')))
              return "Numéro ivoirien invalide";
            return null;
          },
          onChanged: (value) => phone = value,
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text("Annuler")),
        ElevatedButton(
          child: Text("Valider"),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onValidPhone(phone);
            }
          },
        ),
      ],
    );
  }
}
