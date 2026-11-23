import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/widgets/client_card.dart';

void main() {
  testWidgets('affiche la position quand elle est disponible', (tester) async {
    final client = Client(
      id: '1',
      name: 'Sam',
      createdAt: DateTime.utc(2026, 1, 1),
      lat: 51.5074,
      lng: -0.1278,
      isSynced: true,
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ClientCard(client: client))),
    );

    expect(find.text('Sam'), findsOneWidget);
    expect(find.textContaining('51.5074'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
  });

  testWidgets('affiche « Location not captured » sans position',
      (tester) async {
    final client = Client(
      id: '1',
      name: 'Sam',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ClientCard(client: client))),
    );

    expect(find.textContaining('Location not captured'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
  });
}
