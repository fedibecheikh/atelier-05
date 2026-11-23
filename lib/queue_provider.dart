import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:waiting_room_app/geolocation_service.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/models/client.dart';

/// Provider offline-first :
/// 1. lit toujours le SQLite local pour afficher l'UI instantanément ;
/// 2. tente ensuite de synchroniser les enregistrements en attente ;
/// 3. écoute Supabase Realtime pour fusionner les clients des autres appareils.
class QueueProvider extends ChangeNotifier {
  QueueProvider({
    SupabaseClient? supabase,
    LocalQueueService? localDb,
    GeolocationService? geoService,
    this.isDemo = false,
  })  : _supabase = supabase,
        _localDb = localDb ?? LocalQueueService(),
        _geoService = geoService ?? GeolocationService();

  final SupabaseClient? _supabase;
  final LocalQueueService _localDb;
  final GeolocationService _geoService;
  final bool isDemo;

  final List<Client> _clients = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _error;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;

  List<Client> get clients => List<Client>.unmodifiable(_clients);
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;

  Future<void> initialize() async {
    await _loadFromLocal();

    if (_supabase != null) {
      unawaited(_syncLocalToRemote());
      _subscribeToRealtime();
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final rows = await _localDb.getClients();
      _clients
        ..clear()
        ..addAll(rows.map(Client.fromLocalMap));
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      _error = 'Impossible de lire la base locale : $error';
      notifyListeners();
    }
  }

  Future<void> addClient(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final location = await _geoService.getCurrentLocation();

    final client = Client(
      id: const Uuid().v4(),
      name: trimmed,
      createdAt: DateTime.now(),
      lat: location?.latitude,
      lng: location?.longitude,
      accuracy: location?.accuracy,
      isSynced: false,
    );

    await _localDb.insertClientLocally(client.toLocalMap());

    _clients
      ..add(client)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();

    if (_supabase != null) {
      unawaited(_syncLocalToRemote());
    }
  }

  Future<void> removeClient(String id) async {
    await _localDb.deleteClient(id);
    _clients.removeWhere((client) => client.id == id);
    notifyListeners();

    if (_supabase != null) {
      try {
        await _supabase.from('clients').delete().eq('id', id);
      } catch (error) {
        debugPrint('Suppression distante impossible : $error');
      }
    }
  }

  Future<void> nextClient() async {
    if (_clients.isEmpty) return;
    await removeClient(_clients.first.id);
  }

  Future<void> _syncLocalToRemote() async {
    final supabase = _supabase;
    if (supabase == null || _isSyncing) return;

    _isSyncing = true;
    try {
      final unsynced = await _localDb.getUnsyncedClients();

      for (final row in unsynced) {
        final client = Client.fromLocalMap(row);
        try {
          await supabase.from('clients').upsert(client.toRemoteMap());
          await _localDb.markClientAsSynced(client.id);
        } catch (error) {
          debugPrint('Synchronisation échouée pour ${client.id} : $error');
        }
      }

      await _loadFromLocal();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void _subscribeToRealtime() {
    final supabase = _supabase;
    if (supabase == null) return;

    _realtimeSubscription = supabase
        .from('clients')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .listen(
          _mergeRemoteClients,
          onError: (Object error) {
            _error = 'Flux temps réel indisponible : $error';
            notifyListeners();
          },
        );
  }

  Future<void> _mergeRemoteClients(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      try {
        final client = Client.fromRemoteMap(row);
        await _localDb.insertClientLocally(
          client.copyWith(isSynced: true).toLocalMap(),
        );
      } catch (error) {
        debugPrint('Client distant invalide : $error');
      }
    }

    await _loadFromLocal();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
