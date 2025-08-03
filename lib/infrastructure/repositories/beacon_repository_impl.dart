import 'package:sembast/sembast.dart';
import '../database/app_database.dart';
import '../../domain/repositories/beacon_repository.dart';

/// Implementación del repositorio de Beacon utilizando Sembast para persistencia
class BeaconRepositoryImpl implements BeaconRepository {
  static final StoreRef<String, Map<String, dynamic>> _store =
      stringMapStoreFactory.store('settings');
  static const String _recordKey = 'beacon_id';
  static const String _fingerprintKey = 'beacon_fingerprint';

  @override
  Future<void> saveBeaconId(String id) async {
    final db = await AppDatabase.instance.database;
    await _store.record(_recordKey).put(db, {'value': id});
  }

  @override
  Future<String?> loadBeaconId() async {
    final db = await AppDatabase.instance.database;
    final record = await _store.record(_recordKey).get(db);
    return record == null ? null : record['value'] as String?;
  }

  @override
  Future<void> saveBeaconFingerprint(Map<String, dynamic> fingerprint) async {
    final db = await AppDatabase.instance.database;
    await _store.record(_fingerprintKey).put(db, fingerprint);
  }

  @override
  Future<Map<String, dynamic>?> loadBeaconFingerprint() async {
    final db = await AppDatabase.instance.database;
    final record = await _store.record(_fingerprintKey).get(db);
    return record == null ? null : Map<String, dynamic>.from(record);
  }
}
