import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modelo de carta Pokémon con campos adicionales
class CartaPokemon {
  final String id; // Identificador único
  final String nombre; // Ej: "Pikachu"
  final int numero; // Ej: 25
  bool tengo; // true = Mis cartas, false = Faltantes
  final String? notas; // campo opcional

  final DateTime? fechaAgregada; // "Agregada"
  final DateTime? fechaObjetivo; // "Vencida"

  CartaPokemon({
    // constructor
    required this.id,
    required this.nombre,
    required this.numero,
    required this.tengo,
    this.notas,
    this.fechaAgregada,
    this.fechaObjetivo, // opcional
  });

  CartaPokemon copyWith({
    // para copiar y modificar
    String? id,
    String? nombre,
    int? numero,
    bool? tengo,
    String? notas,
    DateTime? fechaAgregada,
    DateTime? fechaObjetivo,
  }) {
    return CartaPokemon(
      // retorna una nueva instancia
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      numero: numero ?? this.numero,
      tengo: tengo ?? this.tengo,
      notas: notas ?? this.notas,
      fechaAgregada: fechaAgregada ?? this.fechaAgregada,
      fechaObjetivo: fechaObjetivo ?? this.fechaObjetivo,
    );
  }
}

/// Filtros solicitados por el enunciado:
/// - Todas / Pendientes / Completas
enum CartaFiltro { todas, pendientes, completas }

/// Orden por fecha objetivo (dueDate); fallback a fechaAgregada
enum SortOrder { asc, desc }

/// Formato simple dd-mm-aaaa (sin dependencias)
// 👉 Ahora con intl en español de Chile. Si quieres español genérico, usa 'es'.
String _fmt(DateTime d) {
  final formato = DateFormat('EEEE d \'de\' MMMM \'de\' y', 'es_CL');
  return formato.format(d);
}

class CartasPokemonScreen extends StatefulWidget {
  // pantalla principal de cartas Pokémon
  const CartasPokemonScreen({super.key});

  @override // crear estado que maneje la lógica
  State<CartasPokemonScreen> createState() => _CartasPokemonScreenState();
}

class _CartasPokemonScreenState extends State<CartasPokemonScreen> {
  // estado que maneja la lógica
  final _busquedaCtrl = TextEditingController();
  CartaFiltro _filtro = CartaFiltro.todas;
  SortOrder _sortOrder = SortOrder.asc;

  final List<CartaPokemon> _cartas = [
    // Precargadas
    CartaPokemon(
      id: '1',
      nombre: 'Pikachu',
      numero: 25,
      tengo: true,
      notas: 'Base Set',
      fechaAgregada: DateTime.now().subtract(
        const Duration(days: 3),
      ), // hace 3 días que se agregó
    ),
    CartaPokemon(
      id: '2',
      nombre: 'Charmander',
      numero: 4,
      tengo: false,
      fechaAgregada: DateTime.now().subtract(const Duration(days: 2)),
      fechaObjetivo: DateTime.now().add(
        const Duration(days: 2),
      ), // pendiente que aun no vence
    ),
    CartaPokemon(
      id: '3',
      nombre: 'Squirtle',
      numero: 7,
      tengo: false,
      fechaAgregada: DateTime.now().subtract(const Duration(days: 4)),
      fechaObjetivo: DateTime.now().subtract(
        const Duration(days: 1),
      ), // vencida hace 1 día
    ),
    CartaPokemon(
      id: '4',
      nombre: 'Bulbasaur',
      numero: 1,
      tengo: true,
      fechaAgregada: DateTime.now().subtract(const Duration(days: 1)),
    ),
    CartaPokemon(
      id: '5',
      nombre: 'Eevee',
      numero: 133,
      tengo: false,
      // sin fechas agregada/objetivo
    ),
  ];

  @override // liberar controlador
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  // Deriva si está vencida: no la tengo y la fechaObjetivo es anterior a hoy
  bool _estaVencida(CartaPokemon c) {
    if (c.tengo) return false;
    if (c.fechaObjetivo == null) return false;
    final hoy = DateTime.now();
    final obj = DateTime(
      c.fechaObjetivo!.year,
      c.fechaObjetivo!.month,
      c.fechaObjetivo!.day,
    );
    final t = DateTime(hoy.year, hoy.month, hoy.day);
    return obj.isBefore(t);
  }

