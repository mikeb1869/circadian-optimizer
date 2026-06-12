import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'repositories/location_repository.dart';
import 'repositories/sun_times_repository.dart';
import 'services/notification_service.dart';
import 'viewmodels/schedule_viewmodel.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<LocationRepository>(() => LocationRepository());
  getIt.registerLazySingleton<SunTimesRepository>(() => SunTimesRepository());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<ScheduleViewModel>(
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

  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(App(showOnboarding: !onboardingComplete));
}

class App extends StatelessWidget {
  final bool showOnboarding;

  const App({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Circadian Optimizer',
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
