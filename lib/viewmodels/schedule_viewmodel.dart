import 'package:flutter/foundation.dart';
import '../models/circadian_schedule.dart';
import '../models/location_data.dart';
import '../repositories/location_repository.dart';
import '../repositories/sun_times_repository.dart';
import '../services/notification_service.dart';

sealed class ScheduleState {}

class ScheduleLoading extends ScheduleState {}

class ScheduleSuccess extends ScheduleState {
  final CircadianSchedule schedule;
  final String? city;
  ScheduleSuccess(this.schedule, {this.city});
}

class ScheduleError extends ScheduleState {
  final String message;
  ScheduleError(this.message);
}

class ScheduleViewModel {
  final LocationRepository _locationRepository;
  final SunTimesRepository _sunTimesRepository;
  final NotificationService _notificationService;

  final ValueNotifier<ScheduleState> state = ValueNotifier(ScheduleLoading());

  LocationData? lastLocation;

  ScheduleViewModel({
    required this._locationRepository,
    required this._sunTimesRepository,
    required this._notificationService,
  });

  Future<void> loadSchedule() async {
    state.value = ScheduleLoading();

    late CircadianSchedule todaySchedule;
    late CircadianSchedule tomorrowSchedule;

    try {
      final location = await _locationRepository.getCurrentLocation();
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      final todaySunTimes = await _sunTimesRepository.getSunTimes(location);
      final tomorrowSunTimes = await _sunTimesRepository.getSunTimes(
        location,
        date: tomorrow,
      );

      todaySchedule = CircadianSchedule.fromSunTimes(todaySunTimes);
      tomorrowSchedule = CircadianSchedule.fromSunTimes(tomorrowSunTimes);

      lastLocation = location;
      state.value = ScheduleSuccess(todaySchedule, city: location.city);
    } catch (e) {
      state.value = ScheduleError(e.toString());
      return;
    }

    try {
      await _notificationService.scheduleAllCueNotifications(
        todaySchedule,
        tomorrowSchedule,
      );
    } catch (_) {}
  }

  void dispose() {
    state.dispose();
  }
}
