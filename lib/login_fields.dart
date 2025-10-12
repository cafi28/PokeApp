import 'package:flutter/material.dart';
import 'package:flutter_application_1/pokemon_screen.dart'; // pantalla principal

class LoginFields extends StatefulWidget {
  const LoginFields({super.key}); // constructor de estado completo

  @override // crear estado que maneje el formulario
  State<LoginFields> createState() => _LoginFieldsState();
}

class _LoginFieldsState extends State<LoginFields> {
  // estado del formulario que maneja validación, controladores, etc.
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override // limpiar controladores al eliminar el widget
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validarCorreo(String? valor) {
    // validación del correo
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Ingrese un correo';
    if (!v.contains('@')) return 'Correo inválido (debe incluir "@")';
    if (!v.contains('.')) return 'Correo inválido (debe incluir ".")';
    if (v.length < 5) return 'Correo demasiado corto';
    return null;
  }

  String? _validarClave(String? valor) {
    // validación de la contraseña
    final v = valor ?? '';
    if (v.isEmpty) return 'Ingrese una contraseña';
    if (v.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    return null;
  }

  Future<void> _submit() async {
    // enviar formulario
    FocusScope.of(context).unfocus();
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    try {
      // simular proceso de inicio de sesión
      setState(() {
        _loading = true;
        _error = null;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return; // verificar si el widget sigue en el árbol
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaBienvenida(correo: _emailCtrl.text.trim()),
        ),
      );
    } catch (e) {
      // aca se pueden manejar errores inesperados
      setState(() => _error = 'Ocurrió un problema. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override // construye la interfaz de usuario del formulario
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _EncabezadoPokemon(),
            const SizedBox(height: 16),

            Text(
              "Colección de Cartas Pokémon",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Campo correo
            TextFormField(
              enabled: !_loading,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: "Correo electrónico",
                hintText: "usuario@ejemplo.com",
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: _validarCorreo,
            ),
            const SizedBox(height: 12),

            // Campo contraseña
            TextFormField(
              enabled: !_loading,
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: "Contraseña",
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: _validarClave,
            ),
            const SizedBox(height: 16),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // Botón ingresar
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: const Text('Ingresar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Encabezado con imagen Pikachu
class _EncabezadoPokemon extends StatelessWidget {
  const _EncabezadoPokemon();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.network(
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png',
          semanticLabel: 'Logo de Pokémon',
          height: 110,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

// --- Pantalla de Bienvenida con Pikachu corriendo ---
class PantallaBienvenida extends StatefulWidget {
  final String correo;
  const PantallaBienvenida({super.key, required this.correo});

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _haciaDerecha = true; // dirección del Pikachu

  @override
  void initState() {
    super.initState();

    _ctrl =
        AnimationController(
            vsync: this,
            duration: const Duration(seconds: 2),
          ) // control de animación
          ..addStatusListener((status) {
            if (status == AnimationStatus.forward) {
              setState(() => _haciaDerecha = true);
            } else if (status == AnimationStatus.reverse) {
              setState(() => _haciaDerecha = false);
            }
          })
          ..repeat(reverse: true);

    // Auto-redirección a la pantalla principal (4 segundos) Esto es fue muy divertido manejarlo, por que desde que inicie este proyecto
    // siempre imagine un Pikachu corriendo para iniciar sesión, con esto da gusto ahora esperar ajajajajja, es bacan!
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CartasPokemonScreen()),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override // construir la interfaz de usuario
  Widget build(BuildContext context) {
    const pikachuGif =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-v/black-white/animated/25.gif';

    return Scaffold(
      // pantalla de bienvenida
      appBar: AppBar(
        title: const Text('Bienvenida'),
        centerTitle: true,
        backgroundColor: Colors.amber.shade600,
      ),
      body: Container(
        color: Colors.amber.shade100,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bienvenido ${widget.correo}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entrando a tu colección...',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Detalles de Pikachu corriendo
                SizedBox(
                  height: 120,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final ancho = constraints.maxWidth;
                      const spriteWidth = 72.0;
                      return AnimatedBuilder(
                        animation: _ctrl,
                        builder: (_, __) {
                          final dx = (ancho - spriteWidth) * _ctrl.value;
                          return Stack(
                            children: [
                              Positioned(
                                left: dx,
                                top: 12,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..scale(_haciaDerecha ? 1.0 : -1.0, 1.0),
                                  child: Image.network(
                                    pikachuGif,
                                    width: spriteWidth,
                                    height: 72,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(
                                          width: spriteWidth,
                                          height: 72,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
