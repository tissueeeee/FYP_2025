import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fyp_project/business/providers/business_provider.dart';
import 'package:fyp_project/business/providers/listing_provider.dart';
import 'package:fyp_project/firebase_options.dart';
import 'package:fyp_project/providers/cart_provider.dart';
import 'package:fyp_project/providers/order_provider.dart';
import 'package:fyp_project/providers/user_provider.dart';
import 'package:fyp_project/screens/delivery_product_page.dart';
import 'package:fyp_project/services/payment_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/gng_screen.dart';
import 'screens/sign_in_page.dart';
import 'screens/sign_up_page.dart';
import 'screens/home_page.dart';
import 'screens/browse_page.dart';
import 'screens/delivery_page.dart';
import 'screens/favorite_page.dart';
import 'screens/profile_page.dart';
import 'screens/manage_account_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Check if it's the first launch
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        Provider(create: (_) => PaymentService()..initialize()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => ListingProvider()),
      ],
      child: MyApp(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    // Try to load user data when app starts
    Future.delayed(Duration.zero, () {
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    });
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grab and Go',
      home: isFirstLaunch ? const OnboardingScreen() : const gngScreen(),
      routes: {
        '/gng': (context) => const gngScreen(), // Main screen
        '/signIn': (context) => SignInPage(), // Sign In page
        '/signUp': (context) => SignUpPage(), // Sign Up page
        '/home': (context) => HomePage(), // Home page after login
        '/browse': (context) => const BrowsePage(),
        '/delivery': (context) => const DeliveryPage(),
        '/favorite': (context) => const FavoritePage(),
        '/profile': (context) => ProfilePage(),
        '/manageAccount': (context) => const ManageAccountPage(),
        '/delivery_product': (context) => const DeliveryProductPage(),
      },
    );
  }
}
