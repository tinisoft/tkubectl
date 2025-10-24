class CommandResult {
  final bool success;
  final String output;
  final String error;
  final int exitCode;
  final DateTime timestamp;

  const CommandResult({
    required this.success,
    required this.output,
    required this.error,
    required this.exitCode,
    required this.timestamp,
  });

  factory CommandResult.success(String output) {
    return CommandResult(
      success: true,
      output: output,
      error: '',
      exitCode: 0,
      timestamp: DateTime.now(),
    );
  }

  factory CommandResult.error(String error, {int exitCode = 1}) {
    return CommandResult(
      success: false,
      output: '',
      error: error,
      exitCode: exitCode,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'CommandResult(success: $success, exitCode: $exitCode, output: ${output.length} chars, error: ${error.length} chars)';
  }
}