import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/planning_screen.dart';
import '../screens/rapport_journalier_screen.dart';
import '../screens/materiel_screen.dart';
import '../screens/materiaux_outils_screen.dart';
import '../screens/materiel_bureau_screen.dart';
import '../screens/bon_entree_screen.dart';
import '../screens/bon_sortie_screen.dart';
import '../screens/valorisation_stocks_screen.dart';
import '../screens/inventaire_stock_screen.dart';
import '../screens/parametres_screen.dart';

class LogistiqueDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: Color(0xFF223C4A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Color(0xFF17333F),
            padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.greenAccent,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : AssetImage('assets/icon/app_icon.png') as ImageProvider,
                ),
                SizedBox(height: 12),
                // Nom
                Text(
                  user?.displayName ?? "Utilisateur",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                // Email
                Text(
                  user?.email ?? "",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                // Boutons actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Color(0xFF17333F),
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: Icon(Icons.lock_reset, size: 18),
                      label: Text("Mot de passe"),
                      onPressed: () {
                        _showResetPasswordDialog(context, user?.email);
                      },
                    ),
                    SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: Icon(Icons.logout, size: 18),
                      label: Text("Déconnexion"),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          _drawerSection("Planification", [
            _drawerItem(context, Icons.event, "Planning", () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => PlanningScreen()));
            }),
            _drawerItem(context, Icons.assignment, "Rapport journalier", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RapportJournalierScreen()),
              );
            }),
          ]),
          _drawerSection("Inventaires", [
            _drawerItem(context, Icons.inventory, "Matériel", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MaterielScreen()),
              );
            }),
            _drawerItem(
                context, Icons.precision_manufacturing, "Matériaux & Outils",
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MateriauxOutilsScreen()),
              );
            }),
            _drawerItem(context, Icons.desktop_windows, "Matériel de bureau",
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MaterielBureauScreen()),
              );
            }),
            _drawerItem(context, Icons.qr_code, "Inventaire de stock", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InventaireStockScreen()),
              );
            }),
          ]),
          _drawerSection("Stocks", [
            _drawerItem(
                context, Icons.stacked_bar_chart, "Valorisation des stocks",
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ValorisationStocksScreen()),
              );
            }),
            _drawerItem(context, Icons.input, "Bons d'entrée", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BonEntreeScreen()),
              );
            }),
            _drawerItem(context, Icons.output, "Bons de sortie", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BonSortieScreen()),
              );
            }),
          ]),
          Divider(color: Colors.white24),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.white70),
            title: Text("Paramètres", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ParametresScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _drawerItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  void _showResetPasswordDialog(BuildContext context, String? email) {
    final controller = TextEditingController(text: email ?? "");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Réinitialiser le mot de passe"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: "Email"),
        ),
        actions: [
          TextButton(
            child: Text("Annuler"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: Text("Envoyer"),
            onPressed: () async {
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: controller.text.trim());
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Email de réinitialisation envoyé !")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur : $e")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
