import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

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
  Future<List<Map<String, dynamic>>> fetchSoldeEvolution(
      {int? annee, int? mois}) async {
    final params = <String, String>{'endpoint': 'solde_evolution'};
    if (annee != null) params['annee'] = annee.toString();
    if (mois != null) params['mois'] = mois.toString();

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ??
            "Erreur lors du chargement de l'évolution du solde");
      }
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
      if (dateDebut != null)
        'date_debut': dateDebut.toIso8601String().substring(0, 10),
      if (dateFin != null)
        'date_fin': dateFin.toIso8601String().substring(0, 10),
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
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des demandes");
      }
    } else {
      throw Exception("Erreur lors du chargement des demandes");
    }
  }

// Récupérer tous les véhicules/engins
  Future<List<Map<String, dynamic>>> fetchVehicules() async {
    final response = await http.get(Uri.parse('$baseUrl?endpoint=vehicules'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des véhicules");
      }
    } else {
      throw Exception("Erreur lors du chargement des véhicules");
    }
  }

// Ajouter un véhicule/engin
  Future<bool> ajouterVehicule(Map<String, dynamic> vehicule) async {
    final response = await http.post(
      Uri.parse('$baseUrl?endpoint=ajouter_vehicule'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(vehicule),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') return true;
      throw Exception(data['message'] ?? "Erreur lors de l'ajout du véhicule");
    } else {
      throw Exception("Erreur lors de l'ajout du véhicule: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchChauffeurs() async {
    final response = await http.get(Uri.parse('$baseUrl?endpoint=chauffeurs'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des chauffeurs");
      }
    } else {
      throw Exception("Erreur lors du chargement des chauffeurs");
    }
  }

  Future<List<Map<String, dynamic>>> fetchMarques() async {
    final response = await http.get(Uri.parse('$baseUrl?endpoint=marques'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des marques");
      }
    } else {
      throw Exception("Erreur lors du chargement des marques");
    }
  }

  Future<bool> ajouterMarque({required String nom, XFile? logo}) async {
    var uri = Uri.parse('$baseUrl?endpoint=ajouter_marque');
    var request = http.MultipartRequest('POST', uri);
    request.fields['nom'] = nom;
    if (logo != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'logo',
          logo.path,
          contentType: MediaType('image', logo.path.split('.').last),
        ),
      );
    }
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception("Erreur lors de l'ajout de la marque");
    }
  }

  Future<bool> ajouterChauffeur({
    required String nom,
    String? telephone,
    String? permis,
    String? groupeSanguin,
    XFile? photo,
    List<Map<String, dynamic>>? pieces,
  }) async {
    var uri = Uri.parse('$baseUrl?endpoint=ajouter_chauffeur');
    var request = http.MultipartRequest('POST', uri);
    request.fields['nom'] = nom;
    if (telephone != null && telephone.isNotEmpty)
      request.fields['telephone'] = telephone;
    if (permis != null && permis.isNotEmpty) request.fields['permis'] = permis;
    if (groupeSanguin != null && groupeSanguin.isNotEmpty)
      request.fields['groupe_sanguin'] = groupeSanguin;
    if (photo != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          photo.path,
          contentType: MediaType('image', photo.path.split('.').last),
        ),
      );
    }
    if (pieces != null && pieces.isNotEmpty) {
      for (int i = 0; i < pieces.length; i++) {
        final piece = pieces[i];
        if (piece['file'] != null) {
          // Le champ doit être 'pieces' pour chaque fichier
          request.files.add(
            await http.MultipartFile.fromPath(
              'pieces', // <-- pas de []
              piece['file'].path,
              contentType:
                  MediaType('image', piece['file'].path.split('.').last),
              filename: piece['file'].name,
            ),
          );
          // Le champ doit être 'pieces_types' pour chaque type (array)
          request.fields['pieces_types[$i]'] = piece['type'] ?? 'Document';
        }
      }
    }
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception("Erreur lors de l'ajout du chauffeur");
    }
  }

  Future<List<Map<String, dynamic>>> fetchChauffeurPieces(
      String chauffeurId) async {
    final response = await http.get(Uri.parse(
        '$baseUrl?endpoint=chauffeur_pieces&chauffeur_id=$chauffeurId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des pièces");
      }
    } else {
      throw Exception("Erreur lors du chargement des pièces");
    }
  }

  // Récupérer le planning (par période ou tout le mois)
  Future<Map<String, List<Map<String, String>>>> fetchPlanning({
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final params = <String, String>{'endpoint': 'planning'};
    if (dateDebut != null) params['date_debut'] = dateDebut.toIso8601String().substring(0, 10);
    if (dateFin != null) params['date_fin'] = dateFin.toIso8601String().substring(0, 10);

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        // Correction ici :
        final raw = data['data'] as Map<String, dynamic>;
        return raw.map((k, v) => MapEntry(
          k,
          List<Map<String, String>>.from(
            (v as List).map((e) => Map<String, String>.from(e)),
          ),
        ));
      } else {
        throw Exception(data['message'] ?? "Erreur lors du chargement du planning");
      }
    } else {
      throw Exception('Erreur lors du chargement du planning');
    }
  }

// Ajouter une tâche au planning
  Future<bool> ajouterPlanning({
    required String datePlanning,
    required String tache,
    required String responsable,
    required String heure,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl?endpoint=planning'),
      body: {
        'date_planning': datePlanning,
        'tache': tache,
        'responsable': responsable,
        'heure': heure,
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception("Erreur lors de l'ajout de la tâche");
    }
  }
}
