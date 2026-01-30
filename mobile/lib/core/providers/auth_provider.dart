import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/auth_service.dart';

final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await authService.getCurrentUser();
});