  String _estado(CartaPokemon c) {
    // Pendiente / Completada / Vencida
    if (c.tengo) return 'Completada';
    if (_estaVencida(c)) return 'Vencida';
    return 'Pendiente';
  }

  // Búsqueda por nombre/número/notas
  bool _coincideBusqueda(CartaPokemon c) {
    final q = _busquedaCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return c.nombre.toLowerCase().contains(q) ||
        c.numero.toString().contains(q) ||
        (c.notas ?? '').toLowerCase().contains(q);
  }

  // Filtros: Todas / Pendientes / Completas
  bool _coincideFiltro(CartaPokemon c) {
    switch (_filtro) {
      case CartaFiltro.todas:
        return true; // sin filtro
      case CartaFiltro.pendientes:
        return !c.tengo; // incluye vencidas dentro de pendientes
      case CartaFiltro.completas:
        return c.tengo; // solo las que tengo
    }
  }

  // Orden: por fechaObjetivo (dueDate) cuando exista; si no, por fechaAgregada; sin fecha -> al final, por nombre
  List<CartaPokemon> get _filtradasOrdenadas {
    final base = _cartas
        .where((c) => _coincideBusqueda(c) && _coincideFiltro(c))
        .toList();

    int _cmpDate(DateTime a, DateTime b) =>
        _sortOrder == SortOrder.asc ? a.compareTo(b) : b.compareTo(a);

    base.sort((a, b) {
      final ad = a.fechaObjetivo;
      final bd = b.fechaObjetivo;

      if (ad != null && bd != null) return _cmpDate(ad, bd);
      if (ad != null && bd == null) return -1; // a primero (tiene dueDate)
      if (ad == null && bd != null) return 1; // b primero

      // Ambos sin fechaObjetivo: usar fechaAgregada si existe
      final aa = a.fechaAgregada;
      final ba = b.fechaAgregada;
      if (aa != null && ba != null) return _cmpDate(aa, ba);
      if (aa != null && ba == null) return -1;
      if (aa == null && ba != null) return 1;

      // Sin fechas: por nombre
      return a.nombre.compareTo(b.nombre);
    });

    return base;
  }

  void _toggleTengo(CartaPokemon c) {
    // marcar/desmarcar como "tengo"
    setState(() => c.tengo = !c.tengo);
  }

