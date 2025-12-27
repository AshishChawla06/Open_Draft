import 'package:flutter/material.dart';

/// Utility class for handling errors and showing user-friendly messages
class ErrorHandler {
  /// Show an error snackbar with a user-friendly message
  static void showErrorSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show a success snackbar
  static void showSuccessSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Show an info snackbar
  static void showInfoSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Show a loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dismiss the currently showing loading dialog
  static void dismissLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Show an error dialog with details
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Technical Details'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SelectableText(
                      details,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Get user-friendly error message from exception
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred';

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }

    // File errors
    if (errorString.contains('file') || errorString.contains('path')) {
      return 'File operation failed. Please try again.';
    }

    // Database errors
    if (errorString.contains('database') || errorString.contains('sql')) {
      return 'Database error. Your data may not have been saved.';
    }

    // Permission errors
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'Permission denied. Please check app permissions.';
    }

    // Parsing errors
    if (errorString.contains('parse') || errorString.contains('format')) {
      return 'Data format error. The file may be corrupted.';
    }

    // Default message
    return 'An error occurred. Please try again.';
  }

  /// Handle async operation with error handling
  static Future<T?> handleAsync<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    bool showLoading = false,
  }) async {
    try {
      if (showLoading && context.mounted) {
        showLoadingDialog(context, message: loadingMessage);
      }

      final result = await operation();

      if (showLoading && context.mounted) {
        dismissLoadingDialog(context);
      }

      if (successMessage != null && context.mounted) {
        showSuccessSnackbar(context, successMessage);
      }

      return result;
    } catch (error, stackTrace) {
      if (showLoading && context.mounted) {
        dismissLoadingDialog(context);
      }

      if (context.mounted) {
        showErrorSnackbar(context, getUserFriendlyMessage(error));
      }

      // Log error for debugging
      debugPrint('Error in handleAsync: $error');
      debugPrint('Stack trace: $stackTrace');

      return null;
    }
  }
}
