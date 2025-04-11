import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connexion',
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
              'Connexion à AgencySN',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  SizedBox(height: MediaQuery.of(context).size.width * 0.1),
                  textFieldForm('Email', emailController, TextInputType.emailAddress, Icons.email),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.1),
                  textFieldForm('Mot de passe', passwordController, TextInputType.visiblePassword, Icons.password, isPassword: true),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.1),
                  ElevatedButton(
                    onPressed: _onSubmit,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                      foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Se connecter"),
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
                    onPressed: _loginWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: Colors.blue.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Pas encore inscrit?', style: TextStyle(color: Colors.grey)),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text(
                    'Inscrivez-vous',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
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

    setState(() {
      isLoading = true;
    });

    try {
       await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Une erreur s\'est produite.';
      if (e.code == 'user-not-found') {
        errorMessage = 'Aucun utilisateur trouvé avec cet email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Mot de passe incorrect.';
      }
      _showError(errorMessage);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
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
        content: Text(message, style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
