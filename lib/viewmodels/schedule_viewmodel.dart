import 'package:flutter/foundation.dart';
import '../models/circadian_schedule.dart';
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

  ScheduleViewModel({
    required this._locationRepository,
    required this._sunTimesRepository,
    required this._notificationService,
  });

  Future<void> loadSchedule() async {
    state.value = ScheduleLoading();

    try {
      final location = await _locationRepository.getCurrentLocation();
      final sunTimes = await _sunTimesRepository.getSunTimes(location);
      final schedule = CircadianSchedule.fromSunTimes(sunTimes);
      state.value = ScheduleSuccess(schedule, city: location.city);
    } catch (e) {
      state.value = ScheduleError(e.toString());
      return;
    }

    try {
      await _notificationService.scheduleAllCueNotifications(
        (state.value as ScheduleSuccess).schedule,
      );
    } catch (_) {
      // Notifications are best-effort — don't fail the whole screen if scheduling fails
    }
  }

  void dispose() {
    state.dispose();
  }
}
