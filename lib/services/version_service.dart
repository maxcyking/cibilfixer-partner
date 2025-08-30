import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_version_model.dart';

class VersionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'version';
  final String _partnerAppDoc = 'partner_app';
  
  static const String _currentAppVersion = '1.0.0'; // This should match your pubspec.yaml version
  
  // Cache for version info
  AppVersion? _cachedVersion;
  DateTime? _lastCheck;
  static const Duration _cacheTimeout = Duration(hours: 1);

  // Get current app version from package info
  Future<String> getCurrentAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print('Error getting package info: $e');
      return _currentAppVersion; // Fallback to hardcoded version
    }
  }

  // Get version info from Firestore
  Future<AppVersion?> getLatestVersionInfo() async {
    try {
      // Check cache first
      if (_cachedVersion != null && _lastCheck != null) {
        final timeSinceLastCheck = DateTime.now().difference(_lastCheck!);
        if (timeSinceLastCheck < _cacheTimeout) {
          print('Using cached version info');
          return _cachedVersion;
        }
      }

      print('Fetching latest version info from Firestore');
      
      final doc = await _firestore
          .collection(_collection)
          .doc(_partnerAppDoc)
          .get();

      if (doc.exists) {
        _cachedVersion = AppVersion.fromFirestore(doc);
        _lastCheck = DateTime.now();
        print('Latest version info: ${_cachedVersion!.requiredVersion}');
        return _cachedVersion;
      } else {
        print('Version document not found');
        return null;
      }
    } catch (e) {
      print('Error fetching version info: $e');
      return null;
    }
  }

  // Check if update is available
  Future<UpdateInfo> checkForUpdate() async {
    try {
      final currentVersion = await getCurrentAppVersion();
      final versionInfo = await getLatestVersionInfo();
      
      if (versionInfo == null) {
        return UpdateInfo(
          updateType: UpdateType.none,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          downloadUrl: '',
          message: '',
        );
      }

      final updateType = versionInfo.getUpdateType(currentVersion);
      
      return UpdateInfo(
        updateType: updateType,
        currentVersion: currentVersion,
        latestVersion: versionInfo.requiredVersion,
        downloadUrl: versionInfo.partnerApkUrl,
        message: versionInfo.updateMessage,
        appVersion: versionInfo,
      );
    } catch (e) {
      print('Error checking for update: $e');
      final currentVersion = await getCurrentAppVersion();
      return UpdateInfo(
        updateType: UpdateType.none,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        downloadUrl: '',
        message: '',
      );
    }
  }

  // Download the APK
  Future<void> downloadUpdate(String downloadUrl) async {
    try {
      if (downloadUrl.isEmpty) {
        throw 'Download URL is empty';
      }

      final uri = Uri.parse(downloadUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('Download initiated: $downloadUrl');
      } else {
        throw 'Could not launch download URL';
      }
    } catch (e) {
      print('Error downloading update: $e');
      rethrow;
    }
  }

  // Get version info stream for real-time updates
  Stream<AppVersion?> getVersionInfoStream() {
    return _firestore
        .collection(_collection)
        .doc(_partnerAppDoc)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            _cachedVersion = AppVersion.fromFirestore(snapshot);
            _lastCheck = DateTime.now();
            return _cachedVersion;
          }
          return null;
        });
  }

  // Clear cache (useful for testing or manual refresh)
  void clearCache() {
    _cachedVersion = null;
    _lastCheck = null;
  }

  // Create or update version info (for admin use)
  Future<void> updateVersionInfo({
    required String currentVersion,
    required String requiredVersion,
    required String partnerApkUrl,
    String updateMessage = 'A new version is available',
    bool forceUpdate = false,
    Map<String, dynamic> features = const {},
  }) async {
    try {
      final versionData = {
        'currentVersion': currentVersion,
        'requiredVersion': requiredVersion,
        'partner_apk': partnerApkUrl,
        'updateMessage': updateMessage,
        'forceUpdate': forceUpdate,
        'lastUpdated': FieldValue.serverTimestamp(),
        'features': features,
      };

      await _firestore
          .collection(_collection)
          .doc(_partnerAppDoc)
          .set(versionData, SetOptions(merge: true));
      
      // Clear cache to force refresh
      clearCache();
      
      print('Version info updated successfully');
    } catch (e) {
      print('Error updating version info: $e');
      rethrow;
    }
  }
}

class UpdateInfo {
  final UpdateType updateType;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String message;
  final AppVersion? appVersion;

  UpdateInfo({
    required this.updateType,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.message,
    this.appVersion,
  });

  bool get shouldShowUpdate => updateType.shouldShowBanner;
  bool get isForceUpdate => updateType.isForced;
  bool get hasValidDownloadUrl => downloadUrl.isNotEmpty;

  String get updateTitle => updateType.title;
  String get updateDescription => updateType.description;
  
  String get formattedMessage {
    if (message.isNotEmpty) {
      return '$message\nCurrent: $currentVersion → Latest: $latestVersion';
    }
    return 'Current: $currentVersion → Latest: $latestVersion';
  }
} 