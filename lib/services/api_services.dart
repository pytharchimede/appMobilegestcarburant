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

/**
 * Enregistre un rechargement de station en BDD
 */
  Future<bool> rechargerStation({
    required String telephone,
    required String nom,
    required double montant,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl?endpoint=confirmation_carburant'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'telephone': telephone,
        'nom': nom,
        'montant': montant,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Réponse API confirmation_carburant: $data'); // Debug
      return data['status'] == 'success';
    } else {
      print('Erreur HTTP ${response.statusCode}: ${response.body}'); // Debug
      throw Exception('Erreur lors du rechargement de la station');
    }
  }

/**
 * Récupère l'historique des bons avec pagination et filtres
 */
  Future<Map<String, dynamic>> fetchBons({
    int page = 1,
    String? station,
    DateTime? dateDebut,
    DateTime? dateFin,
    double? montantMin,
    double? montantMax,
  }) async {
    final Map<String, dynamic> params = {
      'endpoint': 'historique_bons',
      'page': page.toString(),
      if (station != null && station.isNotEmpty) 'station': station,
      if (dateDebut != null) 'date_debut': dateDebut.toIso8601String().substring(0, 10),
      if (dateFin != null) 'date_fin': dateFin.toIso8601String().substring(0, 10),
      if (montantMin != null) 'montant_min': montantMin.toString(),
      if (montantMax != null) 'montant_max': montantMax.toString(),
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);

    print('URL appelée : $uri');

    final response = await http.get(uri);
    print('Réponse brute historique_bons: ${response.body}'); // Ajoute ceci

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        final d = data['data'];
        return {
          'bons': List<Map<String, dynamic>>.from(d['bons']),
          'montantTotal': (d['montantTotal'] ?? 0).toDouble(),
          'hasMore': d['hasMore'] ?? false,
        };
      } else {
        throw Exception(data['message'] ??
            "Erreur lors du chargement de l'historique des bons");
      }
    } else {
      throw Exception('Erreur lors du chargement de l\'historique des bons');
    }
  }

/**
 * Récupère les demandes de carburant en attente.
 * Retourne une liste de maps avec les informations des demandes.
 */
  Future<List<Map<String, dynamic>>> fetchDemandesEnAttente() async {
    final response = await http.get(
      Uri.parse('$baseUrl?endpoint=demandes_carburant_attente'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? "Erreur lors du chargement des demandes");
      }
    } else {
      throw Exception("Erreur lors du chargement des demandes");
    }
  }
}
