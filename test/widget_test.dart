import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_carburant/main.dart';

void main() {
  testWidgets('Vérifie que le tableau de bord et le solde s\'affichent',
      (WidgetTester tester) async {
    await tester.pumpWidget(GestionCarburantApp());

    // Vérifie que le titre principal est visible
    expect(find.text('Tableau de Bord'), findsOneWidget);

    // Vérifie que le bouton "Recharger le compte" est présent
    expect(find.text('Recharger le compte'), findsOneWidget);

    // Vérifie que le solde actuel s'affiche bien (350000 FCFA)
    expect(find.text('350000 FCFA'), findsOneWidget);

    // Vérifie que la mention du dernier crédit est affichée aussi
    expect(find.text('+ 500000 FCFA (validé)'), findsOneWidget);
  });
}
