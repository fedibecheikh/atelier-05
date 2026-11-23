import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/models/client.dart';

void main() {
  test('toLocalMap conserve is_synced et toRemoteMap l\'exclut', () {
    final client = Client(
      id: '1',
      name: 'Alice',
      createdAt: DateTime.utc(2026, 1, 1),
      lat: 36.8065,
      lng: 10.1815,
      accuracy: 3.5,
    );

    final local = client.toLocalMap();
    final remote = client.toRemoteMap();

    expect(local['is_synced'], 0);
    expect(local['accuracy_m'], 3.5);
    expect(remote.containsKey('is_synced'), isFalse);
    expect(remote['location_accuracy_m'], 3.5);
  });

  test('fromLocalMap restaure les champs et le statut de synchro', () {
    final client = Client.fromLocalMap({
      'id': '1',
      'name': 'Alice',
      'lat': 36.8065,
      'lng': 10.1815,
      'accuracy_m': 3.5,
      'created_at': '2026-01-01T00:00:00.000Z',
      'is_synced': 1,
    });

    expect(client.hasLocation, isTrue);
    expect(client.isSynced, isTrue);
    expect(client.locationText, '36.8065, 10.1815');
  });
}
