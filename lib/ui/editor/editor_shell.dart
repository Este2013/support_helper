import 'package:flutter/material.dart';
import 'scenario_list_panel.dart';

/// The editor shell shows the scenario list as the default view.
/// Nested routes (new/edit) replace this content via go_router.
class EditorShell extends StatelessWidget {
  const EditorShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScenarioListPanel();
  }
}
