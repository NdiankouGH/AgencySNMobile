
class Property {

  final String userId;
  final String title ;
  final String type ;
  final String category ;
  final int bedroom ;
  final int bathroom;
  final double price;
  final String location;
  final String description ;
  final  List<String> images;
  final String availability;

  Property({
    required this.userId,
    required this.title,
    required this.type,
    required this.category,
    required this.bedroom,
    required this.bathroom,
    required this.price,
    required this.location,
    required this.description,
    required this.images,
    required this.availability
  });

  factory Property.fromMap(Map<String, dynamic> data) {
    return Property(
        userId: data['userId'],
        title: data['title'],
        type: data['type'],
        category: data['category'],
        bedroom: data['bedroom'],
        bathroom: data['bathroom'],
        price: data['price'],
        location: data['location'],
        description: data['description'],
        images: List<String>.from(data['images']),
        availability: data['availability']
        );
  }
  Map<String, dynamic> toMap(){
    return {
      'userId': userId,  // Ajout de l'ID utilisateur
      'title': title,
      'type': type,
      'category': category,
      'bedroom': bedroom,
      'bathroom': bathroom,
      'price': price,
      'location': location,
      'description': description,
      'images': images,
      'availability': availability
    };
  }

}