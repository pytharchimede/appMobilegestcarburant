import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://fidest.ci/decaissement/api/api.php';

/**
 * Récupère le solde et le dernier crédit.
 */
  Future<Map<String, dynamic>> fetchSolde() async {
    final response = await http.get(Uri.parse('$baseUrl?endpoint=solde'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'solde': (data['solde'] ?? 0).toDouble(),
        'dernierCredit': (data['dernierCredit'] ?? 0).toDouble(),
      };
    } else {
      throw Exception('Erreur lors du chargement du solde');
    }
  }

/**
 * Récupère l'utilisation du carburant en pourcentage.
 */
  Future<double> fetchCarburantUtilisation() async {
    final response =
        await http.get(Uri.parse('$baseUrl?endpoint=carburant_utilisation'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['utilisation'] ?? 0.0).toDouble();
    } else {
      throw Exception('Erreur lors du chargement de l\'utilisation carburant');
    }
  }

/**
 * Récupère l'évolution du solde sur 30 jours.
 * Retourne une liste de maps avec les jours et les soldes correspondants.
 */
  Future<List<Map<String, dynamic>>> fetchSoldeEvolution() async {
    final response =
        await http.get(Uri.parse('$baseUrl?endpoint=solde_evolution'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((e) => {
                'jour': e['jour'],
                'solde': (e['solde'] as num).toDouble(),
              })
          .toList();
    } else {
      throw Exception('Erreur lors du chargement de l\'évolution du solde');
    }
  }

/**
 * Récupère la liste des stations de service.
 * Retourne une liste de maps avec les informations des stations.
 */
  Future<List<Map<String, dynamic>>> fetchStationsService() async {
    final response =
        await http.get(Uri.parse('$baseUrl?endpoint=stations_service'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception('Erreur lors du chargement des stations');
    }
  }

/**
 * Envoie un OTP pour le carburant.
 * Prend en paramètre le numéro de téléphone et le nom du client.
 */
  Future<bool> sendConfirmationCarburant({
    required String telephone,
    required String nom,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl?endpoint=confirmation_carburant'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'telephone': telephone, 'nom': nom}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Réponse API confirmation_carburant: $data'); // Debug
      return data['status'] == 'success';
    } else {
      print('Erreur HTTP ${response.statusCode}: ${response.body}'); // Debug
      throw Exception('Erreur lors de l\'envoi de la confirmation carburant');
    }
  }
}
