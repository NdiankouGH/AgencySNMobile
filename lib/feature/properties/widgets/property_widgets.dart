import 'dart:async';

import 'package:agencysn/data/models/Favorite.dart';
import 'package:agencysn/data/models/model_property.dart';
import 'package:agencysn/feature/properties/screens/property_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class PropertyGrid extends StatelessWidget {
  const PropertyGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('properties')
          .orderBy('title', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune propriété trouvée'));
        }

        var properties = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: properties.length,
          itemBuilder: (context, index) {
            var propertyData = properties[index].data() as Map<String, dynamic>;
            String docId = properties[index].id;
            List<String> images =
                List<String>.from(propertyData['images'] ?? []);
            String? firstImageLink = images.isNotEmpty ? images[0] : null;

            return FutureBuilder<String?>(
              future: _getImageUrl(firstImageLink),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _buildPropertyCard(propertyData, docId, snapshot.data, context);
              },
            );
          },
        );
      },
    );
  }

  Future<String?> _getImageUrl(String? imageLink) async {
    if (imageLink == null) return null;
    try {
      // Nettoyer l'URL de l'image
      String cleanImagePath =
          imageLink.replaceAll(RegExp(r'[^a-zA-Z0-9/._-]'), '');

      if (!cleanImagePath.contains('.')) {
        // Ajouter une extension par défaut si aucune n'est présente
        cleanImagePath += '.jpg';
      }

      // Construire le chemin complet pour Firebase Storage
      String storagePath = 'properties_images/$cleanImagePath';

      final ref = FirebaseStorage.instance.ref(storagePath);

      // Obtenir l'URL de téléchargement avec un timeout
      final url = await ref.getDownloadURL().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Le chargement de l\'image a pris trop de temps');
        },
      );

      return url;
    } catch (e) {
      print('Erreur lors du chargement de l\'image: $e');
      return null;
    }
  }
}

Widget _buildPropertyCard(
    Map<String, dynamic> property, String itemId, String? imageUrl, BuildContext context) {

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageStack(imageUrl , itemId, context),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(property['title'] ?? ''),
              const SizedBox(height: 4),
              _buildType(property['type'] ?? ''),
              const SizedBox(height: 8),
              _buildPriceAndBookingRow(
                  (property['price'] ?? 0).toDouble(), property, context),
            ],
          ),
        ),
      ],
    ),
  );
}
Widget _buildImageStack(String? imageUrl, String itemId, BuildContext context) {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final String userId = currentUser?.uid ?? '';

  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('favorites')
        .doc('${userId}_$itemId')
        .snapshots(),
    builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
      bool isFavorite = snapshot.hasData && snapshot.data!.exists;

      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('properties')
            .doc(itemId)
            .get(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> propertySnapshot) {
          Map<String, dynamic>? propertyData =
          propertySnapshot.data?.data() as Map<String, dynamic>?;

          return Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: imageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) {
                    print('Erreur de chargement de l\'image: $error');
                    return const Center(
                      child: Icon(
                        Icons.error_outline,
                        size: 50,
                        color: Colors.red,
                      ),
                    );
                  },
                )
                    : const Center(
                  child: Icon(
                    Icons.image,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () async {
                      if (propertyData == null) return;

                      try {
                        if (currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez vous connecter pour ajouter aux favoris'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        final FavoriteService favoriteService = FavoriteService();

                        if (isFavorite) {
                          await favoriteService.removeFromFavorite(userId, itemId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Propriété retirée des favoris'),
                              backgroundColor: Colors.deepOrangeAccent,
                            ),
                          );
                        } else {
                          await favoriteService.addToFavorite(
                            userId: userId,
                            itemId: itemId,
                            itemType: 'property',
                            itemTitle: propertyData['title'] ?? '',
                            itemData: {
                              'title': propertyData['title'],
                              'price': propertyData['price'],
                              'type': propertyData['type'],
                              'location': propertyData['location'],
                              'mainImage': imageUrl,
                            },
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Propriété ajoutée aux favoris'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
// Fonction utilitaire pour obtenir l'ID de l'utilisateur courant
String getCurrentUserId() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('Utilisateur non connecté');
  }
  return user.uid;
}
Widget _buildTitle(String title) {
  return Text(
    title,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

Widget _buildType(String type) {
  return Text(
    type,
    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

Widget _buildPriceAndBookingRow(
    double price, Map<String, dynamic> propertyData, BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        '$price fcfa',
        style: const TextStyle(
            color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PropertyDetailsScreen(
                property: Property(
                  userId: propertyData['userId'] ?? '',
                  title: propertyData['title'] ?? '',
                  type: propertyData['type'] ?? '',
                  category: propertyData['category'] ?? '',
                  bedroom: (propertyData['bedroom'] ?? 0).toInt(),
                  bathroom: (propertyData['bathroom'] ?? 0).toInt(),
                  price: (propertyData['price'] ?? 0).toDouble(),
                  location: propertyData['location'] ?? '',
                  description: propertyData['description'] ?? '',
                  images: List<String>.from(propertyData['images'] ?? []),
                  availability: propertyData['availability'] ?? false,
                ),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('voir plus', style: TextStyle(fontSize: 16)),
      ),
    ],
  );
}
