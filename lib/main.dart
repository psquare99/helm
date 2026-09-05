import 'package:flutter/material.dart';
import 'core/theme/command_theme.dart';
import 'presentation/state/project_manager_controller.dart';
import 'presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = ProjectManagerController();
  await controller.init();

  runApp(ProjectManagerApp(controller: controller));
}

class ProjectManagerApp extends StatelessWidget {
  final ProjectManagerController controller;

  const ProjectManagerApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Manager // P² System',
      debugShowCheckedModeBanner: false,
      theme: CommandTheme.lightTheme,
      home: DashboardScreen(controller: controller),
    );
  }
}
