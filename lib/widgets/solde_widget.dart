import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SoldeWidget extends StatelessWidget {
  // Données globales (toute l'activité)
  final double soldeActuel; // totalRechargement - totalServi
  final double totalRechargement;
  final double totalServi;
  final double? dernierRechargement; // montant du dernier rechargement
  final String? dateDernierRechargement; // ISO (YYYY-MM-DD) ou autre
  final VoidCallback onRecharge;
  final VoidCallback? onRefresh; // Optionnel: forcer recalcul full history

  const SoldeWidget({
    super.key,
    required this.soldeActuel,
    required this.totalRechargement,
    required this.totalServi,
    required this.onRecharge,
    this.dernierRechargement,
    this.dateDernierRechargement,
    this.onRefresh,
  });

  double get _utilisation => totalRechargement > 0
      ? (totalServi / totalRechargement).clamp(0.0, 1.0)
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final formatMontant = NumberFormat('#,##0', 'fr_FR');
    final percent = (_utilisation * 100).round();

    return SizedBox(
      width: double.infinity,
      child: Card(
        color: const Color(0xFF17333F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Solde actuel (toute l\'activité)',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text('${formatMontant.format(soldeActuel)} FCFA',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        if (dernierRechargement != null &&
                            (dernierRechargement ?? 0) > 0)
                          Text(
                            '+ ${formatMontant.format(dernierRechargement)} FCFA (Dernier rechargement${dateDernierRechargement != null ? ' le ${_humanDate(dateDernierRechargement!)}' : ''})',
                            style: const TextStyle(color: Colors.greenAccent),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 92,
                          height: 92,
                          child: CircularProgressIndicator(
                            value: _utilisation,
                            backgroundColor: Colors.white24,
                            color: const Color(0xFF00A9A5),
                            strokeWidth: 10,
                          ),
                        ),
                        Text('$percent%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              _buildProgressBar(percent),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'Total rechargé',
                      value: '${formatMontant.format(totalRechargement)} FCFA',
                      color: Colors.greenAccent,
                      icon: Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatChip(
                      label: 'Total servi',
                      value: '${formatMontant.format(totalServi)} FCFA',
                      color: Colors.redAccent,
                      icon: Icons.local_gas_station,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A9A5),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onRecharge,
                      icon: const Icon(Icons.add),
                      label: const Text('Recharger'),
                    ),
                  ),
                  if (onRefresh != null) ...[
                    const SizedBox(width: 12),
                    Tooltip(
                      message: 'Recalculer tout l\'historique',
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF223C4A),
                          foregroundColor: Colors.white70,
                        ),
                        onPressed: onRefresh,
                        child: const Icon(Icons.refresh),
                      ),
                    ),
                  ]
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Utilisation : $percent%',
                style: const TextStyle(color: Colors.white70)),
            Text(
                '${NumberFormat.compact(locale: 'fr_FR').format(totalServi)} / ${NumberFormat.compact(locale: 'fr_FR').format(totalRechargement)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: _utilisation,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              _utilisation >= 0.9
                  ? Colors.redAccent
                  : (_utilisation >= 0.6
                      ? Colors.orangeAccent
                      : Colors.greenAccent),
            ),
          ),
        ),
      ],
    );
  }

  static String _humanDate(String iso) {
    try {
      final d = DateTime.tryParse(iso);
      if (d == null) return iso;
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2F3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
