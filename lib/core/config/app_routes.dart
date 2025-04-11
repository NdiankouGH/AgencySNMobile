import 'package:agencysn/feature/authentification/screens/login_screen.dart';
import 'package:agencysn/feature/authentification/screens/signup_screen.dart';
import 'package:agencysn/feature/explorer/screens/explorer_screen.dart';
import 'package:agencysn/feature/home/screens/home_screen.dart';
import 'package:agencysn/feature/messaging/screens/message_list_screen.dart';
import 'package:agencysn/feature/profil/screens/Favorite_screen.dart';
import 'package:agencysn/feature/profil/screens/announcement.dart';
import 'package:agencysn/feature/profil/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';


class AppRoutes {
  static const String home = '/';
  static const String explore = '/explore';
  static const String favorites = '/favorites';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String announcements = '/announcements';

  static const String newAd = '/new-ad';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String setting = '/setting';


  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case explore:
        return MaterialPageRoute(builder: (_) => const ExploreScreen());
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoriteScreen());
      case messages:
        return MaterialPageRoute(builder: (_) => const MessageListScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case announcements:
        return MaterialPageRoute(builder: (_) => const AnnouncementScreen());

     //
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
