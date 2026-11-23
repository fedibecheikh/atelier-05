/// Client de la file d'attente, avec ses métadonnées de synchronisation.
class Client {
  const Client({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lat,
    this.lng,
    this.accuracy,
    this.isSynced = false,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final double? lat;
  final double? lng;
  final double? accuracy;
  final bool isSynced;

  bool get hasLocation => lat != null && lng != null;

  String get locationText => hasLocation
      ? '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}'
      : 'Location not captured';

  /// Sérialisation pour Supabase : uniquement les données métier.
  Map<String, dynamic> toRemoteMap() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'location_accuracy_m': accuracy,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  /// Sérialisation pour SQLite : inclut `is_synced`, propre au device,
  /// et utilise le nom de colonne local `accuracy_m`.
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'accuracy_m': accuracy,
      'created_at': createdAt.toUtc().toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Client.fromRemoteMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'].toString(),
      name: map['name'] as String,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      accuracy: (map['location_accuracy_m'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      isSynced: true,
    );
  }

  factory Client.fromLocalMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      name: map['name'] as String,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      accuracy: (map['accuracy_m'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      isSynced: (map['is_synced'] as num?)?.toInt() == 1,
    );
  }

  Client copyWith({bool? isSynced}) {
    return Client(
      id: id,
      name: name,
      createdAt: createdAt,
      lat: lat,
      lng: lng,
      accuracy: accuracy,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() =>
      'Client(id: $id, name: $name, isSynced: $isSynced, lat: $lat, lng: $lng)';
}
