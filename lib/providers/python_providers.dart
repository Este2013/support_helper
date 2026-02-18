import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/python/python_input.dart';
import '../data/services/python_runner_service.dart';

part 'python_providers.g.dart';

class PythonRunState {
  final bool isRunning;
  final String? suggestedAnswer;
  final String? notes;
  final String? error;

  const PythonRunState({
    this.isRunning = false,
    this.suggestedAnswer,
    this.notes,
    this.error,
  });

  bool get hasResult => suggestedAnswer != null || notes != null || error != null;

  PythonRunState copyWith({
    bool? isRunning,
    String? suggestedAnswer,
    String? notes,
    String? error,
    bool clear = false,
  }) {
    if (clear) return const PythonRunState();
    return PythonRunState(
      isRunning: isRunning ?? this.isRunning,
      suggestedAnswer: suggestedAnswer ?? this.suggestedAnswer,
      notes: notes ?? this.notes,
      error: error ?? this.error,
    );
  }
}

@riverpod
class PythonRunner extends _$PythonRunner {
  @override
  PythonRunState build(String profileId, String sessionId, String questionId) {
    return const PythonRunState();
  }

  Future<void> run(String scriptPath, PythonScriptInput input) async {
    state = state.copyWith(isRunning: true, clear: false);
    final service = PythonRunnerService();
    final result = await service.run(scriptPath, input);
    if (result.isSuccess) {
      state = PythonRunState(
        isRunning: false,
        suggestedAnswer: result.output!.suggestedAnswer,
        notes: result.output!.notes,
      );
    } else {
      state = PythonRunState(isRunning: false, error: result.error);
    }
  }

  void clear() {
    state = const PythonRunState();
  }
}
