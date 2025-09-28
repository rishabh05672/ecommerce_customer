import 'package:ecommerce_customer/provider/auth_provider.dart';
import 'package:ecommerce_customer/provider/cart_provider.dart';
import 'package:ecommerce_customer/provider/favorite_provider.dart';
import 'package:ecommerce_customer/provider/product_provider.dart';
import 'package:ecommerce_customer/screens/home_screen.dart';
import 'package:ecommerce_customer/screens/login_screen.dart';
import 'package:ecommerce_customer/screens/signup_screen.dart';
import 'package:ecommerce_customer/screens/splash_screen.dart';
import 'package:ecommerce_customer/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: MaterialApp(
        title: 'Ecommerce Shop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: SplashScreen(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/signup': (context) => SignupScreen(),
        },
      ),
    );
  }
}
