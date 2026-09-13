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
  TextColumn get descripcion => text().withLength(min: 0, max: 500)(); // Agregado
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

class Pagos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get prestamoId => integer().references(Prestamos, #id)();
  RealColumn get monto => real()();
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
  Future<int> insertPago(PagosCompanion pago) => into(pagos).insert(pago);
}

// Part 3: Open the database (native for mobile, lazy)
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, '${AppConstants.dbName}'));
    return NativeDatabase.createInBackground(file);
  });
}