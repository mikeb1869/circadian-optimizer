class LocationData {
  final double latitude;
  final double longitude;
  final String? city;

  LocationData({required this.latitude, required this.longitude, this.city});

  // Method to create a copy of the current LocationData with optional new values
  LocationData copyWith({double? latitude, double? longitude, String? city}) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
    );
  }
  
  @override // Override the toString method for better debugging and logging
  String toString() {
    return 'LocationData(latitude: $latitude, longitude: $longitude, city: $city)';
  }
}