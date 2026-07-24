import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'services/printer_service.dart';
import 'screens/home_screen.dart';

/// Change once per deployment if Cheers Hotel ever runs multiple branches.
const String kRestaurantId = 'cheers-hotel-main';
const String kRestaurantName = 'Cheers Hotel';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CheersHotelApp());
}

class CheersHotelApp extends StatelessWidget {
  const CheersHotelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirestoreService>(
          create: (_) => FirestoreService(restaurantId: kRestaurantId),
        ),
        Provider<PrinterService>(
          create: (_) => PrinterService(),
        ),
      ],
      child: MaterialApp(
        title: 'Cheers Hotel — Sales & Records',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF8B1E2B),
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
