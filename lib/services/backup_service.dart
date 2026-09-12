import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/services/auth_service.dart';

class BackupService {
  final GoogleAuthService _authService;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  BackupService(this._authService);

  Future<drive.DriveApi> _getDriveApi() async {
    final client = await _authService.getAuthenticatedClient();
    if (client == null) {
      throw Exception('User not signed in with Google or authorization failed');
    }
    return drive.DriveApi(client);
  }

  Future<String?> _getOrCreateBackupFolder(drive.DriveApi driveApi) async {
    final drive.FileList result = await driveApi.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and name='${AppConstants.googleDriveBackupFolder}' and trashed=false",
      $fields: 'files(id, name)',
    );

    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id;
    }

    final drive.File folder = drive.File()
      ..name = AppConstants.googleDriveBackupFolder
      ..mimeType = 'application/vnd.google-apps.folder';

    final drive.File createdFolder = await driveApi.files.create(folder);
    return createdFolder.id;
  }

  Future<bool> backupDatabase() async {
    try {
      if (!_authService.isSignedIn()) {
        throw Exception('Please sign in with Google to enable backup');
      }

      final drive.DriveApi driveApi = await _getDriveApi();
      final String? folderId = await _getOrCreateBackupFolder(driveApi);
      if (folderId == null) {
        throw Exception('Failed to create or find backup folder');
      }

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final File dbFile = File('${appDocDir.path}/${AppConstants.dbName}');
      if (!dbFile.existsSync()) {
        throw Exception('Database file not found');
      }

      final drive.File fileMeta = drive.File()
        ..name = '${AppConstants.dbName}_${DateTime.now().toIso8601String().replaceAll(':', '-')}'
        ..parents = [folderId];

      final dbStream = dbFile.openRead();
      final int fileSize = await dbFile.length();

      final drive.File uploadedFile = await driveApi.files.create(
        fileMeta,
        uploadMedia: drive.Media(dbStream, fileSize),
      );

      return uploadedFile.id != null;
    } catch (e) {
      throw Exception('Backup failed: $e');
    }
  }

  Future<List<drive.File>> listBackups() async {
    try {
      if (!_authService.isSignedIn()) {
        throw Exception('User not signed in');
      }

      final drive.DriveApi driveApi = await _getDriveApi();
      final String? folderId = await _getOrCreateBackupFolder(driveApi);

      final drive.FileList result = await driveApi.files.list(
        q: "'$folderId' in parents and trashed=false",
        $fields: 'files(id, name, createdTime, size)',
        orderBy: 'createdTime desc',
      );

      return result.files ?? [];
    } catch (e) {
      throw Exception('Failed to list backups: $e');
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.read(googleAuthServiceProvider));
});
