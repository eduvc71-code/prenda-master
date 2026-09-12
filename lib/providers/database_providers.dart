import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prenda_master/data/app_database.dart';

// Database provider - creates a single instance of the database
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Client providers
final clientesProvider = StreamProvider<List<Cliente>>((ref) {
  final db = ref.read(databaseProvider);
  return db.watchAllClientes();
});

final clienteByIdProvider = FutureProvider.family<Cliente, int>((ref, id) {
  final db = ref.read(databaseProvider);
  return db.getCliente(id);
});

// Prestamo providers
final prestamosProvider = StreamProvider<List<Prestamo>>((ref) {
  final db = ref.read(databaseProvider);
  return db.watchAllPrestamos();
});

final prestamoByIdProvider = FutureProvider.family<Prestamo, int>((ref, id) {
  final db = ref.read(databaseProvider);
  return db.getPrestamo(id);
});

// Prenda (photo) providers
final prendasByPrestamoProvider = StreamProvider.family<List<Prenda>, int>((ref, prestamoId) {
  final db = ref.read(databaseProvider);
  return (db.select(db.prendas)..where((t) => t.prestamoId.equals(prestamoId))).watch();
});

// Pago providers
final pagosByPrestamoProvider = StreamProvider.family<List<Pago>, int>((ref, prestamoId) {
  final db = ref.read(databaseProvider);
  return (db.select(db.pagos)..where((t) => t.prestamoId.equals(prestamoId))).watch();
});

// Helper providers for form submissions
final prestamoNotifierProvider = StateNotifierProvider<PrestamoNotifier, AsyncValue<void>>((ref) {
  return PrestamoNotifier(ref.read(databaseProvider));
});

class PrestamoNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;

  PrestamoNotifier(this._db) : super(const AsyncValue.loading());

  Future<void> createPrestamo(PrestamosCompanion prestamo) async {
    state = const AsyncValue.loading();
    try {
      await _db.insertPrestamo(prestamo);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updatePrestamo(int id, PrestamosCompanion prestamo) async {
    state = const AsyncValue.loading();
    try {
      await _db.updatePrestamo(id, prestamo);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deletePrestamo(int id) async {
    state = const AsyncValue.loading();
    try {
      await _db.deletePrestamo(id);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final clienteNotifierProvider = StateNotifierProvider<ClienteNotifier, AsyncValue<void>>((ref) {
  return ClienteNotifier(ref.read(databaseProvider));
});

class ClienteNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;

  ClienteNotifier(this._db) : super(const AsyncValue.loading());

  Future<void> createCliente(ClientesCompanion cliente) async {
    state = const AsyncValue.loading();
    try {
      await _db.insertCliente(cliente);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateCliente(int id, ClientesCompanion cliente) async {
    state = const AsyncValue.loading();
    try {
      await _db.updateCliente(id, cliente);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteCliente(int id) async {
    state = const AsyncValue.loading();
    try {
      await _db.deleteCliente(id);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
