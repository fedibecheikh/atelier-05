/// Position simplifiée renvoyée par [GeolocationService].
///
/// Ce modèle évite de dépendre de `geolocator` dans les tests et l'UI.
class LocationSample {
  const LocationSample({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  final double latitude;
  final double longitude;
  final double accuracy;

  @override
  String toString() =>
      'LocationSample(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
}
