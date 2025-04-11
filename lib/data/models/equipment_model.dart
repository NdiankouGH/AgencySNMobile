class Equipment {
  final String title;
  final String type; //Location ou vente
  final String description;
  final double price;
  final String category; // Catégorie de l'équipement (ex: outils, machines)
  final String condition; // État de l'équipement (ex: neuf, utilisé)
  final String location;
  final List<String> images;
  final String userId;

  Equipment({
    required this.title,
    required this.type,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.location,
    required this.images,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'location': location,
      'images': images,
      'userId': userId,
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      title: map['title'],
      type: map['type'],
      description: map['description'],
      price: map['price'],
      category: map['category'],
      condition: map['condition'],
      location: map['location'],
      images: List<String>.from(map['images']),
      userId: map['userId'],
    );
  }
}
