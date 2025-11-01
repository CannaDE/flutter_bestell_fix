import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:android_intent_plus/android_intent.dart';

class UpdateService {
  final String githubUser;
  final String githubRepo;

  UpdateService(this.githubUser, this.githubRepo);

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        debugPrint('Kein Internet – Updateprüfung übersprungen.');
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final url = 'https://api.github.com/repos/$githubUser/$githubRepo/releases/latest';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        debugPrint('Fehler beim Abruf des Releases: ${response.statusCode}');
        return;
      }

      final data = jsonDecode(response.body);
      final latestVersion = data['tag_name']?.replaceAll('v', '') ?? '';
      final changelog = data['body'] ?? 'Kein Changelog verfügbar.';
      final assets = data['assets'] as List?;
      final apkAsset = assets?.firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => null,
      );

      final apkUrl = apkAsset != null ? apkAsset['browser_download_url'] : null;

      if (apkUrl == null) {
        debugPrint('Keine APK im Release gefunden.');
        return;
      }

      if (_isNewerVersion(latestVersion, currentVersion)) {
        _showUpdateDialog(context, latestVersion, changelog, apkUrl);
      } else {
        debugPrint('App ist aktuell ($currentVersion)');
      }
    } catch (e) {
      debugPrint('Updateprüfung fehlgeschlagen: $e');
    }
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final l = latest.split('.').map(int.parse).toList();
      final c = current.split('.').map(int.parse).toList();
      for (int i = 0; i < l.length; i++) {
        if (i >= c.length) return true;
        if (l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _showUpdateDialog(
      BuildContext context, String latestVersion, String changelog, String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Neue Version verfügbar ($latestVersion)'),
        content: SingleChildScrollView(child: Text(changelog)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Später'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstallApk(context, apkUrl, latestVersion);
            },
            child: const Text('Jetzt aktualisieren'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstallApk(
      BuildContext context, String url, String version) async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw 'Kein Speicherverzeichnis gefunden';

      final filePath = '${dir.path}/update_v$version.apk';
      debugPrint('Lade APK herunter nach: $filePath');

      final dio = Dio();
      double progress = 0;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Update wird heruntergeladen...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text('${(progress * 100).toStringAsFixed(0)} %'),
              ],
            ),
          ),
        ),
      );

      await dio.download(url, filePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          progress = received / total;
          (context as Element).markNeedsBuild();
        }
      });

      Navigator.pop(context); // Download-Dialog schließen

      // Installation via android_intent_plus starten
      final intent = AndroidIntent(
        action: 'action_view',
        data: 'file://$filePath',
        type: 'application/vnd.android.package-archive',
        flags: <int>[
          0x10000000, // FLAG_ACTIVITY_NEW_TASK
        ],
      );
      await intent.launch();
    } catch (e) {
      debugPrint('Fehler beim Download/Installieren: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fehler'),
          content: Text('Update konnte nicht installiert werden:\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
