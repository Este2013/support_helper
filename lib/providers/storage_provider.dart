import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/services/storage_service.dart';

part 'storage_provider.g.dart';

@Riverpod(keepAlive: true)
Future<StorageService> storageService(StorageServiceRef ref) async {
  final service = StorageService();
  await service.initialize();
  return service;
}
