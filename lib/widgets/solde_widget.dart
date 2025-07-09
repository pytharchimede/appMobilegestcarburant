import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SoldeWidget extends StatelessWidget {
  final double solde;
  final double dernierCredit;
  final VoidCallback
      onRecharge; // Callback appelé quand on appuie sur le bouton

  SoldeWidget({
    required this.solde,
    required this.dernierCredit,
    required this.onRecharge,
  });

  @override
  Widget build(BuildContext context) {
    final formatMontant = NumberFormat("#,##0", "fr_FR");

    return Container(
      width: double.infinity,
      child: Card(
        color: Color(0xFF17333F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Solde actuel station',
                  style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('${formatMontant.format(solde)} FCFA',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(
                  '+ ${formatMontant.format(dernierCredit)} FCFA (Dernier rechargement)',
                  style: TextStyle(color: Colors.greenAccent)),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00A9A5),
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      onRecharge, // Appelle la fonction passée en paramètre
                  icon: Icon(Icons.add),
                  label: Text('Recharger le solde'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
