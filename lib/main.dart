import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_bestell_fix/screens/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Hive
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
        colorScheme:  ColorScheme.fromSeed(seedColor: Colors.grey.shade200,),
      ),
      home: HomePage(),
    );
  }
}