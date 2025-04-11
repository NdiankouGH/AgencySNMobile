import 'package:agencysn/data/models/equipment_model.dart';
import 'package:agencysn/data/models/model_property.dart';
import 'package:agencysn/data/models/vehicle_model.dart';
import 'package:agencysn/feature/equipment/screens/equipment_form.dart';
import 'package:agencysn/feature/properties/screens/property_form_screen.dart';
import 'package:agencysn/feature/vehicles/screens/vehicle_form_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AnnouncementScreen extends StatelessWidget {
  const AnnouncementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes annonces'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Propriété'),
              Tab(text: 'Véhicule'),
              Tab(text: 'Équipement'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AnnouncementCategory(category: 'properties'),
            AnnouncementCategory(category: 'vehicles'),
            AnnouncementCategory(category: 'equipments'),
          ],
        ),
      ),
    );
  }
}

class AnnouncementCategory extends StatelessWidget {
  final String category;

  const AnnouncementCategory({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AddCard(category: category),
        Expanded(
          child: AnnouncementList(category: category),
        ),
      ],
    );
  }
}

class AddCard extends StatelessWidget {
  final String category;

  const AddCard({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CategoryInfo categoryInfo = getCategoryInfo(category);

    return Card(
      margin: const EdgeInsets.all(8.0),
      color: Colors.white70,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => categoryInfo.formScreen),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(categoryInfo.icon, size: 24.0, color: Colors.blueGrey),
              const SizedBox(width: 16.0),
              Text(
                'Ajouter une annonce ${categoryInfo.displayName}',
                style: const TextStyle(color: Colors.blueAccent, fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnnouncementList extends StatelessWidget {
  final String category;

  const AnnouncementList({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Veuillez vous connecter pour voir vos annonces.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(category)
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Une erreur s\'est produite: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune annonce trouvée.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return AnnouncementCard(
              title: data['title'] ?? 'Sans titre',
              description: data['description'] ?? 'Pas de description',
              onEdit: () => _editAnnouncement(context, category, doc.id),
              onDelete: () => _showDeleteDialog(context, category, doc.id),
              onWatch: () {  },
            );
          },
        );
      },
    );
  }

  void _editAnnouncement(BuildContext context, String category, String docId) {
    FirebaseFirestore.instance.collection(category).doc(docId).get().then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        switch (category) {
          case 'properties':
            Property property = Property(
              title: data['title'] ?? '',
              type: data['type'] ?? '',
              category: data['category'] ?? '',
              bedroom: data['bedroom'] ?? 0,
              bathroom: data['bathroom'] ?? 0,
              price: data['price'] ?? 0.0,
              location: data['location'] ?? '',
              description: data['description'] ?? '',
              images: List<String>.from(data['images'] ?? []),
              availability: data['availability'] ?? '',
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            );

            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PropertyFormScreen(
                property: property,
                documentId: docId,
              ),
            ));
            break;

          case 'vehicles':
            Vehicle vehicle = Vehicle(
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              type: data['type'] ?? '',
              price: data['price'] ?? 0.0,
              make: data['make'] ?? '',
              model: data['model'] ?? '',
              year: data['year'] ?? 0,
              mileage: data['mileage'] ?? 0,
              fuelType: data['fuelType'] ?? '',
              images: List<String>.from(data['images'] ?? []),
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            );

            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => VehicleFormScreen(
                vehicle: vehicle,
                documentId: docId,
              ),
            ));
            break;
          case 'equipments':
            Equipment equipment = Equipment(
                title: data['title'],
                type: data['type'],
                description: data['description'] ,
                price: data['price'],
                category: data['category'],
                condition: data['condition'] ,
                location: data['location'],
                images: List<String>.from(data['images'] ?? []),
                userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            );
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EquipmentFormScreen(
                equipment: equipment,
                documentId: docId,
              ),
            ));
          default:
            print('Catégorie non reconnue: $category');
        }
      } else {
        print('Document non trouvé');
      }
    });
  }

  void _showDeleteDialog(BuildContext context, String category, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Suppression de l\'annonce', style: TextStyle(color: Colors.black)),
          content: const Text('Êtes-vous sûr de vouloir supprimer cette annonce ?', style: TextStyle(color: Colors.black)),
          actions: [
            TextButton(
              child: const Text('Annuler', style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onPressed: () => _deleteAnnouncement(context, category, docId),
            ),
          ],
        );
      },
    );
  }

  void _deleteAnnouncement(BuildContext context, String category, String docId) async {
    try {
      await FirebaseFirestore.instance.collection(category).doc(docId).delete();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce supprimée avec succès')),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression de l\'annonce')),
      );
      print('Erreur lors de la suppression: $e');
    }
  }
}

class AnnouncementCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onWatch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AnnouncementCard({
    Key? key,
    required this.title,
    required this.description,
    required this.onWatch,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.white38,
      shadowColor: Colors.white,
      surfaceTintColor: Colors.blueGrey,
      child: ListTile(
        title: Text(title,style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black),),
        subtitle: Text(description, style: TextStyle(fontWeight: FontWeight.normal,color: Colors.blue)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_red_eye_outlined),
              onPressed: (){},
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryInfo {
  final IconData icon;
  final String displayName;
  final Widget formScreen;

  const CategoryInfo({
    required this.icon,
    required this.displayName,
    required this.formScreen,
  });
}

CategoryInfo getCategoryInfo(String category) {
  switch (category) {
    case 'properties':
      return CategoryInfo(
        icon: Icons.home_outlined,
        displayName: 'Propriété',
        formScreen: const PropertyFormScreen(),
      );
    case 'vehicles':
      return CategoryInfo(
        icon: Icons.car_rental_outlined,
        displayName: 'Véhicule',
        formScreen: const VehicleFormScreen(),
      );
    case 'equipments':
      return const CategoryInfo(
        icon: Icons.build_outlined,
        displayName: 'Équipement',
        formScreen: EquipmentFormScreen(),
      );
    default:
      throw Exception('Catégorie non reconnue: $category');
  }
}
