import 'package:solar_calculator/solar_calculator.dart';
import '../models/location_data.dart';

class SunTimes {
  final DateTime sunrise;
  final DateTime sunset;

  SunTimes({required this.sunrise, required this.sunset});

  @override
  String toString() => 'SunTimes(sunrise: $sunrise, sunset: $sunset)';
}

class SunTimesRepository {
  Future<SunTimes> getSunTimes(LocationData location) async {
    final now = DateTime.now();
    final timezoneOffset = now.timeZoneOffset.inMinutes / 60;
    final instant = Instant(
      year: now.year,
      month: now.month,
      day: now.day,
      timeZoneOffset: timezoneOffset,
    );

    final calculator = SolarCalculator(
      instant,
      location.latitude,
      location.longitude,
      timezoneOffset,
    );

    final sunriseUtc = calculator.sunriseTime.toUtcDateTime();
    final sunsetUtc = calculator.sunsetTime.toUtcDateTime();

    final sunrise = DateTime(
      sunriseUtc.year,
      sunriseUtc.month,
      sunriseUtc.day,
      sunriseUtc.hour + timezoneOffset.toInt(),
      sunriseUtc.minute,
      sunriseUtc.second,
    );

    final sunset = DateTime(
      sunsetUtc.year,
      sunsetUtc.month,
      sunsetUtc.day,
      sunsetUtc.hour + timezoneOffset.toInt(),
      sunsetUtc.minute,
      sunsetUtc.second,
    );

    return SunTimes(sunrise: sunrise, sunset: sunset);
  }
}
