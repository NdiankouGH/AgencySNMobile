import 'dart:async';
import 'package:agencysn/data/models/Favorite.dart';
import 'package:agencysn/data/models/equipment_model.dart';
import 'package:agencysn/feature/equipment/screens/equipement_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class EquipmentGrid extends StatelessWidget {
  const EquipmentGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('equipments')
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
          return const Center(child: Text('Aucun équipement trouvé'));
        }

        var equipments = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: equipments.length,
          itemBuilder: (context, index) {
            var equipmentData = equipments[index].data() as Map<String, dynamic>;
            String docId = equipments[index].id;

            List<String> images = List<String>.from(equipmentData['images'] ?? []);
            String? firstImageLink = images.isNotEmpty ? images[0] : null;

            return FutureBuilder<String?>(
              future: _getImageUrl(firstImageLink),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _buildEquipmentCard(equipmentData, docId ,snapshot.data, context);
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
      String cleanImagePath = imageLink.replaceAll(RegExp(r'[^a-zA-Z0-9/._-]'), '');

      if (!cleanImagePath.contains('.')) {
        cleanImagePath += '.jpg';
      }

      String storagePath = 'equipment_images/$cleanImagePath';

      final ref = FirebaseStorage.instance.ref(storagePath);

      final url = await ref.getDownloadURL().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Le chargement de l\'image a pris trop de temps');
        },
      );

      return url;
    } catch (e) {
      print('Erreur lors du chargement de l\'image: $e');
      return null;
    }
  }

  Widget _buildEquipmentCard(Map<String, dynamic> equipment, String itemId, String? imageUrl, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageStack(imageUrl, itemId,context),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(equipment['title'] ?? ''),
                const SizedBox(height: 4),
                _buildCondition(equipment['condition'] ?? ''),
                const SizedBox(height: 8),
                _buildPriceAndDetailsRow(
                    (equipment['price'] ?? 0).toDouble(),
                    equipment,
                    context
                ),
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
              .collection('equipments')
              .doc(itemId)
              .get(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> equipmentSnapshot) {
            Map<String, dynamic>? equipmentData =
            equipmentSnapshot.data?.data() as Map<String, dynamic>?;

            return Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
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
                        if (equipmentData == null) return;
                        try {
                          if (currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Veuillez vous connecter pour ajouter aux favoris',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          final FavoriteService favoriteService = FavoriteService();

                          if (isFavorite) {
                            await favoriteService.removeFromFavorite(
                              userId,
                              itemId,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Equipement retiré des favoris'),
                                backgroundColor: Colors.deepOrangeAccent,
                              ),
                            );
                          } else {
                            await favoriteService.addToFavorite(
                              userId: userId,
                              itemId: itemId,
                              itemType: 'equipment', // Changé de 'property' à 'equipment'
                              itemTitle: equipmentData['title'] ?? '',
                              itemData: {
                                'title': equipmentData['title'],
                                'price': equipmentData['price'],
                                'type': equipmentData['type'],
                                'location': equipmentData['location'],
                                'mainImage': imageUrl,
                              },
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Equipement ajouté aux favoris'),
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
  Widget _buildTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCondition(String condition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        condition,
        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildPriceAndDetailsRow(double price, Map<String, dynamic> equipmentData, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$price fcfa',
          style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 16
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EquipmentDetailsScreen(
                  equipment: Equipment(
                    userId: equipmentData['userId'] ?? '',
                    title: equipmentData['title'] ?? '',
                    type: equipmentData['type'] ?? '',
                    description: equipmentData['description'] ?? '',
                    price: (equipmentData['price'] ?? 0).toDouble(),
                    category: equipmentData['category'] ?? '',
                    condition: equipmentData['condition'] ?? '',
                    location: equipmentData['location'] ?? '',
                    images: List<String>.from(equipmentData['images'] ?? []),
                  ),
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('voir plus', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}