import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/auction_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://luooikdggmiwbgdzoubv.supabase.co',
    anonKey: 'sb_publishable_5EPrVD9AJ78Wgc0Mqp-XHw_y9YtLsX-',
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
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => AuctionProvider()),
      ],
      child: MaterialApp(
        title: 'Unideal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        home: SplashScreen(),
      ),
    );
  }
}
