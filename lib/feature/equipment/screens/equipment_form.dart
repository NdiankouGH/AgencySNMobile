import 'dart:io';
import 'dart:typed_data';

import 'package:agencysn/data/models/equipment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class EquipmentFormScreen extends StatefulWidget {
  final Equipment? equipment;
  final String? documentId;

  const EquipmentFormScreen({Key? key, this.equipment, this.documentId}) : super(key: key);

  @override
  _EquipmentFormState createState() => _EquipmentFormState();
}

class _EquipmentFormState extends State<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final List<dynamic> _existingImages = [];
  final List<dynamic> _newImages = [];
  List<dynamic> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  String? _type;
  String? _category;
  String? _condition;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.equipment != null) {
      _loadEquipmentData(widget.equipment!);
    }
  }

  void _initializeControllers() {
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _locationController = TextEditingController();
  }

  void _loadEquipmentData(Equipment equipment) {
    setState(() {
      _existingImages.addAll(equipment.images.cast<String>());
      _selectedImages = List.from(_existingImages);
      _titleController.text = equipment.title;
      _type = equipment.type;
      _descriptionController.text = equipment.description;
      _priceController.text = equipment.price.toString();
      _category = equipment.category;
      _condition = equipment.condition;
      _locationController.text = equipment.location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.equipment != null ? 'Modifier l\'équipement' : 'Publier un équipement'),
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
              _buildHeader(),
              const SizedBox(height: 30),
              _buildTextField('Titre', _titleController, Icons.short_text),
              const SizedBox(height: 30),
              _buildDropdown(
                  'Type',
                  ['Location', 'Vente'],
                      (value) => setState(() => _type = value),
                  _type
              ),
              const SizedBox(height: 30),
              _buildTextField('Prix', _priceController, Icons.price_change_sharp, TextInputType.number),
              const SizedBox(height: 30),
              _buildDropdown(
                  'Catégorie',
                  _categories,
                      (value) => setState(() => _category = value),
                  _category
              ),
              const SizedBox(height: 30),
              _buildDropdown(
                  'Condition',
                  ['Neuf', 'Occasion'],
                      (value) => setState(() => _condition = value),
                  _condition
              ),
              const SizedBox(height: 30),
              _buildTextField('Localisation', _locationController, Icons.location_on),
              const SizedBox(height: 30),
              _buildTextField(
                'Description',
                _descriptionController,
                Icons.description,
                TextInputType.multiline,
              ),
              const SizedBox(height: 30),
              _buildImagePickerButton(),
              const SizedBox(height: 20),
              _buildImageList(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.build),
        SizedBox(width: 8),
        Text(
          'Publier un équipement',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImagePickerButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.image),
      onPressed: _pickImages,
      label: const Text('Sélectionner des images'),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _onSubmit,
      child: _isLoading
          ? const CircularProgressIndicator()
          : Text(widget.equipment != null ? 'Modifier' : "Publier"),
    );
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      double? price = double.tryParse(_priceController.text);

      if (price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer un prix valide.')),
        );
        return;
      }
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner au moins une image')),
        );
        return;
      }
      setState(() => _isLoading = true);

      try {
        List<String> imageUrls;
        if (widget.equipment != null) {
          List<String> refreshedUrls = await _refreshImageUrls(_existingImages.cast<String>());
          List<String> newImageUrls = await _uploadImages(_newImages);
          imageUrls = [...refreshedUrls, ...newImageUrls];
        } else {
          imageUrls = await _uploadImages(_selectedImages);
        }

        final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (userId.isEmpty) {
          throw Exception("Utilisateur non connecté");
        }

        final Equipment equipment = Equipment(
          title: _titleController.text,
          type: _type ?? '',
          description: _descriptionController.text,
          price: price,
          category: _category ?? '',
          condition: _condition ?? '',
          location: _locationController.text,
          images: imageUrls,
          userId: userId,
        );

        final equipmentsCollection = FirebaseFirestore.instance.collection('equipments');
        if (widget.equipment != null && widget.documentId != null) {
          await equipmentsCollection.doc(widget.documentId).update(equipment.toMap());
          _showSuccess('Équipement mis à jour avec succès');
        } else {
          await equipmentsCollection.add(equipment.toMap());
          _showSuccess('Équipement publié avec succès');
        }
        Navigator.of(context).pop();
      } catch (e) {
        _showError('Erreur lors de la publication: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<List<String>> _refreshImageUrls(List<String> oldUrls) async {
    List<String> newUrls = [];
    for (String oldUrl in oldUrls) {
      try {
        Uri uri = Uri.parse(oldUrl);
        String path = uri.pathSegments.sublist(3).join('/');
        String newUrl = await FirebaseStorage.instance.ref(path).getDownloadURL();
        newUrls.add(newUrl);
      } catch (e) {
        print('Erreur lors du rafraîchissement de l\'URL : $e');
        newUrls.add(oldUrl);
      }
    }
    return newUrls;
  }

  Future<List<String>> _uploadImages(List<dynamic> images) async {
    List<String> imageUrls = [];
    for (var image in images) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('equipment_images/${DateTime.now().toIso8601String()}');

        if (image is String) {
          imageUrls.add(image);
          continue;
        }

        if (kIsWeb) {
          Uint8List imageData = image is Uint8List ? image : await image;
          await ref.putData(imageData, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          await ref.putFile(image);
        }

        String url = await ref.getDownloadURL();
        imageUrls.add(url);
      } catch (e) {
        print("Erreur lors de l'upload de l'image: $e");
      }
    }
    return imageUrls;
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

  Widget _buildImageWidget(dynamic image) {
    if (image is String) {
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
      return Image.file(image, height: 100, width: 100, fit: BoxFit.cover);
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

  Widget _buildErrorPlaceholder() {
    return Container(
      height: 100,
      width: 100,
      color: Colors.grey[300],
      child: const Icon(Icons.error, color: Colors.red),
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

  Widget _buildDropdown(String label, List<String> items, void Function(String?) onChanged, String? currentValue) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      value: currentValue,
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
  final List<String> _categories = [
    'Outils électriques',
    'Outils manuels',
    'Équipement de jardin',
    'Équipement de construction',
    'Échelles et échafaudages',
    'Équipement de peinture',
    'Équipement de nettoyage',
    'Équipement de soudage',
    'Équipement de plomberie',
    'Équipement électrique',
    'Équipement de manutention',
    'Équipement de mesure et de test',
    'Équipement de sécurité',
    'Équipement de chauffage et climatisation',
    'Équipement audio-visuel',
    'Équipement informatique',
    'Équipement de camping',
    'Équipement sportif',
    'Équipement médical',
    'Équipement événementiel',
    'Autre'
  ];
}
