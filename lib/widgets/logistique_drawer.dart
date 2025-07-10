import 'package:flutter/material.dart';
import '../screens/planning_screen.dart';

class LogistiqueDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFF223C4A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF17333F),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.business_center,
                    color: Colors.greenAccent, size: 40),
                SizedBox(height: 8),
                Text(
                  "Gestion Logistique",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "Version Pro",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
          _drawerSection("Planification", [
            _drawerItem(context, Icons.event, "Planning", () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => PlanningScreen()));
            }),
          ]),
          _drawerSection("Inventaires", [
            _drawerItem(context, Icons.inventory, "Matériel", () {/* TODO */}),
            _drawerItem(
                context, Icons.precision_manufacturing, "Matériaux & Outils",
                () {/* TODO */}),
            _drawerItem(context, Icons.desktop_windows, "Matériel de bureau",
                () {/* TODO */}),
          ]),
          _drawerSection("Stocks", [
            _drawerItem(
                context, Icons.stacked_bar_chart, "Valorisation des stocks",
                () {/* TODO */}),
            _drawerItem(context, Icons.input, "Bons d'entrée", () {/* TODO */}),
            _drawerItem(context, Icons.output, "Bons de sortie", () {
              /* TODO */
            }),
          ]),
          Divider(color: Colors.white24),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.white70),
            title: Text("Paramètres", style: TextStyle(color: Colors.white)),
            onTap: () {/* TODO */},
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
}
