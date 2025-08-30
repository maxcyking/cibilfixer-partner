import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelpers {
  /// Converts Firestore Timestamp or String to String
  /// Returns empty string if null
  static String convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Timestamp) return value.toDate().toIso8601String();
    return value.toString();
  }

  /// Converts Firestore Timestamp or String to nullable String
  /// Returns null if input is null
  static String? convertToStringNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Timestamp) return value.toDate().toIso8601String();
    return value.toString();
  }

  /// Converts Firestore Timestamp or String to DateTime
  /// Returns null if conversion fails
  static DateTime? convertToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
} 