import 'package:flutter/material.dart';
import 'package:flutter_application_1/login_fields.dart';

class LoginScreen extends StatelessWidget {
  // pantalla de inicio de sesión
  const LoginScreen({super.key}); // constructor

  @override
  Widget build(BuildContext context) {
    // construir la interfaz de usuario
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenador · Inicio de sesión'),
        centerTitle: true,
        backgroundColor: Colors.amber.shade600,
      ),
      body: Container(
        color: Colors.amber.shade100, // fondo amarillo pálido
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const LoginFields(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
