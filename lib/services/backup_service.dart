import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/alarm_model.dart';
import '../models/stats_model.dart';
import 'hive_service.dart';
import '../controllers/alarm_controller.dart';
import '../controllers/stats_controller.dart';
import 'package:get/get.dart';

class BackupService {
  
  /// Export data to JSON string
  Future<String> exportData() async {
    try {
      final alarms = HiveService.getAllAlarms().map((a) => a.toJson()).toList();
      final stats = HiveService.getStats().toJson();
      
      final data = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'alarms': alarms,
        'stats': stats,
      };
      
      return jsonEncode(data);
    } catch (e) {
      print('Export error: $e');
      throw Exception('Failed to export data');
    }
  }

  /// Share backup as a JSON file
  Future<void> shareDataAsFile() async {
    try {
      final json = await exportData();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/nashur_backup.json');
      await file.writeAsString(json);
      
      final xFile = XFile(file.path, mimeType: 'application/json');
      await Share.shareXFiles([xFile], text: 'نسخة احتياطية لتطبيق نَشُور');
    } catch (e) {
      print('Share file error: $e');
      throw Exception('Failed to share backup file');
    }
  }

  /// Import data from a selected file
  Future<void> importDataFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        await importData(jsonString);
      }
    } catch (e) {
      print('Import file error: $e');
      throw Exception('Failed to import from file: $e');
    }
  }

  /// Import data from JSON string
  Future<void> importData(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);
      
      if (data['version'] != 1) {
        throw Exception('Unsupported backup version');
      }

      // Restore Alarms
      if (data['alarms'] != null) {
        await HiveService.clearAlarms();
        
        final alarmsList = data['alarms'] as List;
        for (var alarmJson in alarmsList) {
          final alarm = AlarmModel.fromJson(alarmJson);
          await HiveService.saveAlarm(alarm);
        }
        
        // Refresh controller
        if (Get.isRegistered<AlarmController>()) {
          Get.find<AlarmController>().loadAlarms();
        }
      }

      // Restore Stats
      if (data['stats'] != null) {
        final stats = StatsModel.fromJson(data['stats']);
        await HiveService.saveStats(stats);
        
        if (Get.isRegistered<StatsController>()) {
          Get.find<StatsController>().loadStats();
        }
      }

    } catch (e) {
      print('Import error: $e');
      throw Exception('Failed to import data: $e');
    }
  }

  /// Copy backup to clipboard
  Future<void> copyBackupToClipboard() async {
    final json = await exportData();
    await Clipboard.setData(ClipboardData(text: json));
  }

  /// Paste and restore from clipboard
  Future<void> restoreFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) throw Exception('No data in clipboard');
    
    await importData(data!.text!);
  }
}
