import 'package:supabase_flutter/supabase_flutter.dart';

class AppException implements Exception {
  const AppException(this.message, {this.permissionDenied = false});

  final String message;
  final bool permissionDenied;

  @override
  String toString() => message;
}

bool isPermissionDenied(Object error) {
  if (error is AppException) return error.permissionDenied;
  if (error is PostgrestException) return error.code == '42501';
  return false;
}

String friendlyError(Object error) {
  if (isPermissionDenied(error)) {
    return 'Permission denied. You are not allowed to do that.';
  }
  if (error is AppException) return error.message;
  if (error is PostgrestException) return error.message;
  if (error is AuthException) return error.message;
  if (error is StorageException) return error.message;
  return 'Something went wrong. Please try again.';
}
