import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/python/python_input.dart';
import '../models/python/python_output.dart';

class PythonRunnerResult {
  final PythonScriptOutput? output;
  final String? error;

  const PythonRunnerResult({this.output, this.error});

  bool get isSuccess => error == null && output != null;
}

class PythonRunnerService {
  static const Duration _timeout = Duration(seconds: 30);

  Future<PythonRunnerResult> run(
      String scriptPath, PythonScriptInput input) async {
    final inputJson = jsonEncode(input.toJson());

    String? lastError;

    // Try 'python' first, then 'python3' as fallback
    for (final executable in ['python', 'python3']) {
      try {
        final result = await _runProcess(executable, scriptPath, inputJson);
        return result;
      } on ProcessException catch (e) {
        lastError = e.message;
        continue;
      } on TimeoutException {
        return const PythonRunnerResult(
            error: 'Script timed out after 30 seconds.');
      } catch (e) {
        lastError = e.toString();
        continue;
      }
    }

    return PythonRunnerResult(
        error: 'Could not find Python executable. '
            'Please ensure Python is installed and in your PATH.\n'
            'Last error: $lastError');
  }

  Future<PythonRunnerResult> _runProcess(
      String executable, String scriptPath, String inputJson) async {
    final process = await Process.start(executable, [scriptPath]);

    // Write input JSON to stdin and close
    process.stdin.write(inputJson);
    await process.stdin.close();

    // Collect stdout and stderr
    final stdoutFuture =
        process.stdout.transform(utf8.decoder).join();
    final stderrFuture =
        process.stderr.transform(utf8.decoder).join();

    final exitCode = await process.exitCode.timeout(_timeout);
    final stdout = (await stdoutFuture).trim();
    final stderr = (await stderrFuture).trim();

    if (exitCode != 0) {
      return PythonRunnerResult(
          error: 'Script exited with code $exitCode.\n'
              '${stderr.isNotEmpty ? stderr : '(no stderr output)'}');
    }

    if (stdout.isEmpty) {
      return const PythonRunnerResult(error: 'Script produced no output.');
    }

    try {
      final json = jsonDecode(stdout) as Map<String, dynamic>;
      return PythonRunnerResult(output: PythonScriptOutput.fromJson(json));
    } catch (e) {
      return PythonRunnerResult(
          error: 'Script output is not valid JSON:\n$stdout');
    }
  }
}
