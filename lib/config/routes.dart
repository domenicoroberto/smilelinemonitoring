import 'package:flutter/material.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String timer = '/timer';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String stageDetail = '/stage-detail';
  static const String editPlan = '/edit-plan';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (_) => Container(),
      onboarding: (_) => Container(),
      home: (_) => Container(),
      timer: (_) => Container(),
      history: (_) => Container(),
      settings: (_) => Container(),
    };
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case stageDetail:
        return MaterialPageRoute(
          builder: (_) => Container(),
          settings: settings,
        );
      case editPlan:
        return MaterialPageRoute(
          builder: (_) => Container(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route non trovata')),
          ),
        );
    }
  }
}

class StageDetailArgs {
  final int stageNumber;
  final String stageType;

  StageDetailArgs({
    required this.stageNumber,
    required this.stageType,
  });
}