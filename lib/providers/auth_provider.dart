import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  static const String _userDataKey = 'cached_user_data';
  static const String _lastLoginKey = 'last_login_time';

  // Getters
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _user != null && _userData != null;
  bool get isAdmin => _userData?['role']?.toString().toLowerCase() == 'admin';
  bool get isSalesRepresentative => _userData?['role']?.toString().toLowerCase() == 'sales representative';
  bool get isPartner => _userData?['role']?.toString().toLowerCase() == 'partner';
  bool get hasAuthorizedRole => isSalesRepresentative || isPartner;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  
  // KYC Status checks
  bool get isKycCompleted => _userData?['kycStatus']?.toString().toLowerCase() == 'completed' || 
                            _userData?['kycStatus']?.toString().toLowerCase() == 'approved';
  bool get isKycPending => _userData?['kycStatus']?.toString().toLowerCase() == 'pending';
  bool get requiresKyc => isAuthenticated && !isKycCompleted;
  String? get kycStatus => _userData?['kycStatus']?.toString();

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // Load cached user data first for faster app startup
    await _loadCachedUserData();

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _fetchUserData(user.uid);
      } else {
        _userData = null;
        await _clearCachedData();
      }
      
      if (!_isInitialized) {
        _isInitialized = true;
        _isLoading = false;
      }
      notifyListeners();
    });
  }

  Future<void> _loadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_userDataKey);
      final lastLoginTime = prefs.getInt(_lastLoginKey);
      
      if (cachedData != null && lastLoginTime != null) {
        // Check if cached data is still valid (7 days)
        final cacheAge = DateTime.now().millisecondsSinceEpoch - lastLoginTime;
        const maxCacheAge = 7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds
        
        if (cacheAge < maxCacheAge) {
          _userData = json.decode(cachedData);
        } else {
          // Cache expired, clear it
          await _clearCachedData();
        }
      }
    } catch (e) {
      // If there's any error loading cache, just continue without it
      await _clearCachedData();
    }
  }

  Future<void> _saveUserDataToCache(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, json.encode(userData));
      await prefs.setInt(_lastLoginKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // If caching fails, just continue without it
    }
  }

  Future<void> _clearCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.remove(_lastLoginKey);
    } catch (e) {
      // If clearing cache fails, just continue
    }
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userData = doc.data();
        await _saveUserDataToCache(_userData!);
      } else {
        _userData = null;
      }
    } catch (e) {
      _userData = null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Login method
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = credential.user;
      
      if (_user != null) {
        // Fetch user data from Firestore
        final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
        
        if (!userDoc.exists) {
          _error = 'User data not found in database';
          await _auth.signOut();
          _user = null;
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        _userData = userDoc.data();
        
        // Check if user has authorized role (sales representative or partner) - case insensitive
        final userRole = _userData?['role']?.toString().toLowerCase();
        if (userRole != 'sales representative' && userRole != 'partner') {
          _error = 'Access denied. Only Sales Representatives and Partners can access this system.';
          await _auth.signOut();
          _user = null;
          _userData = null;
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        // Check if user is active
        final isActive = _userData?['isActive'];
        if (isActive != true) {
          _error = 'Your account has been disabled. Please contact support.';
          await _auth.signOut();
          _user = null;
          _userData = null;
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        // Save user data to cache
        if (_userData != null) {
          await _saveUserDataToCache(_userData!);
        }
      }
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out method
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _auth.signOut();
      _user = null;
      _userData = null;
      await _clearCachedData();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to sign out';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to send reset email. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Method to refresh user data from server
  Future<void> refreshUserData() async {
    if (_user != null) {
      await _fetchUserData(_user!.uid);
      notifyListeners();
    }
  }

  // Method to check if user is still authenticated and data is valid
  Future<bool> validateSession() async {
    if (_user == null || _userData == null) {
      return false;
    }

    try {
      // Check if user still exists and is active in Firestore
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      
      if (!userDoc.exists) {
        await signOut();
        return false;
      }
      
      final userData = userDoc.data();
      final userRole = userData?['role']?.toString().toLowerCase();
      if ((userRole != 'sales representative' && userRole != 'partner') || userData?['isActive'] != true) {
        await signOut();
        return false;
      }
      
      // Update cached data if needed
      _userData = userData;
      await _saveUserDataToCache(_userData!);
      notifyListeners();
      
      return true;
    } catch (e) {
      // If validation fails due to network issues, assume session is still valid
      // but user should refresh when network is available
      return true;
    }
  }

  // Error message helper
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This user account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication failed. Please try again';
    }
  }
} 