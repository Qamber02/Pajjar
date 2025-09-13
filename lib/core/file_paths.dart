import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Utility class to manage file paths for the dictionary app
class FilePaths {
  /// Private constructor to prevent instantiation
  FilePaths._();

  /// Directory where app data is stored
  static Future<Directory> get _documentsDir async {
    return await getApplicationDocumentsDirectory();
  }

  /// Path to the main JSON data file
  static Future<String> get wordsJsonPath async {
    final dir = await _documentsDir;
    return '${dir.path}/words.json';
  }

  /// Path to the temporary JSON file used during atomic writes
  static Future<String> get wordsJsonTempPath async {
    final dir = await _documentsDir;
    return '${dir.path}/words.json.tmp';
  }

  /// Path to the CSV mirror file
  static Future<String> get wordsCsvPath async {
    final dir = await _documentsDir;
    return '${dir.path}/words.csv';
  }

  /// Path to the backups directory
  static Future<String> get backupsDir async {
    final dir = await _documentsDir;
    final backupsPath = '${dir.path}/backups';
    final directory = Directory(backupsPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return backupsPath;
  }

  /// Generates a timestamped backup file path
  static Future<String> get timestampedBackupPath async {
    final backupDir = await backupsDir;
    final timestamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    return '$backupDir/words-$timestamp.json';
  }

  /// Ensures all required directories exist
  static Future<void> ensureDirectoriesExist() async {
    final dir = await _documentsDir;
    final backupDir = Directory('${dir.path}/backups');
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
  }
}
