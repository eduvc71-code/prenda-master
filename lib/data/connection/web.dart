import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor openConnection() {
  return WebDatabase('prenda_master_web_demo');
}
