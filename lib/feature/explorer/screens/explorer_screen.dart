import 'package:agencysn/feature/equipment/widgets/equipment_widget.dart';
import 'package:agencysn/feature/properties/widgets/property_widgets.dart';
import 'package:agencysn/feature/vehicles/widgets/vehicle_widget.dart';
import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildTabController());
  }

  // Widget pour le tableau des card
  Widget _buildTabController() {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  title: const Text('Explorer'),
                  actions: [
                    IconButton(
                        onPressed: () {}, icon: const Icon(Icons.search)),
                    IconButton(
                        onPressed: () {}, icon: const Icon(Icons.filter_list)),
                  ],
                  pinned: true,
                  floating: true,
                  bottom: const TabBar(tabs: [
                    Tab(
                      text: 'Proprietes',
                    ),
                    Tab(
                      text: 'Vehicules',
                    ),
                    Tab(
                      text: 'Equipements',
                    )
                  ]),
                )
              ];
            },
            body: const TabBarView(children: [
              PropertyGrid(),
              VehicleGrid(),
              EquipmentGrid(),
            ]),
          ),
          bottomNavigationBar: BottomNavigationBar(items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.grid_view), label: "Grille"),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: "Liste"),
          ]),
        ));
  }
}
