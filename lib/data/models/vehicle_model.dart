class Vehicle {
  final String title;
  final String description;
  final String type; //Location ou vente
  final double price;
  final String make; // Marque du véhicule
  final String model; // Modèle du véhicule
  final int year;
  final String fuelType; // Type de carburant (essence, diesel, etc.)
  final double mileage; // Kilométrage
  final List<String> images;
  final String userId;

  Vehicle({
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.make,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.mileage,
    required this.images,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'price': price,
      'make': make,
      'model': model,
      'year': year,
      'fuelType': fuelType,
      'mileage': mileage,
      'images': images,
      'userId': userId,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      title: map['title'],
      description: map['description'],
      type: map['type'],
      price: map['price'],
      make: map['make'],
      model: map['model'],
      year: map['year'],
      fuelType: map['fuelType'],
      mileage: map['mileage'],
      images: List<String>.from(map['images']),
      userId: map['ownerId'],
    );
  }
}
