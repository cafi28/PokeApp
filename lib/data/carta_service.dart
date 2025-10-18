import 'package:cloud_firestore/cloud_firestore.dart';
import '../pokemon_screen.dart' show CartaPokemon;

class CartaService {
  static final _col = FirebaseFirestore.instance.collection('cartas');

  /// Crea una carta en Firestore
  static Future<String> addCarta(CartaPokemon c) async {
    final data = {
      'nombre': c.nombre,
      'numero': c.numero,
      'tengo': c.tengo,
      'notas': c.notas,
      'fechaAgregada': c.fechaAgregada != null
          ? Timestamp.fromDate(c.fechaAgregada!)
          : null,
      'fechaObjetivo': c.fechaObjetivo != null
          ? Timestamp.fromDate(c.fechaObjetivo!)
          : null,
      'createdAt': Timestamp.now(),
    };
    final doc = await _col.add(data);
    return doc.id;
  }

  /// Obtiene cartas desde Firestore (ordenadas por creación)
  static Future<List<CartaPokemon>> getCartas() async {
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return CartaPokemon(
        id: doc.id,
        nombre: d['nombre'] ?? 'Desconocido',
        numero: (d['numero'] ?? 0) is int
            ? d['numero']
            : int.tryParse('${d['numero']}') ?? 0,
        tengo: d['tengo'] ?? false,
        notas: d['notas'],
        fechaAgregada: d['fechaAgregada'] is Timestamp
            ? (d['fechaAgregada'] as Timestamp).toDate()
            : null,
        fechaObjetivo: d['fechaObjetivo'] is Timestamp
            ? (d['fechaObjetivo'] as Timestamp).toDate()
            : null,
      );
    }).toList();
  }
}
