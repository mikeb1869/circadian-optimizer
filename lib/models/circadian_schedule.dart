import '../repositories/sun_times_repository.dart';

class CircadianSchedule {
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime morningSunlightStart;
  final DateTime morningSunlightEnd;
  final DateTime afternoonSunlightStart;
  final DateTime afternoonSunlightEnd;
  final DateTime caffeineCutoff;
  final DateTime dimLights;
  final DateTime bedtime;

  CircadianSchedule({
    required this.sunrise,
    required this.sunset,
    required this.morningSunlightStart,
    required this.morningSunlightEnd,
    required this.afternoonSunlightStart,
    required this.afternoonSunlightEnd,
    required this.caffeineCutoff,
    required this.dimLights,
    required this.bedtime,
  });

  static CircadianSchedule fromSunTimes(SunTimes sunTimes) {
    return CircadianSchedule(
      sunrise: sunTimes.sunrise,
      sunset: sunTimes.sunset,
      morningSunlightStart: sunTimes.sunrise,
      morningSunlightEnd: sunTimes.sunrise.add(const Duration(hours: 3)),
      afternoonSunlightStart: sunTimes.sunset.subtract(const Duration(hours: 2)),
      afternoonSunlightEnd: sunTimes.sunset,
      caffeineCutoff: sunTimes.sunset.subtract(const Duration(hours: 4)),
      dimLights: sunTimes.sunset.add(const Duration(hours: 2)),
      bedtime: sunTimes.sunset.add(const Duration(hours: 4)),
    );
  }

  @override // Override the toString method for better debugging and logging
  String toString() {
    return 'CircadianSchedule(sunrise: $sunrise, sunset: $sunset, morningSunlightStart: $morningSunlightStart, morningSunlightEnd: $morningSunlightEnd, afternoonSunlightStart: $afternoonSunlightStart, afternoonSunlightEnd: $afternoonSunlightEnd, caffeineCutoff: $caffeineCutoff, dimLights: $dimLights, bedtime: $bedtime)';
  }
}
