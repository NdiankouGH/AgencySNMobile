import 'package:flutter/material.dart';

class VehicleListScreen {

  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des vehicule'),
      ),
      body: Center(
        child: Text('Liste des vehicules disponible'),
      ),
    );
  }
}