  void _deleteWithUndo(CartaPokemon c) {
    // eliminar con opción a deshacer
    final idx = _cartas.indexWhere((x) => x.id == c.id);
    if (idx < 0) return;

    final removed = _cartas.removeAt(idx); // eliminar
    setState(() {});

    ScaffoldMessenger.of(context).clearSnackBars(); // limpiar mensajes previos
    ScaffoldMessenger.of(context).showSnackBar(
      // mostrar SnackBar con opción a deshacer
      SnackBar(
        content: Text('Eliminada: ${removed.nombre}'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            _cartas.insert(idx, removed);
            setState(() {});
          },
        ),
      ),
    );
  }

  Future<void> _agregarCarta() async {
    // agregar nueva carta (modal bottom sheet)
    final nombreCtrl = TextEditingController();
    final numeroCtrl = TextEditingController();
    final notasCtrl = TextEditingController();
    bool tengo = false;
    DateTime? fechaObjetivo;

    await showModalBottomSheet(
      // modal bottom sheet
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctxModal, setModal) {
              Future<void> _pickDate() async {
                // costo pero se pudo, cambiarle la fecha fue todo un reto.
                final hoy = DateTime.now();
                final inicio = DateTime(hoy.year, hoy.month, hoy.day);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: inicio,
                  firstDate: inicio, // no permite pasado (regla RF)
                  lastDate: DateTime(hoy.year + 5),
                  locale: const Locale('es', 'CL'), //Español Chile porfin !!!
                  useRootNavigator: true, // español en el date picker
                );
                if (picked != null) {
                  setModal(() => fechaObjetivo = picked);
                }
              }

              return Column(
                // contenido del modal
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Agregar nueva carta',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: numeroCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Número Pokédex *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: notasCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),

                  // Tengo (checkbox)
                  Row(
                    children: [
                      Checkbox(
                        value: tengo,
                        onChanged: (v) => setModal(() => tengo = v ?? false),
                      ),
                      const Text('Ya la tengo'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Fecha objetivo (opcional)
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      fechaObjetivo == null
                          ? 'Fecha objetivo (opcional)'
                          : 'Fecha objetivo: ${_fmt(fechaObjetivo!)}',
                    ),
                  ),

                  const SizedBox(height: 8),

                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                    onPressed: () {
                      final nombre = nombreCtrl.text.trim();
                      if (nombre.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('El nombre es obligatorio'),
                          ),
                        );
                        return;
                      }
                      final numTxt = numeroCtrl.text.trim();
                      if (numTxt.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('El número es obligatorio'),
                          ),
                        );
                        return;
                      }
                      final parsed = int.tryParse(numTxt);
                      if (parsed == null || parsed <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Número inválido')),
                        );
                        return;
                      }

                      final nueva = CartaPokemon(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        nombre: nombre,
                        numero: parsed,
                        tengo: tengo,
                        notas: notasCtrl.text.trim().isEmpty
                            ? null
                            : notasCtrl.text.trim(),
                        fechaAgregada: DateTime.now(), // para tu orden/visual
                        fechaObjetivo: fechaObjetivo, // dueDate opcional
                      );

                      Navigator.pop(ctx, nueva);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    ).then((value) {
      if (value is CartaPokemon) {
        setState(() => _cartas.add(value));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Agregada: ${value.nombre}')));
      }
    });
  }

  @override // construir la interfaz de usuario
  Widget build(BuildContext context) {
    final lista = _filtradasOrdenadas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi colección de cartas'),
        centerTitle: true,
        backgroundColor: Colors.amber.shade600,
        actions: [
          // Alternar orden (asc/desc) por fechaObjetivo (fallback fechaAgregada)
          IconButton(
            tooltip: _sortOrder == SortOrder.asc
                ? 'Orden por fecha: Ascendente'
                : 'Orden por fecha: Descendente',
            onPressed: () => setState(() {
              _sortOrder = _sortOrder == SortOrder.asc
                  ? SortOrder.desc
                  : SortOrder.asc;
            }),
            icon: Icon(
              _sortOrder == SortOrder.asc
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarCarta,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: Container(
        color: Colors.amber.shade100,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Buscador
                    TextField(
                      controller: _busquedaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Buscar carta (nombre, número o notas)',
                        prefixIcon: Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Filtros renombrados: Todas / Pendientes / Completas
                    SegmentedButton<CartaFiltro>(
                      segments: const [
                        ButtonSegment(
                          value: CartaFiltro.todas,
                          label: Text('Todas'),
                        ),
                        ButtonSegment(
                          value: CartaFiltro.pendientes,
                          label: Text('Pendientes'),
                        ),
                        ButtonSegment(
                          value: CartaFiltro.completas,
                          label: Text('Completas'),
                        ),
                      ],
                      selected: <CartaFiltro>{_filtro},
                      onSelectionChanged: (sel) =>
                          setState(() => _filtro = sel.first),
                    ),
                    const SizedBox(height: 16),

                    // Lista
                    if (lista.isEmpty)
                      const _EmptyState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lista.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final c = lista[index];
                          final estado = _estado(c);
                          final esVencida = estado == 'Vencida';

                          return Dismissible(
                            key: ValueKey(c.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              color: Colors.red.shade300,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => _deleteWithUndo(c),
                            child: Card(
                              elevation: 1,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: Checkbox(
                                  value: c.tengo,
                                  onChanged: (_) => _toggleTengo(c),
                                ),
                                title: Text(
                                  '${c.nombre} (#${c.numero})',
                                  // Estilo "completada" (tachado) si la tengo
                                  style: c.tengo
                                      ? const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        )
                                      : const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((c.notas ?? '').trim().isNotEmpty)
                                      Text(c.notas!.trim()),
                                    if (c.fechaAgregada != null)
                                      Text(
                                        'Agregada: ${_fmt(c.fechaAgregada!)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    if (c.fechaObjetivo != null)
                                      Text(
                                        'Fecha objetivo: ${_fmt(c.fechaObjetivo!)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    Text(
                                      estado, // Pendiente / Completada / Vencida
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: esVencida
                                                ? Colors.red.shade700
                                                : Colors.black54,
                                            fontWeight: esVencida
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                                onTap: () => _toggleTengo(c),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  // estado vacío
  // widget para mostrar cuando la lista está vacía
  const _EmptyState();

  @override // construir la interfaz de usuario
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.collections, size: 48, color: Colors.black54),
            const SizedBox(height: 8),
            Text(
              'Tu colección aparecerá aquí',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text('Agrega cartas.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
