import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/geolocation_service.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/models/location_sample.dart';
import 'package:waiting_room_app/queue_provider.dart';

class FakeGeolocationService extends GeolocationService {
  FakeGeolocationService({this.sample});

  final LocationSample? sample;
  int calls = 0;

  @override
  Future<LocationSample?> getCurrentLocation() async {
    calls++;
    return sample;
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('addClient sauvegarde le client avec sa géolocalisation', () async {
    final storage = LocalQueueService(inMemory: true);
    final geolocation = FakeGeolocationService(
      sample: const LocationSample(
        latitude: 36.8065,
        longitude: 10.1815,
        accuracy: 5.5,
      ),
    );
    final provider = QueueProvider(
      localDb: storage,
      geoService: geolocation,
      isDemo: true,
    );
    addTearDown(() async {
      provider.dispose();
      await storage.close();
    });

    await provider.initialize();
    await provider.addClient('Alice');

    expect(geolocation.calls, 1);
    expect(provider.clients.single.name, 'Alice');
    expect(provider.clients.single.lat, 36.8065);
    expect(provider.clients.single.lng, 10.1815);
    expect(provider.clients.single.isSynced, isFalse);

    final rows = await storage.getClients();
    expect(rows.single['is_synced'], 0);
  });

  test('addClient fonctionne même si la géolocalisation est refusée',
      () async {
    final storage = LocalQueueService(inMemory: true);
    final provider = QueueProvider(
      localDb: storage,
      geoService: FakeGeolocationService(),
      isDemo: true,
    );
    addTearDown(() async {
      provider.dispose();
      await storage.close();
    });

    await provider.initialize();
    await provider.addClient('Bob');

    expect(provider.clients.single.name, 'Bob');
    expect(provider.clients.single.hasLocation, isFalse);
    expect(provider.clients.single.locationText, 'Location not captured');
  });

  test('nextClient retire le premier client local', () async {
    final storage = LocalQueueService(inMemory: true);
    final provider = QueueProvider(
      localDb: storage,
      geoService: FakeGeolocationService(),
      isDemo: true,
    );
    addTearDown(() async {
      provider.dispose();
      await storage.close();
    });

    await provider.initialize();
    await provider.addClient('Alice');
    await provider.addClient('Bob');
    await provider.nextClient();

    expect(provider.clients.single.name, 'Bob');
    expect((await storage.getClients()).length, 1);
  });

  test('initialize charge les clients déjà présents en base locale', () async {
    final storage = LocalQueueService(inMemory: true);
    await storage.insertClientLocally({
      'id': 'existing-1',
      'name': 'Charlie',
      'created_at': '2024-01-01T00:00:00Z',
      'is_synced': 1,
    });

    final provider = QueueProvider(
      localDb: storage,
      geoService: FakeGeolocationService(),
      isDemo: true,
    );
    addTearDown(() async {
      provider.dispose();
      await storage.close();
    });

    await provider.initialize();

    expect(provider.isLoading, isFalse);
    expect(provider.clients.single.name, 'Charlie');
    expect(provider.clients.single.isSynced, isTrue);
  });
}
