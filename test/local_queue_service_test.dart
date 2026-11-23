import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/local_queue_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('insertClientLocally adds a record to the database', () async {
    final service = LocalQueueService(inMemory: true);
    addTearDown(service.close);

    await service.insertClientLocally({
      'id': 'test-123',
      'name': 'Alice',
      'lat': 40.71,
      'lng': -74.00,
      'accuracy_m': 5.0,
      'created_at': '2024-01-01T00:00:00Z',
      'is_synced': 0,
    });

    final clients = await service.getUnsyncedClients();

    expect(clients.length, 1);
    expect(clients[0]['name'], 'Alice');
    expect(clients[0]['lat'], 40.71);
  });

  test('markClientAsSynced retire le client de la file des non synchronisés',
      () async {
    final service = LocalQueueService(inMemory: true);
    addTearDown(service.close);

    await service.insertClientLocally({
      'id': 'test-123',
      'name': 'Alice',
      'created_at': '2024-01-01T00:00:00Z',
      'is_synced': 0,
    });

    await service.markClientAsSynced('test-123');

    expect(await service.getUnsyncedClients(), isEmpty);
    final all = await service.getClients();
    expect(all.single['is_synced'], 1);
  });

  test('deleteClient supprime définitivement le client', () async {
    final service = LocalQueueService(inMemory: true);
    addTearDown(service.close);

    await service.insertClientLocally({
      'id': 'test-123',
      'name': 'Alice',
      'created_at': '2024-01-01T00:00:00Z',
      'is_synced': 0,
    });

    await service.deleteClient('test-123');

    expect(await service.getClients(), isEmpty);
  });

  test('insertClientLocally remplace un client existant (même id)', () async {
    final service = LocalQueueService(inMemory: true);
    addTearDown(service.close);

    final row = {
      'id': 'test-123',
      'name': 'Alice',
      'created_at': '2024-01-01T00:00:00Z',
      'is_synced': 0,
    };
    await service.insertClientLocally(row);
    await service.insertClientLocally({...row, 'name': 'Alicia'});

    final all = await service.getClients();
    expect(all.length, 1);
    expect(all.single['name'], 'Alicia');
  });
}
