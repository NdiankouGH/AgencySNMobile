import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inscription',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Inscription à AgencySN',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  textFieldForm('Nom', nameController, TextInputType.name, Icons.person),
                  const SizedBox(height: 20),
                  textFieldForm('Numéro de téléphone', telController, TextInputType.phone, Icons.phone),
                  const SizedBox(height: 20),
                  textFieldForm('Email', emailController, TextInputType.emailAddress, Icons.email),
                  const SizedBox(height: 20),
                  textFieldForm('Mot de passe', passwordController, TextInputType.visiblePassword, Icons.lock, isPassword: true),
                  const SizedBox(height: 20),
                  textFieldForm('Confirmer le mot de passe', confirmPasswordController, TextInputType.visiblePassword, Icons.lock, isPassword: true),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("S'inscrire"),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Expanded(child: Divider(thickness: 0.5)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text('Ou continuer avec'),
                      ),
                      Expanded(child: Divider(thickness: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Image.asset(
                      'assets/images/logo-google.png',
                      height: 24.0,
                    ),
                    label: const Text('Se connecter avec Google'),
                    onPressed: _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Déjà un compte?',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          shadowColor: Colors.blue.withOpacity(0.5),
                        ),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget textFieldForm(String label, TextEditingController controller, TextInputType type, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        hintText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez remplir le champ';
        }
        if (isPassword && value.length < 6) {
          return 'Le mot de passe doit contenir au moins 6 caractères';
        }
        return null;
      },
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showError("Les mots de passe ne correspondent pas.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
        'name': nameController.text,
        'email': emailController.text,
        'telephone': telController.text,
        'createdAt': Timestamp.now(),
      });

      _showSuccess("Inscription réussie !");
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _showError('Le mot de passe est trop faible.');
      } else if (e.code == 'email-already-in-use') {
        _showError('Un compte existe déjà avec cet email.');
      } else {
        _showError(e.message ?? 'Une erreur est survenue.');
      }
    } catch (e) {
      _showError('Une erreur est survenue.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      if (googleAuth?.accessToken != null && googleAuth?.idToken != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );

        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
          'name': googleUser?.displayName,
          'email': googleUser?.email,
          'telephone': '', // Le numéro de téléphone peut être vide
          'createdAt': Timestamp.now(),
        });

        _showSuccess("Connexion réussie avec Google !");
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showError('Une erreur est survenue lors de la connexion avec Google.');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    telController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
