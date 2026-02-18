import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../ui/shell/app_shell.dart';
import '../ui/home/home_screen.dart';
import '../ui/profile/profile_tab_screen.dart';
import '../ui/session/session_screen.dart';
import '../ui/editor/editor_shell.dart';
import '../ui/editor/scenario_editor_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/editor',
            name: 'editorList',
            builder: (context, state) => const EditorShell(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'editorNew',
                builder: (context, state) =>
                    const ScenarioEditorScreen(scenarioId: null, scenarioVersion: null),
              ),
              GoRoute(
                path: ':scenarioId/:scenarioVersion',
                name: 'editorScenario',
                builder: (context, state) => ScenarioEditorScreen(
                  scenarioId: state.pathParameters['scenarioId']!,
                  scenarioVersion: state.pathParameters['scenarioVersion']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile/:profileId',
            name: 'profile',
            builder: (context, state) => ProfileTabScreen(
              profileId: state.pathParameters['profileId']!,
            ),
            routes: [
              GoRoute(
                path: 'session/:sessionId',
                name: 'session',
                builder: (context, state) => SessionScreen(
                  profileId: state.pathParameters['profileId']!,
                  sessionId: state.pathParameters['sessionId']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
