import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:agencysn/data/models/model_property.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class PropertyFormScreen extends StatefulWidget {
  final Property? property;
  final String? documentId;

  const PropertyFormScreen({Key? key, this.property, this.documentId}) : super(key: key);

  @override
  _PropertyFormState createState() => _PropertyFormState();
}

class _PropertyFormState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  List<dynamic> _existingImages = [];
  List<dynamic> _newImages = [];
  List<dynamic> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _bedroomController;
  late final TextEditingController _bathroomController;
  late final TextEditingController _locationController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  String? _type;
  String? _category;
  String? _availability;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.property != null) {
      _loadPropertyData(widget.property!);
    }
  }

  void _initializeControllers() {
    _titleController = TextEditingController();
    _bedroomController = TextEditingController();
    _bathroomController = TextEditingController();
    _locationController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  void _loadPropertyData(Property property) {
    _existingImages = property.images.cast<String>();
    _selectedImages = List.from(_existingImages);
    _titleController.text = property.title;
    _type = property.type;
    _category = property.category;
    _bedroomController.text = property.bedroom.toString();
    _bathroomController.text = property.bathroom.toString();
    _locationController.text = property.location;
    _priceController.text = property.price.toString();
    _descriptionController.text = property.description;
    _availability = property.availability;
    _selectedImages = property.images;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property != null ? 'Modifier la propriété' : 'Publier une propriété'),
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              _buildTextField('Titre', _titleController, Icons.short_text),
              const SizedBox(height: 30),
              _buildDropdown(
                'Type',
                ['Location', 'Vente'],
                    (value) => setState(() => _type = value),
                _type,
              ),
              const SizedBox(height: 30),
              _buildDropdown(
                'Catégorie',
                ['Maison', 'Appartement', 'Commercial'],
                    (value) => setState(() => _category = value),
                _category,
              ),
              const SizedBox(height: 30),
              _buildIntegerTextField('Nombre de chambres', _bedroomController, Icons.bedroom_parent_outlined),
              const SizedBox(height: 30),
              _buildIntegerTextField('Nombre de salles de bain', _bathroomController, Icons.bathroom_outlined),
              const SizedBox(height: 30),
              _buildTextField('Adresse', _locationController, Icons.location_on_rounded),
              const SizedBox(height: 30),
              _buildTextField('Prix', _priceController, Icons.price_change_rounded, TextInputType.number),
              const SizedBox(height: 30),
              _buildTextField('Description', _descriptionController, Icons.description, TextInputType.multiline),
              const SizedBox(height: 30),
              _buildDropdown(
                'Disponibilité',
                ['Disponible', 'Non-Disponible'],
                    (value) => setState(() => _availability = value),
                _availability,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                onPressed: _pickImages,
                label: const Text('Sélectionner des images'),
              ),
              const SizedBox(height: 20),
              _buildImageList(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _onSubmit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.property != null ? "Mettre à jour" : "Publier"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, [TextInputType? keyboardType]) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      keyboardType: keyboardType,
      validator: (value) => value?.isEmpty ?? true ? 'Ce champ est requis' : null,
    );
  }

  Widget _buildIntegerTextField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Ce champ est requis';
        }
        if (int.tryParse(value!) == null) {
          return 'Veuillez entrer un nombre entier valide';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(String label, List<String> items, void Function(String?) onChanged, String? value) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      value: value,
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Ce champ est requis' : null,
    );
  }

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      setState(() {
        _newImages.addAll(kIsWeb
            ? images.map((image) => image.readAsBytes())
            : images.map((image) => File(image.path)));
        _selectedImages = [..._existingImages, ..._newImages];
      });
    }
  }

  Widget _buildImageList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Images sélectionnées: ${_selectedImages.length}'),
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    children: [
                      _buildImageWidget(_selectedImages[index]),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildImageWidget(dynamic image) {
    if (image is String) {
      // C'est une URL d'image existante
      return Image.network(
        image,
        height: 100,
        width: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Erreur de chargement de l'image: $error");
          return _buildErrorPlaceholder();
        },
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else if (kIsWeb) {
      // C'est une nouvelle image sur le web
      return FutureBuilder<Uint8List>(
        future: image is Uint8List ? Future.value(image) : image,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Image.memory(snapshot.data!, height: 100, width: 100, fit: BoxFit.cover);
          } else {
            return Container(height: 100, width: 100, color: Colors.grey);
          }
        },
      );
    } else {
      // C'est une nouvelle image sur mobile
      return Image.file(image, height: 100, width: 100, fit: BoxFit.cover);
    }
  }
  Widget _buildErrorPlaceholder() {
    return Container(
      height: 100,
      width: 100,
      color: Colors.grey[300],
      child: Icon(Icons.error, color: Colors.red),
    );
  }
  int? _parseInteger(String value) {
    try {
      return int.parse(value);
    } catch (e) {
      return null;
    }
  }

  double? _parseDouble(String value) {
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      int? bedroom = _parseInteger(_bedroomController.text);
      int? bathroom = _parseInteger(_bathroomController.text);
      double? price = _parseDouble(_priceController.text);

      if (bedroom == null || bathroom == null || price == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez entrer des valeurs valides pour les champs numériques.')));
        return;
      }
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez sélectionner au moins une image')));
        return;
      }
      setState(() => _isLoading = true);
      try {
        final List<String> imageUrls = await _uploadImages();
        final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (userId.isEmpty) {
          throw Exception("Utilisateur non connecté");
        }

        final property = Property(
          userId: userId,
          title: _titleController.text,
          type: _type ?? '',
          category: _category ?? '',
          bedroom: int.parse(_bedroomController.text),
          bathroom: int.parse(_bathroomController.text),
          price: double.parse(_priceController.text),
          location: _locationController.text,
          description: _descriptionController.text,
          images: imageUrls,
          availability: _availability ?? '',
        );

        final propertiesCollection = FirebaseFirestore.instance.collection('properties');
        if (widget.property != null && widget.documentId != null) {
          await propertiesCollection.doc(widget.documentId!).update(property.toMap());
          _showSuccess('Propriété mise à jour avec succès');
        } else {
          await propertiesCollection.add(property.toMap());
          _showSuccess('Propriété publiée avec succès');
        }

        Navigator.of(context).pop();
      } catch (error) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));

    }finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<List<String>> _uploadImages() async {
    final List<String> imageUrls = [];
    for (var image in _selectedImages) {
      if (image is String) {
        // C'est une URL existante, vérifions si elle est toujours valide
        try {
          final response = await http.get(Uri.parse(image));
          if (response.statusCode == 200) {
            imageUrls.add(image);
          } else {
            print("L'image n'est plus disponible: $image");
          }
        } catch (e) {
          print("Erreur lors de la vérification de l'image: $e");
        }
      } else {
        // C'est une nouvelle image, procédons à l'upload
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('properties_images/${DateTime.now().toIso8601String()}');

          if (kIsWeb) {
            final Uint8List imageData = image is Uint8List ? image : await image;
            await ref.putData(imageData, SettableMetadata(contentType: 'image/jpeg'));
          } else {
            await ref.putFile(image);
          }
          final String url = await ref.getDownloadURL();
          imageUrls.add(url);
        } catch (e) {
          print("Erreur lors de l'upload de l'image: $e");
        }
      }
    }
    return imageUrls;
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ));
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bedroomController.dispose();
    _bathroomController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}