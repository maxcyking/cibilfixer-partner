import 'package:cloud_firestore/cloud_firestore.dart';

class AppVersion {
  final String id;
  final String currentVersion;
  final String requiredVersion;
  final String partnerApkUrl;
  final String updateMessage;
  final bool forceUpdate;
  final DateTime lastUpdated;
  final Map<String, dynamic> features;

  AppVersion({
    required this.id,
    required this.currentVersion,
    required this.requiredVersion,
    required this.partnerApkUrl,
    required this.updateMessage,
    required this.forceUpdate,
    required this.lastUpdated,
    required this.features,
  });

  factory AppVersion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AppVersion(
      id: doc.id,
      currentVersion: data['currentVersion'] ?? '1.0.0',
      requiredVersion: data['requiredVersion'] ?? '1.0.0',
      partnerApkUrl: data['partner_apk'] ?? '',
      updateMessage: data['updateMessage'] ?? 'A new version is available',
      forceUpdate: data['forceUpdate'] ?? false,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      features: Map<String, dynamic>.from(data['features'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentVersion': currentVersion,
      'requiredVersion': requiredVersion,
      'partner_apk': partnerApkUrl,
      'updateMessage': updateMessage,
      'forceUpdate': forceUpdate,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'features': features,
    };
  }

  // Parse version string (e.g., "1.2.3") into comparable integers
  List<int> _parseVersion(String version) {
    return version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }

  // Compare two versions
  // Returns: -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
  int compareVersions(String v1, String v2) {
    final version1 = _parseVersion(v1);
    final version2 = _parseVersion(v2);
    
    // Ensure both versions have same length (pad with zeros)
    while (version1.length < version2.length) {
      version1.add(0);
    }
    while (version2.length < version1.length) {
      version2.add(0);
    }
    
    for (int i = 0; i < version1.length; i++) {
      if (version1[i] < version2[i]) return -1;
      if (version1[i] > version2[i]) return 1;
    }
    return 0;
  }

  // Check if update is needed based on version difference
  UpdateType getUpdateType(String appVersion) {
    final currentParts = _parseVersion(appVersion);
    final requiredParts = _parseVersion(requiredVersion);
    
    // Ensure both have at least 3 parts (major.minor.patch)
    while (currentParts.length < 3) {
      currentParts.add(0);
    }
    while (requiredParts.length < 3) {
      requiredParts.add(0);
    }
    
    // If current version is newer or equal, no update needed
    if (compareVersions(appVersion, requiredVersion) >= 0) {
      return UpdateType.none;
    }
    
    // Force update if specified
    if (forceUpdate) {
      return UpdateType.force;
    }
    
    // Check version difference
    if (currentParts[0] < requiredParts[0]) {
      // Major version difference
      return UpdateType.force;
    } else if (currentParts[1] < requiredParts[1]) {
      // Minor version difference
      return UpdateType.optional;
    } else {
      // Only patch version difference
      return UpdateType.none;
    }
  }

  bool get hasValidApkUrl => partnerApkUrl.isNotEmpty;
  
  String get formattedUpdateMessage => 
      '$updateMessage\nCurrent: $currentVersion → Latest: $requiredVersion';
}

enum UpdateType {
  none,      // No update needed (patch version difference)
  optional,  // Optional update (minor version difference)
  force,     // Force update required (major version difference or forceUpdate flag)
}

extension UpdateTypeExtension on UpdateType {
  bool get shouldShowBanner => this == UpdateType.optional || this == UpdateType.force;
  bool get isForced => this == UpdateType.force;
  
  String get title {
    switch (this) {
      case UpdateType.none:
        return '';
      case UpdateType.optional:
        return 'Update Available';
      case UpdateType.force:
        return 'Update Required';
    }
  }
  
  String get description {
    switch (this) {
      case UpdateType.none:
        return '';
      case UpdateType.optional:
        return 'A new version of the app is available with improvements and new features.';
      case UpdateType.force:
        return 'This update is required to continue using the app.';
    }
  }
} 