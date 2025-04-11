import 'dart:io';
import 'package:agencysn/data/models/vehicle_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class VehicleFormScreen extends StatefulWidget{
  final Vehicle? vehicle;
  final String? documentId;
  const VehicleFormScreen({Key? key,this.vehicle, this.documentId}): super(key: key);

  @override
  _VehicleFormState createState() => _VehicleFormState();

}

class _VehicleFormState extends State<VehicleFormScreen>{
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final List<dynamic> _existingImages = [];
  final List<dynamic> _newImages = [];
  List<dynamic> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  String? _type;
  String? _fuelType;
  DateTime? _year;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _yearController;
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _mileageController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.vehicle != null) {
      _loadVehicleData(widget.vehicle!);
    }
  }

  void _initializeControllers() {
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _yearController = TextEditingController();
    _makeController = TextEditingController();
    _modelController = TextEditingController();
    _mileageController = TextEditingController();
    _priceController = TextEditingController();
  }

  void _loadVehicleData(Vehicle vehicle) {
    setState(() {
      _existingImages.addAll(vehicle.images.cast<String>());
      _selectedImages = List.from(_existingImages);
      _titleController.text = vehicle.title;
      _type = vehicle.type; // Chargez la valeur actuelle ici
      _descriptionController.text = vehicle.description;
      _yearController.text = vehicle.year.toString();
      _makeController.text = vehicle.make;
      _modelController.text = vehicle.model;
      _mileageController.text = vehicle.mileage.toString();
      _priceController.text = vehicle.price.toString();
      _fuelType = vehicle.fuelType; // Chargez la valeur actuelle ici
      _year = DateTime(vehicle.year);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle != null ? 'Modifier le véhicule' : 'Publier un véhicule'),
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
              _buildTextField('Marque', _makeController, Icons.directions_car),
              const SizedBox(height: 30),
              _buildTextField('Modèle', _modelController, Icons.model_training),
              const SizedBox(height: 30),
              _buildYearField(),
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
                'Type de carburant',
                ['Essence', 'Diesel'],
                    (value) => setState(() => _fuelType = value),
                _fuelType, // Passez ici la valeur initiale
              ),

              const SizedBox(height: 30),
              _buildTextField(
                'Kilométrage',
                _mileageController,
                Icons.map,
                TextInputType.number,
              ),
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
        Icon(Icons.car_rental),
        SizedBox(width: 8),
        Text(
          'Publier un véhicule',
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
          : Text(widget.vehicle != null ? 'Modifier' : "Publier"),
    );
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      int? year = _parseInteger(_yearController.text);
      int? mileage = _parseInteger(_mileageController.text);
      double? price = _parseDouble(_priceController.text);

      if (year == null || mileage == null || price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer des valeurs valides pour les champs numériques.')),
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
        if (widget.vehicle != null) {
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

        final Vehicle vehicle = Vehicle(
          title: _titleController.text,
          description: _descriptionController.text,
          type: _type ?? '',
          price: price,
          make: _makeController.text,
          model: _modelController.text,
          year: year,
          fuelType: _fuelType ?? '',
          mileage: mileage.toDouble(),
          images: imageUrls,
          userId: userId,
        );

        final vehiclesCollection = FirebaseFirestore.instance.collection('vehicles');
        if (widget.vehicle != null && widget.documentId != null) {
          await vehiclesCollection.doc(widget.documentId).update(vehicle.toMap());
          _showSuccess('Véhicule mis à jour avec succès');
        } else {
          await vehiclesCollection.add(vehicle.toMap());
          _showSuccess('Véhicule publié avec succès');
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
            .child('vehicles_images/${DateTime.now().toIso8601String()}');

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

  int? _parseInteger(String value) {
    return int.tryParse(value);
  }

  double? _parseDouble(String value) {
    return double.tryParse(value);
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
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d+)?$'))],
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Ce champ est requis';
        }
        if (double.tryParse(value!) == null) {
          return 'Veuillez entrer un prix valide';
        }
        if (double.parse(value) <= 0) {
          return 'Le prix doit être un nombre décimal positif';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(String label, List<String> items, void Function(String?) onChanged, String? currentValue) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      value: currentValue, // Assurez-vous que cette valeur est bien définie
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

  Widget _buildYearField() {
    return ListTile(
      title: Text(_year?.year.toString() ?? 'Année'),
      leading: const Icon(Icons.calendar_today),
      onTap: () => _selectYear(context),
    );
  }

  Future<void> _selectYear(BuildContext context) async {
    final DateTime? newYear = await showDatePicker(
      context: context,
      initialDate: _year ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (newYear != null) {
      setState(() {
        _year = newYear;
        _yearController.text = _year!.year.toString();
      });
    }
  }

}
