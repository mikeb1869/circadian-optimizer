import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'repositories/location_repository.dart';
import 'repositories/sun_times_repository.dart';
import 'services/notification_service.dart';
import 'viewmodels/schedule_viewmodel.dart';
import 'screens/home_screen.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<LocationRepository>(() => LocationRepository());
  getIt.registerLazySingleton<SunTimesRepository>(() => SunTimesRepository());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerFactory<ScheduleViewModel>(
    () => ScheduleViewModel(
      locationRepository: getIt<LocationRepository>(),
      sunTimesRepository: getIt<SunTimesRepository>(),
      notificationService: getIt<NotificationService>(),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  await getIt<NotificationService>().init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Circadian Optimizer',
      home: HomeScreen(),
    );
  }
}
