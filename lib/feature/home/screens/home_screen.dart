import 'package:agencysn/feature/explorer/screens/explorer_screen.dart';
import 'package:agencysn/feature/messaging/screens/message_list_screen.dart';
import 'package:agencysn/feature/profil/screens/Favorite_screen.dart';
import 'package:agencysn/feature/profil/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    ExploreScreen(),
    FavoriteScreen(),
    MessageListScreen(),
    DashboardScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder( // Utilisez le LayoutBuilder intégré
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {  // Seuil pour utiliser NavigationRail
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: Icon(Icons.explore),
                      label: Text('Explorer'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favoris'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.message),
                      label: Text('Messages'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person),
                      label: Text('Profil'),
                    ),
                  ],
                ),
                Expanded(
                  child: _pages[_selectedIndex],
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(
                  child: _pages[_selectedIndex],
                ),
                BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorer'),
                    BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoris'),
                    BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
                  ],
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                ),
              ],
            );
          }
        },
      ),
    );
  }
}