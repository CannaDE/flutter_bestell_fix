import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:time_monitoring/screens/home_page.dart';
import 'package:time_monitoring/services/update_service.dart';

// UpdateService initialisieren
final updater = UpdateService("CannaDE", "flutter_bestell_fix");

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive initialisieren
  await Hive.initFlutter();
  await Hive.openBox('ordersBox');

  runApp(const BestellFixApp());
}

class BestellFixApp extends StatelessWidget {
  const BestellFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BestellFix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey.shade200,
        ),
      ),
      home: const HomeWithUpdateCheck(),
    );
  }
}

/// Wrapper um HomePage, um UpdateCheck beim Start auszuführen
class HomeWithUpdateCheck extends StatefulWidget {
  const HomeWithUpdateCheck({super.key});

  @override
  State<HomeWithUpdateCheck> createState() => _HomeWithUpdateCheckState();
}

class _HomeWithUpdateCheckState extends State<HomeWithUpdateCheck> {
  @override
  void initState() {
    super.initState();

    // Updateprüfung nach Frame-Render starten
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await updater.checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
