import 'dart:async'; // TimeoutException, Future
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'data/carta_service.dart';

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
    required this.id,
    required this.nombre,
    required this.numero,
    required this.tengo,
    this.notas,
    this.fechaAgregada,
    this.fechaObjetivo,
  });

  CartaPokemon copyWith({
    String? id,
    String? nombre,
    int? numero,
    bool? tengo,
    String? notas,
    DateTime? fechaAgregada,
    DateTime? fechaObjetivo,
  }) {
    return CartaPokemon(
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

/// Filtros: Todas / Pendientes / Completas
enum CartaFiltro { todas, pendientes, completas }

/// Orden por fecha objetivo (dueDate) o agregada
enum SortOrder { asc, desc }

/// Fechas en español (Chile)
String _fmt(DateTime d) {
  final formato = DateFormat('EEEE d \'de\' MMMM \'de\' y', 'es_CL');
  return formato.format(d);
}

class CartasPokemonScreen extends StatefulWidget {
  const CartasPokemonScreen({super.key});

  @override
  State<CartasPokemonScreen> createState() => _CartasPokemonScreenState();
}

class _CartasPokemonScreenState extends State<CartasPokemonScreen> {
  final _busquedaCtrl = TextEditingController();
  CartaFiltro _filtro = CartaFiltro.todas;
  SortOrder _sortOrder = SortOrder.asc;

  // 🔹 Semillas para no ver vacío mientras sincroniza
  final List<CartaPokemon> _seedCartas = [
    CartaPokemon(
      id: 'seed-1',
      nombre: 'Pikachu',
      numero: 25,
      tengo: true,
      notas: 'Base Set',
      fechaAgregada: DateTime.now().subtract(const Duration(days: 3)),
    ),
    CartaPokemon(
      id: 'seed-2',
      nombre: 'Charmander',
      numero: 4,
      tengo: false,
      fechaAgregada: DateTime.now().subtract(const Duration(days: 2)),
      fechaObjetivo: DateTime.now().add(const Duration(days: 2)),
    ),
    CartaPokemon(
      id: 'seed-3',
      nombre: 'Squirtle',
      numero: 7,
      tengo: false,
      fechaAgregada: DateTime.now().subtract(const Duration(days: 4)),
      fechaObjetivo: DateTime.now().subtract(const Duration(days: 1)),
    ),
    CartaPokemon(
      id: 'seed-4',
      nombre: 'Bulbasaur',
      numero: 1,
      tengo: true,
      fechaAgregada: DateTime.now().subtract(const Duration(days: 1)),
    ),
    CartaPokemon(id: 'seed-5', nombre: 'Eevee', numero: 133, tengo: false),
  ];

  // Estado
  List<CartaPokemon> _cartas = [];
  bool _sincronizando = false;

  @override
  void initState() {
    super.initState();
    // Muestra algo de inmediato y sincroniza en background
    _cartas = List.of(_seedCartas);
    _cargarCartas();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarCartas() async {
    setState(() => _sincronizando = true);
    try {
      final cartasBD = await CartaService.getCartas().timeout(
        const Duration(seconds: 6),
      );

      // Si Firestore tiene datos, reemplaza las semillas
      if (cartasBD.isNotEmpty) {
        setState(() => _cartas = cartasBD);
      } else {
        // Si está vacío, mantenemos semillas (mejor UX para demo)
        setState(() => _cartas = List.of(_seedCartas));
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización lenta. Mostrando datos locales.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar cartas: $e')));
      }
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  // Deriva si está vencida: no la tengo y dueDate es anterior a hoy
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

  // Filtros
  bool _coincideFiltro(CartaPokemon c) {
    switch (_filtro) {
      case CartaFiltro.todas:
        return true;
      case CartaFiltro.pendientes:
        return !c.tengo;
      case CartaFiltro.completas:
        return c.tengo;
    }
  }

  // Orden: dueDate > fechaAgregada > nombre
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
      if (ad != null && bd == null) return -1;
      if (ad == null && bd != null) return 1;

      final aa = a.fechaAgregada;
      final ba = b.fechaAgregada;
      if (aa != null && ba != null) return _cmpDate(aa, ba);
      if (aa != null && ba == null) return -1;
      if (aa == null && ba != null) return 1;

      return a.nombre.compareTo(b.nombre);
    });

    return base;
  }

  void _toggleTengo(CartaPokemon c) {
    setState(() => c.tengo = !c.tengo);
  }

  void _deleteWithUndo(CartaPokemon c) {
    final idx = _cartas.indexWhere((x) => x.id == c.id);
    if (idx < 0) return;

    final removed = _cartas.removeAt(idx);
    setState(() {});

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
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
    final nombreCtrl = TextEditingController();
    final numeroCtrl = TextEditingController();
    final notasCtrl = TextEditingController();
    bool tengo = false;
    DateTime? fechaObjetivo;

    final value = await showModalBottomSheet<CartaPokemon?>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        bool sending = false;

        void safeSnack(String msg) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctxModal, setModal) {
              Future<void> _pickDate() async {
                final hoy = DateTime.now();
                final inicio = DateTime(hoy.year, hoy.month, hoy.day);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: inicio,
                  firstDate: inicio,
                  lastDate: DateTime(hoy.year + 5),
                  locale: const Locale('es', 'CL'),
                  useRootNavigator: true,
                );
                if (picked != null) setModal(() => fechaObjetivo = picked);
              }

              Future<void> _onSubmit() async {
                final nombre = nombreCtrl.text.trim();
                final numTxt = numeroCtrl.text.trim();
                if (nombre.isEmpty) {
                  safeSnack('El nombre es obligatorio');
                  return;
                }
                if (numTxt.isEmpty) {
                  safeSnack('El número es obligatorio');
                  return;
                }
                final parsed = int.tryParse(numTxt);
                if (parsed == null || parsed <= 0) {
                  safeSnack('Número inválido');
                  return;
                }

                setModal(() => sending = true);

                final nueva = CartaPokemon(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  nombre: nombre,
                  numero: parsed,
                  tengo: tengo,
                  notas: notasCtrl.text.trim().isEmpty
                      ? null
                      : notasCtrl.text.trim(),
                  fechaAgregada: DateTime.now(),
                  fechaObjetivo: fechaObjetivo,
                );

                try {
                  await CartaService.addCarta(
                    nueva,
                  ).timeout(const Duration(seconds: 6));
                } on TimeoutException {
                  safeSnack(
                    'La red está lenta. Guardaremos cuando haya conexión.',
                  );
                } catch (e) {
                  safeSnack('Error guardando en la nube: $e');
                } finally {
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop(nueva);
                  }
                }
              }

              return Column(
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

                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      icon: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: Text(sending ? 'Guardando...' : 'Agregar'),
                      onPressed: sending ? null : _onSubmit,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );

    if (value is CartaPokemon) {
      setState(() => _cartas.add(value));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Agregada: ${value.nombre}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtradasOrdenadas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi colección de cartas'),
        centerTitle: true,
        backgroundColor: Colors.amber.shade600,
        actions: [
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
        // 🔹 Barrita de sincronización
        bottom: _sincronizando
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarCarta,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: Container(
        color: Colors.amber.shade100,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _cargarCartas, // pull-to-refresh
            child: Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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

                      // Filtros: Todas / Pendientes / Completas
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
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
