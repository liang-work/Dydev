import 'dart:io';

/// Log levels with increasing severity.
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3);

  final int value;
  const LogLevel(this.value);
}

/// Simple lightweight logger that writes timestamped messages to stderr.
///
/// Log level can be changed at runtime via [LoggerService.level].
/// Production builds should set it to [LogLevel.warning] or higher.
class LoggerService {
  static final bool _isTest = Platform.environment.containsKey('FLUTTER_TEST');

  /// Current global log level. Defaults to [LogLevel.debug].
  static LogLevel level = LogLevel.debug;

  /// Write a debug message (omitted in test mode).
  static void d(String tag, String message) {
    _log(LogLevel.debug, tag, message);
  }

  /// Write an info message.
  static void i(String tag, String message) {
    _log(LogLevel.info, tag, message);
  }

  /// Write a warning message.
  static void w(String tag, String message) {
    _log(LogLevel.warning, tag, message);
  }

  /// Write an error message with optional exception and stack trace.
  static void e(String tag, String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.error, tag, message);
    if (error != null) {
      stderr.writeln('  Error  : $error');
    }
    if (stack != null) {
      stderr.writeln('  Stack  : $stack');
    }
  }

  static void _log(LogLevel level, String tag, String message) {
    if (level.value < LoggerService.level.value || _isTest) return;
    final now = DateTime.now().toIso8601String();
    stderr.writeln('[$now][${level.name.toUpperCase()}][$tag] $message');
  }
}
