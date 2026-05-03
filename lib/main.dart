// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/ai_personality_provider.dart';
import 'providers/alarm_provider.dart';
import 'providers/self_learning_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/activity_provider.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/tool_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise local database
  await DatabaseService.instance.init();

  // Initialise notifications
  await NotificationService.instance.init();

  // Initialise tool registry
  ToolRegistry.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => AIPersonalityProvider()),
        ChangeNotifierProvider(create: (_) => SelfLearningProvider()),
        ChangeNotifierProvider(create: (_) => AlarmProvider()),
      ],
      child: const SelaphimApp(),
    ),
  );
}
