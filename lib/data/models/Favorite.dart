import 'package:cloud_firestore/cloud_firestore.dart';

class Favorite {
  final String userId;
  final String itemId;
  final String itemType;
  final String itemTitle;
  final DateTime dateAdded;
  final Map<String, dynamic> itemData;

  Favorite({
    required this.userId,
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
    required this.dateAdded,
    required this.itemData,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'itemId': itemId,
      'itemType': itemType,
      'itemTitle': itemTitle,
      'dateAdded': dateAdded.toIso8601String(),
      'itemData': itemData,
    };
  }

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      userId: map['userId'] ?? '',
      itemId: map['itemId'] ?? '',
      itemType: map['itemType'] ?? '',
      itemTitle: map['itemTitle'] ?? '',
      dateAdded: DateTime.parse(map['dateAdded'] ?? DateTime.now().toIso8601String()),
      itemData: Map<String, dynamic>.from(map['itemData'] ?? {}),
    );
  }
}

//Service de gestion des favoris
class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addToFavorite({
    required String userId,
    required String itemId,
    required String itemType,
    required String itemTitle,
    required Map<String, dynamic> itemData,
  }) async {
    try {
      final favorite = Favorite(
        userId: userId,
        itemId: itemId,
        itemType: itemType,
        itemTitle: itemTitle,
        dateAdded: DateTime.now(),
        itemData: itemData,
      );

      final docRef = _firestore
          .collection('favorites')
          .doc('${userId}_${itemId}');

      // Vérifier si le document existe déjà
      final doc = await docRef.get();
      if (doc.exists) {
        throw Exception('Cet élément est déjà dans vos favoris');
      }

      await docRef.set(favorite.toMap());
    } catch (e) {
      print('Erreur lors de l\'ajout aux favoris: $e');
      throw _handleError(e);
    }
  }

  Future<void> removeFromFavorite(String userId, String itemId) async {
    try {
      final docRef = _firestore
          .collection('favorites')
          .doc('${userId}_${itemId}');

      final doc = await docRef.get();
      if (!doc.exists) {
        throw Exception('Cet élément n\'est pas dans vos favoris');
      }

      await docRef.delete();
    } catch (e) {
      print('Erreur lors de la suppression des favoris: $e');
      throw _handleError(e);
    }
  }

  Stream<List<Favorite>> getUserFavorites(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Favorite.fromMap(doc.data()))
        .toList());
  }

  Stream<List<Favorite>> getFavoritesByType(String userId, String itemType) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('itemType', isEqualTo: itemType)
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Favorite.fromMap(doc.data()))
        .toList());
  }

  Exception _handleError(dynamic e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return Exception('Vous n\'avez pas les permissions nécessaires');
        case 'not-found':
          return Exception('Document non trouvé');
        default:
          return Exception('Une erreur est survenue: ${e.message}');
      }
    }
    return Exception('Une erreur inattendue est survenue');
  }
}