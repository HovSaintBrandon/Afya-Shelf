import '../config/api_config.dart';
import 'api_service.dart';
import '../models/medicine.dart';
import '../models/batch.dart';

class SyncService {
  final ApiService _api = ApiService();

  Future<Map<String, List<dynamic>>> fullSync() async {
    print('🔄 [SYNC] Starting Full Sync...');
    try {
      final data = await _api.post(ApiConfig.syncFull, {});
      
      final medicines = (data['medicines'] as List? ?? [])
          .map((e) => Medicine.fromJson(e))
          .toList();
          
      final batches = (data['batches'] as List? ?? [])
          .map((e) => Batch.fromJson(e))
          .toList();

      print('✅ [SYNC] Full Sync complete. Got ${medicines.length} meds, ${batches.length} batches.');
      return {
        'medicines': medicines,
        'batches': batches,
      };
    } catch (e) {
      print('❌ [SYNC] Full Sync failed: $e');
      rethrow;
    }
  }

  Future<Map<String, List<dynamic>>> pullSync(DateTime lastSyncAt) async {
    print('🔄 [SYNC] Starting Pull Sync (Since: $lastSyncAt)...');
    try {
      final data = await _api.post(ApiConfig.syncPull, {
        'lastSyncAt': lastSyncAt.toIso8601String(),
      });

      final medicines = (data['medicines'] as List? ?? [])
          .map((e) => Medicine.fromJson(e))
          .toList();
          
      final batches = (data['batches'] as List? ?? [])
          .map((e) => Batch.fromJson(e))
          .toList();

      print('✅ [SYNC] Pull Sync complete. Got ${medicines.length} meds, ${batches.length} batches.');
      return {
        'medicines': medicines,
        'batches': batches,
      };
    } catch (e) {
      print('❌ [SYNC] Pull Sync failed: $e');
      rethrow;
    }
  }

  Future<void> pushSync(List<Map<String, dynamic>> operations) async {
    print('📤 [SYNC] Starting Push Sync (${operations.length} operations)...');
    try {
      await _api.post(ApiConfig.syncPush, {
        'operations': operations,
      });
      print('✅ [SYNC] Push Sync complete.');
    } catch (e) {
      print('❌ [SYNC] Push Sync failed: $e');
      rethrow;
    }
  }

  Future<dynamic> ocrExtraction(String filePath) async {
    print('📸 [OCR] Extracting data from: $filePath');
    try {
      final result = await _api.postMultipart(ApiConfig.medicineOCR, filePath, 'document');
      print('✅ [OCR] Extraction successful: $result');
      return result;
    } catch (e) {
      print('❌ [OCR] Extraction failed: $e');
      rethrow;
    }
  }
}
