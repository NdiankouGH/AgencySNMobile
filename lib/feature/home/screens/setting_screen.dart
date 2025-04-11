import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // États
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'Français';
  bool _isNotificationEnabled = true;
  String _selectedNotificationSound = 'Default';
  bool _isNewListingNotificationEnabled = false;
  String _notificationFrequency = 'Quotidiennement';
  bool _vibrationEnabled = true;
  bool _doNotDisturbEnabled = false;
  bool _dataStorageOptimizationEnabled = false;
  int _currentStorageSize = 0;
  int _availableStorageSpace = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeStorage();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _darkModeEnabled = prefs.getBool('darkMode') ?? false;
        _selectedLanguage = prefs.getString('language') ?? 'Français';
        _isNotificationEnabled = prefs.getBool('notifications') ?? true;
        _selectedNotificationSound = prefs.getString('notificationSound') ?? 'Default';
        _isNewListingNotificationEnabled = prefs.getBool('newListingNotifications') ?? false;
        _notificationFrequency = prefs.getString('notificationFrequency') ?? 'Quotidiennement';
        _vibrationEnabled = prefs.getBool('vibration') ?? true;
        _doNotDisturbEnabled = prefs.getBool('doNotDisturb') ?? false;
        _dataStorageOptimizationEnabled = prefs.getBool('dataOptimization') ?? false;
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des paramètres');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeStorage() async {
    await _calculateTotalStorageSize();
    await _checkAvailableStorage();
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setBool('darkMode', _darkModeEnabled),
        prefs.setString('language', _selectedLanguage),
        prefs.setBool('notifications', _isNotificationEnabled),
        prefs.setString('notificationSound', _selectedNotificationSound),
        prefs.setBool('newListingNotifications', _isNewListingNotificationEnabled),
        prefs.setString('notificationFrequency', _notificationFrequency),
        prefs.setBool('vibration', _vibrationEnabled),
        prefs.setBool('doNotDisturb', _doNotDisturbEnabled),
        prefs.setBool('dataOptimization', _dataStorageOptimizationEnabled),
      ]);
      _showSuccessSnackBar('Paramètres sauvegardés avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde des paramètres');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Sauvegarder les modifications',
          ),
        ],
      ),
      body: _buildSettingsBody(),
    );
  }

  Widget _buildSettingsBody() {
    return ListView(
      children: [
        _buildAccountSettings(),
        const Divider(),
        _buildNotificationSettings(),
        const Divider(),
        _buildPrivacySettings(),
        const Divider(),
        _buildLanguageSettings(),
        const Divider(),
        _buildAppearanceSettings(),
        const Divider(),
        _buildDataStorageSettings(),
        const Divider(),
        _buildAboutSupport(),
      ],
    );
  }


  Widget _buildAccountSettings() {
    return ExpansionTile(
      leading: const Icon(Icons.person),
      title: const Text('Compte'),
      children: [
        _buildEmailUpdateForm(),
        _buildPasswordUpdateForm(),
        _buildTwoFactorAuthSettings(),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return ExpansionTile(
      leading: const Icon(Icons.notifications),
      title: const Text('Notifications'),
      children: [
        // Notification générale
        SwitchListTile(
          title: const Text('Activer les notifications'),
          value: _isNotificationEnabled,
          onChanged: (bool value) {
            setState(() {
              _isNotificationEnabled = value;
              // Désactiver toutes les autres options si les notifications sont désactivées
              if (!value) {
                _isNewListingNotificationEnabled = false;
                _vibrationEnabled = false;
              }
              _saveNotificationSettings(); // Méthode à implémenter pour sauvegarder
            });
          },
        ),

        // Notifications pour nouvelles annonces
        SwitchListTile(
          title: const Text('Notifications pour les nouvelles annonces'),
          value: _isNewListingNotificationEnabled,
          onChanged: (bool value) {
            setState(() {
              _isNewListingNotificationEnabled = value;
              _saveNotificationSettings(); // Méthode à implémenter pour sauvegarder
            });
          },
        ),

        // Son de notification
        ListTile(
          title: const Text('Son de notification'),
          subtitle: Text(_selectedNotificationSound),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Sélectionner le son de notification'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: [
                        _buildSoundOption('Son par défaut'),
                        _buildSoundOption('Sonnerie 1'),
                        _buildSoundOption('Sonnerie 2'),
                        _buildSoundOption('Sonnerie 3'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),

        // Fréquence de notification
        ListTile(
          title: const Text('Fréquence de notification'),
          subtitle: Text(_notificationFrequency),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Fréquence de notification'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: [
                        _buildFrequencyOption('Toutes les heures'),
                        _buildFrequencyOption('Toutes les 2 heures'),
                        _buildFrequencyOption('Toutes les 4 heures'),
                        _buildFrequencyOption('Une fois par jour'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),

        // Vibration
        SwitchListTile(
          title: const Text('Vibration'),
          value: _vibrationEnabled,
          onChanged: (value) => setState(() {
            _vibrationEnabled = value;
            _saveNotificationSettings(); // Méthode à implémenter pour sauvegarder
          }),
        ),

        // Mode Ne pas déranger
        SwitchListTile(
          title: const Text('Ne pas déranger'),
          value: _doNotDisturbEnabled,
          onChanged: (value) => setState(() {
            _doNotDisturbEnabled = value;
            _saveNotificationSettings(); // Méthode à implémenter pour sauvegarder
          }),
        ),
      ],
    );
  }
  // Méthodes auxiliaires à ajouter dans votre classe
  Widget _buildSoundOption(String soundName) {
    return ListTile(
      title: Text(soundName),
      onTap: () {
        setState(() {
          _selectedNotificationSound = soundName;
          _saveNotificationSettings();
        });
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildFrequencyOption(String frequency) {
    return ListTile(
      title: Text(frequency),
      onTap: () {
        setState(() {
          _notificationFrequency = frequency;
          _saveNotificationSettings();
        });
        Navigator.of(context).pop();
      },
    );
  }

// Méthode pour sauvegarder les paramètres (à implémenter selon votre besoin)
  void _saveNotificationSettings() {
    // Implémentez ici la logique de sauvegarde
    // Par exemple, avec SharedPreferences ou votre système de stockage
  }

  Widget _buildPrivacySettings() {
    return ExpansionTile(
      leading: const Icon(Icons.lock),
      title: const Text('Confidentialité'),
      children: [
        ListTile(
          title: const Text('Gestion des permissions'),
          onTap: () {
            // Logique pour gérer les permissions
          },
        ),
        ListTile(
          title: const Text('Préférences de confidentialité'),
          onTap: () {
            // Logique pour gérer les préférences de confidentialité
          },
        ),
        ListTile(
          title: const Text('Politique de confidentialité'),
          onTap: () {
            // Logique pour afficher la politique de confidentialité
          },
        ),
      ],
    );
  }

  Widget _buildLanguageSettings() {
    return ExpansionTile(
      leading: const Icon(Icons.language),
      title: const Text('Langue'),
      children: [
        ListTile(
          title: const Text('Langue de l\'application'),
          subtitle: Text(_selectedLanguage),
          onTap: () {
            // Logique pour choisir la langue
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    return ExpansionTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('Apparence'),
      children: [
        SwitchListTile(
          title: const Text('Mode sombre'),
          value: _darkModeEnabled,
          onChanged: (value) {
            setState(() => _darkModeEnabled = value);
            _saveSettings(); // Sauvegarde l'état du mode sombre
          },
        ),
        ListTile(
          title: const Text('Thème'),
          onTap: () {
            // Logique pour choisir le thème
          },
        ),
      ],
    );
  }



  Widget _buildAboutSupport() {
    return ExpansionTile(
      leading: const Icon(Icons.info),
      title: const Text('À propos & Support'),
      children: [
        ListTile(
          title: const Text('À propos de l\'application'),
          onTap: () {
            // Logique pour afficher des informations sur l'application
          },
        ),
        ListTile(
          title: const Text('Support'),
          onTap: () {
            // Logique pour afficher les informations de support
          },
        ),
        ListTile(
          title: const Text('Contactez-nous'),
          onTap: () {
            // Logique pour contacter le support
          },
        ),
      ],
    );
  }


  Widget _buildEmailUpdateForm() {
    return ListTile(
      title: const Text('Changer l\'adresse e-mail'),
      onTap: () => _showEmailUpdateModal(),
    );
  }

  void _showEmailUpdateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEmailUpdateBottomSheet(),
    );
  }

  Widget _buildEmailUpdateBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildModalHandle(),
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: _buildCloseButton(),
            title: const Text('Modifier l\'adresse mail'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: _buildEmailTextField(),
              ),
            ),
          ),
          _buildEmailUpdateButton(),
        ],
      ),
    );
  }

  Widget _buildPasswordUpdateForm() {
    return ListTile(
      title: const Text('Changer le mot de passe'),
      onTap: () => _showPasswordUpdateModal(),
    );
  }

  void _showPasswordUpdateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPasswordUpdateBottomSheet(),
    );
  }

  Widget _buildPasswordUpdateBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildModalHandle(),
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: _buildCloseButton(),
            title: const Text('Modifier le mot de passe'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildPasswordTextField(),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordTextField(),
                  ],
                ),
              ),
            ),
          ),
          _buildPasswordUpdateButton(),
        ],
      ),
    );
  }

  Widget _buildTwoFactorAuthSettings() {
    return ListTile(
      title: const Text('Vérification en deux étapes'),
      onTap: () {
        // Logique pour activer la 2FA
      },
    );
  }

  Widget _buildModalHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildCloseButton() {
    return IconButton(
      icon: const Icon(Icons.close, color: Colors.black),
      onPressed: () => Navigator.pop(context),
    );
  }

  Widget _buildEmailTextField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.email_outlined, color: Colors.blue),
        labelText: 'Email',
      ),
      validator: (value) => !value!.contains('@') ? 'Email invalide' : null,
    );
  }

  Widget _buildPasswordTextField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock, color: Colors.blue),
        labelText: 'Mot de passe',
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
      validator: (value) => value == null || value.length < 6 ? 'Le mot de passe doit contenir au moins 6 caractères' : null,
    );
  }

  Widget _buildConfirmPasswordTextField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isPasswordVisible,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.lock, color: Colors.blue),
        labelText: 'Confirmer le mot de passe',
      ),
      validator: (value) => value != _passwordController.text ? 'Les mots de passe ne correspondent pas' : null,
    );
  }

  Widget _buildEmailUpdateButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 18,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.blue.withOpacity(0.5),
      ),
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          _updateEmail(_emailController.text);
        }
      },
      child: const Text('Enregistrer'),
    );
  }

  Widget _buildPasswordUpdateButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 18,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.blue.withOpacity(0.5),
      ),
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          _updatePassword(_passwordController.text);
        }
      },
      child: const Text('Enregistrer'),
    );
  }

  Future<void> _updateEmail(String newEmail) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateEmail(newEmail);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'email': newEmail});
        _showSuccessSnackBar('Email mis à jour avec succès');
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la mise à jour de l\'email');
    } finally {
      setState(() => _isLoading = false);
    }
  }



  // Calculer la taille totale des données stockées
  Future<void> _calculateTotalStorageSize() async {
    try {
      // Récupérer le répertoire de l'application
      final appDir = await getApplicationDocumentsDirectory();

      // Calculer la taille totale de tous les fichiers
      int totalSize = 0;
      final dir = Directory(appDir.path);

      // Parcourir récursivement tous les fichiers
      await dir.list(recursive: true).forEach((FileSystemEntity file) {
        if (file is File) {
          totalSize += file.lengthSync();
        }
      });

      setState(() {
        _currentStorageSize = totalSize;
      });
    } catch (e) {
      print('Erreur lors du calcul de la taille du stockage : $e');
    }
  }

  // Vérifier l'espace de stockage disponible
  Future<void> _checkAvailableStorage() async {
    try {
      if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final stat = await directory.stat();
          // Sur Android, nous devons utiliser une autre approche car freeSpace n'est pas disponible
          final df = await Process.run('df', [directory.path]);
          if (df.exitCode == 0) {
            final lines = df.stdout.toString().split('\n');
            if (lines.length > 1) {
              final values = lines[1].split(RegExp(r'\s+'));
              if (values.length > 3) {
                setState(() {
                  _availableStorageSpace = int.tryParse(values[3]) ?? 0;
                });
              }
            }
          }
        }
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        // Sur iOS, nous utilisons une estimation basée sur la taille totale
        final stat = await directory.stat();
        setState(() {
          // Estimation arbitraire de l'espace disponible
          _availableStorageSpace = 1024 * 1024 * 1024; // 1 GB par défaut
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification de l\'espace de stockage : $e');
      setState(() {
        _availableStorageSpace = 0;
      });
    }
  }

  // Méthode pour formater la taille du stockage
  String _formatStorageSize(int bytes) {
    const List<String> units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  // Calculer la taille des données par type
  Future<int> _calculateDataSize(String dataType) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(appDir.path);
      int totalSize = 0;

      await for (final file in dir.list(recursive: true)) {
        if (file is File) {
          switch (dataType) {
            case 'annonces':
              if (file.path.contains('annonces')) {
                totalSize += await file.length();
              }
              break;
            case 'messages':
              if (file.path.contains('messages')) {
                totalSize += await file.length();
              }
              break;
            case 'images':
              if (file.path.contains('.jpg') ||
                  file.path.contains('.png') ||
                  file.path.contains('.jpeg')) {
                totalSize += await file.length();
              }
              break;
            case 'cache':
              if (file.path.contains('cache')) {
                totalSize += await file.length();
              }
              break;
          }
        }
      }
      return totalSize;
    } catch (e) {
      print('Erreur lors du calcul de la taille des données : $e');
      return 0;
    }
  }

  // Optimisation du stockage
  Future<void> _performStorageOptimization() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(appDir.path);

      // Supprimer les fichiers temporaires
      await dir.list(recursive: true).forEach((FileSystemEntity file) {
        if (file is File) {
          // Exemple : supprimer les fichiers temporaires vieux de plus de 30 jours
          final stat = file.statSync();
          final now = DateTime.now();
          final fileDate = stat.modified;

          if (now.difference(fileDate).inDays > 30) {
            file.deleteSync();
          }
        }
      });

      // Recalculer la taille du stockage après optimisation
      await _calculateTotalStorageSize();
      await _checkAvailableStorage();

      // Notification d'optimisation réussie
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Optimisation du stockage terminée')),
      );
    } catch (e) {
      print('Erreur lors de l\'optimisation du stockage : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de l\'optimisation du stockage')),
      );
    }
  }

  // Nettoyage des données
  Future<void> _cleanupUnusedData() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(appDir.path);

      // Supprimer les fichiers considérés comme inutilisés
      await dir.list(recursive: true).forEach((FileSystemEntity file) {
        if (file is File) {
          // Exemple de critères pour supprimer des fichiers
          if (file.path.contains('temp') ||
              file.path.contains('cache') ||
              file.lengthSync() == 0) {
            file.deleteSync();
          }
        }
      });

      // Recalculer la taille après nettoyage
      await _calculateTotalStorageSize();
      await _checkAvailableStorage();

      // Notification de nettoyage réussi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nettoyage des données terminé')),
      );
    } catch (e) {
      print('Erreur lors du nettoyage des données : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec du nettoyage des données')),
      );
    }
  }

  // Dialogue de gestion des données
  void _showDataManagementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<int>>(
          future: Future.wait([
            _calculateDataSize('annonces'),
            _calculateDataSize('messages'),
            _calculateDataSize('images'),
            _calculateDataSize('cache'),
          ]),
          builder: (context, AsyncSnapshot<List<int>> snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                content: Center(child: CircularProgressIndicator()),
              );
            }

            final List<int> sizes = snapshot.data ?? [0, 0, 0, 0];

            return AlertDialog(
              title: const Text('Gestion des données stockées'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    _buildDataTypeItem('Annonces', sizes[0]),
                    _buildDataTypeItem('Messages', sizes[1]),
                    _buildDataTypeItem('Images', sizes[2]),
                    _buildDataTypeItem('Cache', sizes[3]),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Supprimer les données inutilisées'),
                  onPressed: () {
                    _cleanupUnusedData();
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Fermer'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Construction d'un élément de type de données
  Widget _buildDataTypeItem(String label, int size) {
    return ListTile(
      title: Text(label),
      trailing: Text(_formatStorageSize(size)),
    );
  }

  // Dialogue de nettoyage des données
  void _showDataCleanupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Nettoyage des données'),
          content: Text('Voulez-vous supprimer les données temporaires et inutilisées ?'),
          actions: [
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Nettoyer'),
              onPressed: () {
                _cleanupUnusedData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Vérifier et afficher les détails du stockage
  void _checkAndDisplayStorageDetails() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détails du stockage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Taille totale des données : ${_formatStorageSize(_currentStorageSize)}'),
              Text('Espace disponible : ${_formatStorageSize(_availableStorageSpace)}'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Méthode principale de construction de l'interface
  Widget _buildDataStorageSettings() {
    return ExpansionTile(
      leading: const Icon(Icons.storage),
      title: const Text('Stockage des données'),
      children: [
        // Optimisation du stockage
        SwitchListTile(
          title: const Text('Optimisation du stockage'),
          subtitle: const Text('Compresse et nettoie automatiquement les données'),
          value: _dataStorageOptimizationEnabled,
          onChanged: (value) {
            setState(() {
              _dataStorageOptimizationEnabled = value;
              _saveSettings(); // Sauvegarde l'état de l'optimisation

              // Logique supplémentaire si l'optimisation est activée
              if (value) {
                _performStorageOptimization();
              }
            });
          },
        ),

        // Gestion des données stockées
        ListTile(
          title: const Text('Gérer les données stockées'),
          subtitle: Text('Taille totale : ${_formatStorageSize(_currentStorageSize)}'),
          onTap: () {
            _showDataManagementDialog();
          },
        ),

        // Options de nettoyage des données
        ListTile(
          title: const Text('Nettoyage des données'),
          subtitle: const Text('Supprime les données temporaires et inutilisées'),
          onTap: () {
            _showDataCleanupDialog();
          },
        ),

        // Espace de stockage disponible
        ListTile(
          title: const Text('Espace de stockage'),
          subtitle: Text('Disponible : ${_formatStorageSize(_availableStorageSpace)}'),
          onTap: () {
            _checkAndDisplayStorageDetails();
          },
        ),
      ],
    );
  }



  Future<void> _updatePassword(String newPassword) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        _showSuccessSnackBar('Mot de passe mis à jour avec succès');
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la mise à jour du mot de passe');
    } finally {
      setState(() => _isLoading = false);
    }
  }

}
