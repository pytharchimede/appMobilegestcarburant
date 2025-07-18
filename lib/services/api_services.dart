import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

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

//Accepter demande de carburant
  Future<bool> accepterDemandeCarburant(String numFiche) async {
    final response = await http.post(
      Uri.parse('$baseUrl?endpoint=accepter_demande_carburant'),
      body: {'num_fiche': numFiche},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception("Erreur lors de l'acceptation");
    }
  }

//Réfuser demande de carburant
  Future<bool> refuserDemandeCarburant(String numFiche) async {
    final response = await http.post(
      Uri.parse('$baseUrl?endpoint=refuser_demande_carburant'),
      body: {'num_fiche': numFiche},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception("Erreur lors du refus");
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
    if (dateDebut != null)
      params['date_debut'] = dateDebut.toIso8601String().substring(0, 10);
    if (dateFin != null)
      params['date_fin'] = dateFin.toIso8601String().substring(0, 10);

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
        throw Exception(
            data['message'] ?? "Erreur lors du chargement du planning");
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

// Récupérer les rapports du jour (synchronisés avec le planning)
  Future<Map<String, List<Map<String, dynamic>>>> fetchRapportsJournalier({
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final params = <String, String>{'endpoint': 'rapport_journalier'};
    if (dateDebut != null)
      params['date_debut'] = dateDebut.toIso8601String().substring(0, 10);
    if (dateFin != null)
      params['date_fin'] = dateFin.toIso8601String().substring(0, 10);

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        if (data['data'] is Map) {
          final raw = data['data'] as Map<String, dynamic>;
          return raw.map((k, v) => MapEntry(
                k,
                List<Map<String, dynamic>>.from(
                  (v as List).map((e) => Map<String, dynamic>.from(e)),
                ),
              ));
        } else {
          return {};
        }
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des rapports");
      }
    } else {
      throw Exception('Erreur lors du chargement des rapports');
    }
  }

// Mettre à jour ou créer un rapport pour une tâche planifiée
  Future<bool> updateRapportJournalier({
    required int planningLineId,
    required String dateRapport,
    required String etat,
    String? commentaire,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl?endpoint=rapport_journalier'),
      body: {
        'planning_line_id': planningLineId.toString(),
        'date_rapport': dateRapport,
        'etat': etat,
        'commentaire': commentaire ?? '',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception("Erreur lors de la mise à jour du rapport");
    }
  }

  // Récupérer la liste des matériels
  Future<List<Map<String, dynamic>>> fetchMateriels() async {
    final response = await http.get(Uri.parse('$baseUrl?endpoint=materiels'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des matériels");
      }
    } else {
      throw Exception("Erreur lors du chargement des matériels");
    }
  }

// Récupérer la liste des catégories
  Future<List<Map<String, dynamic>>> fetchMaterielCategories() async {
    final response =
        await http.get(Uri.parse('$baseUrl?endpoint=materiel_categories'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des catégories");
      }
    } else {
      throw Exception("Erreur lors du chargement des catégories");
    }
  }

// Ajouter un matériel
  Future<bool> ajouterMateriel({
    required String nom,
    required String categorie, // Peut être id ou libellé
    required String etat,
    required int quantite,
    required String emplacement,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl?endpoint=ajouter_materiel'),
      body: {
        'nom': nom,
        'categorie': categorie,
        'etat': etat,
        'quantite': quantite.toString(),
        'emplacement': emplacement,
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception("Erreur lors de l'ajout du matériel");
    }
  }

  // Récupérer la liste des matériaux & outils
  Future<List<Map<String, dynamic>>> fetchMateriauxOutils() async {
    final response =
        await http.get(Uri.parse('$baseUrl?endpoint=materiaux_outils'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ??
            "Erreur lors du chargement des matériaux/outils");
      }
    } else {
      throw Exception("Erreur lors du chargement des matériaux/outils");
    }
  }

// Récupérer la liste des catégories
  Future<List<Map<String, dynamic>>> fetchMateriauxOutilsCategories() async {
    final response = await http
        .get(Uri.parse('$baseUrl?endpoint=materiaux_outils_categories'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des catégories");
      }
    } else {
      throw Exception("Erreur lors du chargement des catégories");
    }
  }

// Ajouter un matériau ou outil
  Future<bool> ajouterMateriauOutil({
    required String nom,
    required String categorie, // Peut être id ou libellé
    required String etat,
    required int quantite,
    required String emplacement,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl?endpoint=ajouter_materiau_outil'),
      body: {
        'nom': nom,
        'categorie': categorie,
        'etat': etat,
        'quantite': quantite.toString(),
        'emplacement': emplacement,
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception("Erreur lors de l'ajout du matériau/outil");
    }
  }

  // Récupérer la liste du matériel de bureau
  Future<List<Map<String, dynamic>>> fetchMaterielBureau() async {
    final response =
        await http.get(Uri.parse('$baseUrl?endpoint=materiel_bureau'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ??
            "Erreur lors du chargement du matériel de bureau");
      }
    } else {
      throw Exception("Erreur lors du chargement du matériel de bureau");
    }
  }

// Récupérer la liste des catégories de matériel de bureau
  Future<List<Map<String, dynamic>>> fetchMaterielBureauCategories() async {
    final response = await http
        .get(Uri.parse('$baseUrl?endpoint=materiel_bureau_categories'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des catégories");
      }
    } else {
      throw Exception("Erreur lors du chargement des catégories");
    }
  }

// Ajouter un matériel de bureau
  Future<bool> ajouterMaterielBureau({
    required String nom,
    required String categorie, // Peut être id ou libellé
    required String etat,
    required int quantite,
    required String emplacement,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl?endpoint=ajouter_materiel_bureau'),
      body: {
        'nom': nom,
        'categorie': categorie,
        'etat': etat,
        'quantite': quantite.toString(),
        'emplacement': emplacement,
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception("Erreur lors de l'ajout du matériel de bureau");
    }
  }

  // Récupérer la liste des inventaires (optionnel: filtrer par date)
  Future<List<Map<String, dynamic>>> fetchInventaireStock(
      {DateTime? date}) async {
    final params = <String, String>{'endpoint': 'inventaire_stock'};
    if (date != null) {
      params['date'] = date.toIso8601String().substring(0, 10);
    }
    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des inventaires");
      }
    } else {
      throw Exception("Erreur lors du chargement des inventaires");
    }
  }

  // Récupérer la liste des catégories d'inventaire
  Future<List<Map<String, dynamic>>> fetchInventaireStockCategories() async {
    final response = await http
        .get(Uri.parse('$baseUrl?endpoint=inventaire_stock_categories'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des catégories");
      }
    } else {
      throw Exception("Erreur lors du chargement des catégories");
    }
  }

  // Ajouter un inventaire (avec upload photo)
  Future<bool> ajouterInventaireStock({
    required DateTime date,
    required String categorie, // id ou libellé
    required String designation,
    required int quantite,
    required String emplacement,
    required String qrcode,
    XFile? photo,
  }) async {
    var uri = Uri.parse('$baseUrl?endpoint=ajouter_inventaire_stock');
    var request = http.MultipartRequest('POST', uri);
    request.fields['date_inventaire'] = date.toIso8601String().substring(0, 10);
    request.fields['categorie'] = categorie;
    request.fields['designation'] = designation;
    request.fields['quantite'] = quantite.toString();
    request.fields['emplacement'] = emplacement;
    request.fields['qrcode'] = qrcode;
    if (photo != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          photo.path,
        ),
      );
    }
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception("Erreur lors de l'ajout de l'inventaire");
    }
  }

  // Récupérer la liste valorisée des stocks
  Future<Map<String, dynamic>> fetchValorisationStocks() async {
    final response =
        await http.get(Uri.parse('$baseUrl?endpoint=valorisation_stocks'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return {
          'total': data['total'] ?? 0,
          'stocks': List<Map<String, dynamic>>.from(data['data']),
        };
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des stocks");
      }
    } else {
      throw Exception("Erreur lors du chargement des stocks");
    }
  }

