# Atelier 5 — Offline-first, SQLite et géolocalisation

## Réalisation

L'application fonctionne sans réseau : chaque inscription est d'abord écrite dans
SQLite, puis synchronisée vers Supabase dès que possible.

### Persistance locale (`lib/local_queue_service.dart`)

- Table `local_clients` : `id`, `name`, `lat`, `lng`, `accuracy_m`, `created_at`, `is_synced`.
- `insertClientLocally`, `getClients`, `getUnsyncedClients`, `markClientAsSynced`, `deleteClient`.
- Mode `inMemory: true` pour des tests rapides et isolés.

### Synchronisation (`lib/queue_provider.dart`)

1. `initialize()` charge le SQLite **immédiatement** (UI utilisable hors ligne).
2. `_syncLocalToRemote()` envoie les clients `is_synced = 0` via `upsert`, puis les marque synchronisés.
3. `_subscribeToRealtime()` fusionne les clients des autres appareils dans SQLite.
4. `addClient()` capture la position (ou `null`), écrit en local, met à jour l'UI et lance la synchro en tâche de fond (`unawaited`).

### Géolocalisation (`lib/geolocation_service.dart`)

- Vérifie le service GPS et la permission (`checkPermission` / `requestPermission`).
- Retourne `null` si refus, service désactivé ou timeout : **l'inscription n'est jamais bloquée**.
- Modèle `LocationSample` pour ne pas dépendre de `geolocator` dans les tests.

### UI

- Affichage de la position (`📍 lat, lng`) ou « Location not captured ».
- Icône de synchronisation : `cloud_upload` (en attente) / `cloud_done` (synchronisé).

## Permissions

Android — `android/app/src/main/AndroidManifest.xml` :

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

iOS — `ios/Runner/Info.plist` :

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Cette application utilise votre position pour indiquer où vous avez rejoint la file d'attente.</string>
```

Redémarrer complètement l'application après modification (le hot reload ne suffit pas).

## Base de données

Exécuter [`supabase/schema.sql`](./supabase/schema.sql) dans le SQL Editor.
Le script ajoute les colonnes de localisation, les politiques RLS (dont `update` pour l'upsert)
et active le Realtime.

## Lancer

```bash
flutter pub get
flutter create . --project-name waiting_room_app --platforms=android,ios,web
flutter run \
  --dart-define=SUPABASE_URL=https://votre-projet.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=votre-cle-anon
```

Sans configuration : mode démo, SQLite local uniquement.

## Tests

```bash
flutter test
```

- `test/local_queue_service_test.dart` : base SQLite en mémoire (`sqflite_common_ffi`).
- `test/queue_provider_test.dart` : inscription avec/sans GPS, chargement local, suppression.
- `test/models/client_test.dart` : sérialisation locale / distante.
- `test/widgets/client_card_test.dart` : affichage de la position et du statut de synchro.

## Scénario de démonstration

1. En ligne : ajouter un client → il apparaît dans Supabase.
2. Couper Wi-Fi/données : ajouter deux clients → ils apparaissent immédiatement (SQLite).
3. Réactiver le réseau : `_syncLocalToRemote()` envoie automatiquement les clients en attente.
4. Ouvrir l'app sur un autre appareil : les clients arrivent via Realtime.
5. Refuser la permission GPS : l'inscription fonctionne, la position reste vide.

## Livrables

- [x] Persistance locale SQLite + tests.
- [x] Synchronisation automatique des inscriptions en attente.
- [x] Géolocalisation optionnelle avec gestion des permissions.
- [x] Affichage de la position et de l'état de synchronisation.
- [x] Tests TDD (services, provider, modèles, widgets).
