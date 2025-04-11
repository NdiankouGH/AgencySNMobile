import 'package:agencysn/data/models/user.dart';
import 'package:agencysn/feature/authentification/screens/login_screen.dart';
import 'package:agencysn/feature/home/screens/setting_screen.dart';
import 'package:agencysn/feature/profil/screens/announcement.dart';
import 'package:agencysn/feature/profil/screens/edit_profil_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            return const DashboardScreenContent();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

class DashboardScreenContent extends StatefulWidget {
  const DashboardScreenContent({super.key});

  @override
  _DashboardScreenContentState createState() => _DashboardScreenContentState();
}

class _DashboardScreenContentState extends State<DashboardScreenContent> {
  UserModel? userModel;
  bool isLoading = true;

  int countUserAnnounce = 0;
  int countUserFavorite = 0;
  int countActitvitie = 0;


  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchCount();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userModel = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Erreur de récupération des données utilisateur : $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCount() async {
    User? user = FirebaseAuth.instance.currentUser;
    int countProperties = 0;
    if (user != null) {
      try {
        final propertieSnapshot = await FirebaseFirestore.instance.collection(
            'properties')
            .where('userId', isEqualTo: user.uid).get();
        countProperties = propertieSnapshot.docs.length;

        final vehiclesSnapshot = await FirebaseFirestore.instance.collection(
            'vehicles')
            .where('userId', isEqualTo: user.uid).get();
       int countVehicles = vehiclesSnapshot.docs.length;

        final equipmentsSnapshot = await FirebaseFirestore.instance.collection(
            'equipments')
            .where('userId', isEqualTo: user.uid).get();
      int  countEquipments = equipmentsSnapshot.docs.length;

        final favoritesSnapshot = await FirebaseFirestore.instance.collection(
            'favorites')
            .where('userId', isEqualTo: user.uid).get();
          countUserFavorite = favoritesSnapshot.docs.length;

      countUserAnnounce = countEquipments + countProperties +countVehicles ;
        setState(() {
          isLoading = false;
        });
      } catch (e) {
        print("Erreur lors du chargement des données : $e");
        setState(() {
          isLoading = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStatsCard(),
                const SizedBox(height: 24),
                _buildActionsGrid(),
                const SizedBox(height: 24),
                _buildMenuSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[800] ?? Colors.blue, Colors.blue[600] ?? Colors.blueAccent],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 45,
                      backgroundImage: AssetImage('assets/images/agencysn-logo.png'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userModel?.email ?? 'user@domainname.com',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userModel?.name ?? 'Nom complet',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => SettingScreen() )),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('$countUserAnnounce', 'Annonces', Icons.list_alt),
          _buildVerticalDivider(),
          _buildStatItem('$countActitvitie', 'Actives', Icons.check_circle),
          _buildVerticalDivider(),
          _buildStatItem('$countUserFavorite', 'Favoris', Icons.favorite),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 28),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 50,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildActionCard(
          'Mes Annonces',
          Icons.list_alt,
          Colors.blue[600]!,
              () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AnnouncementScreen()),
          ),
        ),
        _buildActionCard(
          'Favoris',
          Icons.favorite,
          Colors.red[400]!,
              () {
            // Navigation vers les favoris
          },
        ),
        _buildActionCard(
          'Messages',
          Icons.message,
          Colors.green[600]!,
              () {
            // Navigation vers les messages
          },
        ),
        _buildActionCard(
          'Mes demandes',
          Icons.grade,
          Colors.purple[600]!,
              () {
            // Navigation vers les statistiques
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            'Modifier mon profil',
            Icons.edit,
            Colors.blue[600]!,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            'Paramètres',
            Icons.settings,
            Colors.grey[700]!,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingScreen(),
                  ),
                );
              }
          ),
          _buildDivider(),
          _buildMenuItem(
            'Aide & Support',
            Icons.help_outline,
            Colors.green[600]!,
                () {

            },
          ),
          _buildDivider(),
          _buildMenuItem(
            'Déconnexion',
            Icons.logout,
            Colors.red[400]!,
                () async {
              // Afficher une boîte de dialogue de confirmation
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text(
                      'Êtes-vous sûr de vouloir vous déconnecter ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Déconnexion',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[200],
    );
  }





}