// Récupérer les catégories de stock
  Future<List<Map<String, dynamic>>> fetchStockCategories() async {
    final response =
        await http.get(Uri.parse('$baseUrl?endpoint=stock_categories'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des catégories");
      }
    } else {
      throw Exception("Erreur lors du chargement des catégories");
    }
  }

// Ajouter ou modifier un stock
  Future<bool> ajouterOuModifierStock({
    int? id,
    required String categorie, // id ou libellé
    required String designation,
    required int quantite,
    required int prixUnitaire,
    required String emplacement,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl?endpoint=ajouter_ou_modifier_stock'),
      body: {
        if (id != null) 'id': id.toString(),
        'categorie': categorie,
        'designation': designation,
        'quantite': quantite.toString(),
        'prix_unitaire': prixUnitaire.toString(),
        'emplacement': emplacement,
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception("Erreur lors de l'ajout/modification du stock");
    }
  }

// Récupérer la liste des chantiers
  Future<List<Map<String, dynamic>>> fetchChantiers() async {
    final response = await http.get(Uri.parse('$baseUrl?endpoint=chantiers'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des chantiers");
      }
    } else {
      throw Exception("Erreur lors du chargement des chantiers");
    }
  }

// Récupérer la liste des catégories de bon d'entrée
  Future<List<String>> fetchBonEntreeCategories() async {
    final response =
        await http.get(Uri.parse('$baseUrl?endpoint=bon_entree_categories'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<String>.from(data['data'].map((e) => e['libelle']));
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des catégories");
      }
    } else {
      throw Exception("Erreur lors du chargement des catégories");
    }
  }

// Récupérer la liste des bons d'entrée
  Future<List<Map<String, dynamic>>> fetchBonsEntree() async {
    final response = await http.get(Uri.parse('$baseUrl?endpoint=bons_entree'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des bons");
      }
    } else {
      throw Exception("Erreur lors du chargement des bons");
    }
  }

// Ajouter un bon d'entrée (avec pièce jointe)
  Future<bool> ajouterBonEntree({
    required String numero,
    required DateTime date,
    required String fournisseur,
    required String categorie,
    required int quantite,
    XFile? piece,
    required String commentaire,
    required String affectation,
    int? chantierId,
  }) async {
    var uri = Uri.parse('$baseUrl?endpoint=ajouter_bon_entree');
    var request = http.MultipartRequest('POST', uri);
    request.fields['numero'] = numero;
    request.fields['date_entree'] = date.toIso8601String().substring(0, 10);
    request.fields['fournisseur'] = fournisseur;
    request.fields['categorie'] = categorie;
    request.fields['quantite'] = quantite.toString();
    request.fields['commentaire'] = commentaire;
    request.fields['affectation'] = affectation;
    if (chantierId != null)
      request.fields['chantier_id'] = chantierId.toString();
    if (piece != null) {
      request.files.add(await http.MultipartFile.fromPath('piece', piece.path));
    }
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print('Réponse HTTP: ${response.statusCode}');
    print('Réponse body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception("Erreur lors de l'ajout du bon d'entrée");
    }
  }

  // Liste des bons de sortie
  Future<List<Map<String, dynamic>>> fetchBonsSortie() async {
    final response = await http.get(Uri.parse('$baseUrl?endpoint=bons_sortie'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des bons de sortie");
      }
    } else {
      throw Exception("Erreur lors du chargement des bons de sortie");
    }
  }

  // Liste des motifs de sortie
  Future<List<String>> fetchBonSortieMotifs() async {
    final response =
        await http.get(Uri.parse('$baseUrl?endpoint=bon_sortie_motifs'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return List<String>.from(data['data'].map((e) => e['libelle']));
      } else {
        throw Exception(
            data['message'] ?? "Erreur lors du chargement des motifs");
      }
    } else {
      throw Exception("Erreur lors du chargement des motifs");
    }
  }

  // Ajouter un bon de sortie (avec pièce jointe)
  Future<bool> ajouterBonSortie({
    required String numero,
    required DateTime date,
    required String beneficiaire,
    required String categorie,
    required int quantite,
    required String motif,
    XFile? piece,
    required String commentaire,
    required String affectation,
    int? chantierId,
  }) async {
    var uri = Uri.parse('$baseUrl?endpoint=ajouter_bon_sortie');
    var request = http.MultipartRequest('POST', uri);
    request.fields['numero'] = numero;
    request.fields['date_sortie'] = date.toIso8601String().substring(0, 10);
    request.fields['beneficiaire'] = beneficiaire;
    request.fields['categorie'] = categorie;
    request.fields['quantite'] = quantite.toString();
    request.fields['motif'] = motif;
    request.fields['commentaire'] = commentaire;
    request.fields['affectation'] = affectation;
    if (chantierId != null)
      request.fields['chantier_id'] = chantierId.toString();
    if (piece != null) {
      request.files.add(await http.MultipartFile.fromPath('piece', piece.path));
    }
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print('Réponse HTTP: ${response.statusCode}');
    print('Réponse body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception("Erreur lors de l'ajout du bon de sortie");
    }
  }
}
