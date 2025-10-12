import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_application_1/login_screen.dart';

/// Punto de entrada: inicializa formatos de fecha en español (Chile)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CL'); // nombres de meses/días en español
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  // Widget raíz de la aplicación
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Título y tema (mantiene tu look ámbar)
      title: 'Cartas Pokémon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.amber,
        brightness: Brightness.light,
        fontFamily: 'Arial',
      ),

      locale: const Locale('es', 'CL'), // idioma por defecto español

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [Locale('es', 'CL'), Locale('es'), Locale('en')],

      // Pantalla inicial (tu login)
      home: const LoginScreen(),
    );
  }
}
