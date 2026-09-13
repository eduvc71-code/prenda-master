import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:prenda_master/core/constants/app_constants.dart';
part 'app_database.g.dart';

// Part 1: Define the database tables

class Clientes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().withLength(min: 1, max: 100)();
  TextColumn get apellido => text().withLength(min: 1, max: 100)();
  TextColumn get cedula => text().withLength(min: 0, max: 50)();
  TextColumn get telefono => text().withLength(min: 1, max: 20)();
  TextColumn get email => text().withLength(min: 0, max: 100)();
  TextColumn get direccion => text().withLength(min: 0, max: 200)();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

class Prendas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get descripcion => text().withLength(min: 1, max: 200)();
  TextColumn get fotoPath => text().withLength(min: 0, max: 500)(); // nullable
  IntColumn get prestamoId => integer().references(Prestamos, #id)();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

class Prestamos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get clienteId => integer().references(Clientes, #id)();
  RealColumn get monto => real()();
  TextColumn get moneda => text().withLength(min: 1, max: 10)();
  RealColumn get interesMensual => real()();
  IntColumn get plazoDias => integer()();
  DateTimeColumn get fechaInicio => dateTime()();
  DateTimeColumn get fechaVencimiento => dateTime()();
  TextColumn get estado => text().withLength(min: 1, max: 20)();
  TextColumn get descripcion => text().withLength(min: 0, max: 500)();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

class Pagos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get prestamoId => integer().references(Prestamos, #id)();
  RealColumn get monto => real()();
  RealColumn get capitalPagado => real().withDefault(const Constant(0.0))();
  RealColumn get interesPagado => real().withDefault(const Constant(0.0))();
  DateTimeColumn get fechaPago => dateTime()();
  TextColumn get metodo => text().withLength(min: 1, max: 50)();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

// Part 2: The database itself

@DriftDatabase(tables: [Clientes, Prendas, Prestamos, Pagos])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Seed sample initial data with diverse loan states (>61 days moroso, 75-90 days recuperacion, >90 days remate)
          final c1 = await into(clientes).insert(ClientesCompanion.insert(
            nombre: 'Juan',
            apellido: 'Pérez',
            cedula: '3455652',
            telefono: '70123456',
            email: 'juan.perez@email.com',
            direccion: 'Santa Rosa del Yacuma',
          ));
          final c2 = await into(clientes).insert(ClientesCompanion.insert(
            nombre: 'María',
            apellido: 'García',
            cedula: '4567891',
            telefono: '71234567',
            email: 'maria.garcia@email.com',
            direccion: 'La Paz',
          ));
          final c3 = await into(clientes).insert(ClientesCompanion.insert(
            nombre: 'Carlos',
            apellido: 'López',
            cedula: '5678912',
            telefono: '72345678',
            email: 'carlos.lopez@email.com',
            direccion: 'Cochabamba',
          ));
          final c4 = await into(clientes).insert(ClientesCompanion.insert(
            nombre: 'Ana',
            apellido: 'Martínez',
            cedula: '6789123',
            telefono: '73456789',
            email: 'ana.martinez@email.com',
            direccion: 'Santa Cruz',
          ));
          final c5 = await into(clientes).insert(ClientesCompanion.insert(
            nombre: 'Pedro',
            apellido: 'Sánchez',
            cedula: '7891234',
            telefono: '74567890',
            email: 'pedro.sanchez@email.com',
            direccion: 'Oruro',
          ));

          final p1 = await into(prestamos).insert(PrestamosCompanion.insert(
            clienteId: c1,
            monto: 1500.0,
            moneda: 'Bs.',
            interesMensual: 3.0,
            plazoDias: 30,
            fechaInicio: DateTime.now().subtract(const Duration(days: 15)),
            fechaVencimiento: DateTime.now().add(const Duration(days: 15)),
            estado: 'Activo',
            descripcion: '[Joyas (Oro/Plata)] Anillo de oro 18k',
          ));
          
          // María García: 65 days overdue -> Moroso Crítico (>61 días)
          await into(prestamos).insert(PrestamosCompanion.insert(
            clienteId: c2,
            monto: 800.0,
            moneda: 'Bs.',
            interesMensual: 3.0,
            plazoDias: 30,
            fechaInicio: DateTime.now().subtract(const Duration(days: 95)),
            fechaVencimiento: DateTime.now().subtract(const Duration(days: 65)),
            estado: 'Vencido',
            descripcion: '[Electrónica / Celulares] Smartphone Samsung Galaxy',
          ));

          // Carlos López: 82 days overdue -> Ventana de Recuperación (75-90 días)
          await into(prestamos).insert(PrestamosCompanion.insert(
            clienteId: c3,
            monto: 2400.0,
            moneda: 'Bs.',
            interesMensual: 3.0,
            plazoDias: 30,
            fechaInicio: DateTime.now().subtract(const Duration(days: 112)),
            fechaVencimiento: DateTime.now().subtract(const Duration(days: 82)),
            estado: 'Vencido',
            descripcion: '[Relojes] Reloj Rolex Submariner',
          ));

          final p4 = await into(prestamos).insert(PrestamosCompanion.insert(
            clienteId: c4,
            monto: 500.0,
            moneda: 'Bs.',
            interesMensual: 3.0,
            plazoDias: 30,
            fechaInicio: DateTime.now().subtract(const Duration(days: 40)),
            fechaVencimiento: DateTime.now().subtract(const Duration(days: 10)),
            estado: 'Pagado',
            descripcion: '[Herramientas] Taladro Bosch profesional',
          ));

          // Pedro Sánchez: 95 days overdue -> Prenda Lista para Remate (>90 días)
          await into(prestamos).insert(PrestamosCompanion.insert(
            clienteId: c5,
            monto: 3000.0,
            moneda: 'Bs.',
            interesMensual: 3.0,
            plazoDias: 30,
            fechaInicio: DateTime.now().subtract(const Duration(days: 125)),
            fechaVencimiento: DateTime.now().subtract(const Duration(days: 95)),
            estado: 'Vencido',
            descripcion: '[Electrodomésticos] Televisor LG 55 pulgadas',
          ));

          // Seed sample payments
          await into(pagos).insert(PagosCompanion.insert(
            prestamoId: p4,
            monto: 500.0,
            capitalPagado: const Value(500.0),
            interesPagado: const Value(15.0),
            fechaPago: DateTime.now().subtract(const Duration(days: 12)),
            metodo: 'Efectivo',
          ));
          await into(pagos).insert(PagosCompanion.insert(
            prestamoId: p1,
            monto: 45.0,
            capitalPagado: const Value(0.0),
            interesPagado: const Value(45.0),
            fechaPago: DateTime.now().subtract(const Duration(days: 5)),
            metodo: 'Transferencia',
          ));
        },
      );

  // Helper methods for CRUD operations (clients)
  Future<List<Cliente>> getAllClientes() => select(clientes).get();
  Stream<List<Cliente>> watchAllClientes() => select(clientes).watch();
  Future<Cliente> getCliente(int id) => (select(clientes)..where((c) => c.id.equals(id))).getSingle();
  Future<int> insertCliente(ClientesCompanion cliente) => into(clientes).insert(cliente);
  Future<int> updateCliente(int id, ClientesCompanion cliente) =>
      (update(clientes)..where((c) => c.id.equals(id))).write(cliente);
  Future<int> deleteCliente(int id) => (delete(clientes)..where((c) => c.id.equals(id))).go();

  // Helper methods for prestamos
  Future<List<Prestamo>> getAllPrestamos() => select(prestamos).get();
  Stream<List<Prestamo>> watchAllPrestamos() => select(prestamos).watch();
  Future<Prestamo> getPrestamo(int id) => (select(prestamos)..where((p) => p.id.equals(id))).getSingle();
  Future<int> insertPrestamo(PrestamosCompanion prestamo) => into(prestamos).insert(prestamo);
  Future<int> updatePrestamo(int id, PrestamosCompanion prestamo) =>
      (update(prestamos)..where((p) => p.id.equals(id))).write(prestamo);
  Future<int> deletePrestamo(int id) => (delete(prestamos)..where((p) => p.id.equals(id))).go();

  // Helper methods for prendas (photos)
  Future<List<Prenda>> getPrendasByPrestamo(int prestamoId) =>
      (select(prendas)..where((p) => p.prestamoId.equals(prestamoId))).get();
  Future<int> insertPrenda(PrendasCompanion prenda) => into(prendas).insert(prenda);
  Future<int> deletePrenda(int id) => (delete(prendas)..where((p) => p.id.equals(id))).go();

  // Helper methods for prestamos by cliente
  Future<List<Prestamo>> getPrestamosByClienteId(int clienteId) =>
      (select(prestamos)..where((p) => p.clienteId.equals(clienteId))).get();

  // Helper methods for pagos
  Future<List<Pago>> getPagosByPrestamo(int prestamoId) =>
      (select(pagos)..where((p) => p.prestamoId.equals(prestamoId))).get();
  Future<List<Pago>> getAllPagos() => select(pagos).get();
  Stream<List<Pago>> watchAllPagos() => select(pagos).watch();
  Future<int> insertPago(PagosCompanion pago) => into(pagos).insert(pago);

  // Clear / Vaciar Base de Datos
  Future<void> clearAllTables() async {
    await transaction(() async {
      await delete(pagos).go();
      await delete(prendas).go();
      await delete(prestamos).go();
      await delete(clientes).go();
    });
  }
}

// Part 3: Open the database (native for mobile, lazy)
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, '${AppConstants.dbName}'));
    return NativeDatabase.createInBackground(file);
  });
}
