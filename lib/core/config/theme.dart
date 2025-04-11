import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  primarySwatch: Colors.blue,
  primaryColor: Colors.blue,
  hintColor: Colors.grey,
  fontFamily: 'Roboto',
  canvasColor: Colors.grey[50], // Background color for various widgets
  scaffoldBackgroundColor: Colors.grey[100], // Background color for Scaffold
  cardColor: Colors.grey[200], // Background color for Card widget
  dividerColor: Colors.grey[400], // Color for dividers
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.blue, // Default button color
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  ),
  textTheme: TextTheme(
    displayLarge: const TextStyle(
        color: Colors.blue, fontSize: 32, fontWeight: FontWeight.bold),
    titleLarge: const TextStyle(
        color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.w600),
    bodyMedium: TextStyle(color: Colors.grey[800], fontSize: 16),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blue,
    elevation: 2,
    titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  iconTheme: const IconThemeData(
    color: Colors.blue,
    size: 24,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.blueAccent,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40.0),
      borderSide: const BorderSide(color: Colors.black12),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: Colors.blueGrey),
    ),
    labelStyle: const TextStyle(color: Colors.black38),
    hintStyle: const TextStyle(color: Colors.grey),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.grey[100], // Background color for BottomNavigationBar
    elevation: 2,
    selectedItemColor: Colors.blueAccent, // Color for selected item
    unselectedItemColor: Colors.grey, // Color for unselected items
    selectedLabelStyle: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
    unselectedLabelStyle: TextStyle(color: Colors.grey, fontSize: 12),
    showSelectedLabels: true,
    showUnselectedLabels: true,
  ),

  navigationRailTheme: NavigationRailThemeData(
    backgroundColor: Colors.grey[100], // Background color for NavigationRail
    elevation: 2, // Shadow depth for NavigationRail
    selectedLabelTextStyle: TextStyle(
      color: Colors.blue, // Color for the selected label
      fontSize: 12, // Font size for the selected label
      fontWeight: FontWeight.bold, // Font weight for the selected label
    ),
    unselectedLabelTextStyle: TextStyle(
      color: Colors.grey, // Color for the unselected label
      fontSize: 12, // Font size for the unselected label
    ),
    unselectedIconTheme: IconThemeData(
      color: Colors.grey, // Color for the unselected icons
    ),
  ),

  visualDensity: VisualDensity.adaptivePlatformDensity,
);
