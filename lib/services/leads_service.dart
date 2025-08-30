import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/lead_model.dart';
import 'package:intl/intl.dart';

class LeadsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Get leads filtered by referral code
  Future<List<Lead>> getLeads({
    String? searchQuery,
    String? statusFilter,
    String? districtFilter,
    String? stateFilter,
    String? referralCode, // Add referral code filter
  }) async {
    try {
      print('📋 Fetching leads for referral code: $referralCode');
      print('🔍 Parameters: status=$statusFilter, district=$districtFilter, state=$stateFilter, search=$searchQuery');
      
        // If no referral code provided, return empty list
      if (referralCode == null || referralCode.isEmpty) {
        print('⚠️ No referral code provided, returning empty list');
        return [];
      }
      
      // Create two separate queries to handle two-level referral system
      // Query 1: Direct referrals (referralCode field)
      Query query1 = _firestore.collection('creditRequests')
          .where('referralCode', isEqualTo: referralCode);
      
      // Query 2: Indirect referrals (referralCode1 field)
      Query query2 = _firestore.collection('creditRequests')
          .where('referralCode1', isEqualTo: referralCode);
      
      // Apply status filter
      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'All') {
        query1 = query1.where('status', isEqualTo: statusFilter);
        query2 = query2.where('status', isEqualTo: statusFilter);
        print('🔍 Filtering by status: $statusFilter');
      }
      
      // Apply district filter
      if (districtFilter != null && districtFilter.isNotEmpty && districtFilter != 'All') {
        query1 = query1.where('district', isEqualTo: districtFilter);
        query2 = query2.where('district', isEqualTo: districtFilter);
        print('🔍 Filtering by district: $districtFilter');
      }
      
      // Apply state filter
      if (stateFilter != null && stateFilter.isNotEmpty && stateFilter != 'All') {
        query1 = query1.where('state', isEqualTo: stateFilter);
        query2 = query2.where('state', isEqualTo: stateFilter);
        print('🔍 Filtering by state: $stateFilter');
      }
      
      print('🔄 Executing Firestore queries...');
      
      // Execute both queries in parallel
      final results = await Future.wait([
        query1.get(),
        query2.get(),
      ]);
      
      final directReferralsSnapshot = results[0];
      final indirectReferralsSnapshot = results[1];
      
      print('📊 Direct referrals found: ${directReferralsSnapshot.docs.length}');
      print('📊 Indirect referrals found: ${indirectReferralsSnapshot.docs.length}');
      
      // Combine results and remove duplicates
      final allLeadDocs = <String, QueryDocumentSnapshot>{};
      
      // Add direct referrals
      for (final doc in directReferralsSnapshot.docs) {
        allLeadDocs[doc.id] = doc;
      }
      
      // Add indirect referrals (will overwrite if duplicate, but that's fine)
      for (final doc in indirectReferralsSnapshot.docs) {
        allLeadDocs[doc.id] = doc;
      }
      
      print('📊 Total unique leads: ${allLeadDocs.length}');
      
      if (allLeadDocs.isEmpty) {
        print('⚠️ No documents found in creditRequests collection');
        return [];
      }
      
      // Debug: Print first document structure
      if (allLeadDocs.isNotEmpty) {
        final firstDoc = allLeadDocs.values.first;
        print('📄 First document ID: ${firstDoc.id}');
        print('📄 First document data: ${firstDoc.data()}');
      }
      
      List<Lead> leads = [];
      for (var doc in allLeadDocs.values) {
        try {
          final lead = Lead.fromFirestore(doc);
          leads.add(lead);
          print('✅ Successfully parsed lead: ${lead.fullName} (${lead.customerId})');
        } catch (e) {
          print('❌ Error parsing document ${doc.id}: $e');
          print('📄 Document data: ${doc.data()}');
        }
      }
      
      print('📋 Successfully parsed ${leads.length} leads from ${allLeadDocs.length} documents');
      
      // Apply search filter locally (since Firestore doesn't support text search)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        print('🔍 Applying search filter: $searchQuery');
          final searchLower = searchQuery.toLowerCase();
        final beforeCount = leads.length;
        leads = leads.where((lead) {
          return lead.fullName.toLowerCase().contains(searchLower) ||
                 lead.customerId.toLowerCase().contains(searchLower) ||
                 lead.mobile.contains(searchQuery) ||
                 lead.aadhar.contains(searchQuery) ||
                 lead.district.toLowerCase().contains(searchLower) ||
                 lead.state.toLowerCase().contains(searchLower);
        }).toList();
        print('🔍 Search filter reduced leads from $beforeCount to ${leads.length}');
      }
      
      // Sort by creation date (newest first)
      leads.sort((a, b) {
        final dateA = a.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      
      print('📋 Returning ${leads.length} leads with two-level referral filtering');
      return leads;
    } catch (e) {
      print('❌ Error fetching leads: $e');
      return [];
    }
  }

  // Update lead status - DISABLED for read-only access
  Future<bool> updateLeadStatus(String leadId, String newStatus, {String? remark}) async {
    print('🚫 Lead status updates are disabled for this user role');
    return false;
    
    /* DISABLED FOR READ-ONLY ACCESS
    try {
      print('🔄 Updating lead $leadId status to $newStatus');
      
      final updateData = {
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (remark != null && remark.isNotEmpty) {
        updateData['remark'] = remark;
      }
      
      await _firestore.collection('creditRequests').doc(leadId).update(updateData);
      
      print('✅ Lead status updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating lead status: $e');
      return false;
    }
    */
  }

  // Convert lead to customer - DISABLED for read-only access
  Future<bool> convertLeadToCustomer(String leadId) async {
    print('🚫 Lead conversion is disabled for this user role');
    return false;
    
    /* DISABLED FOR READ-ONLY ACCESS
    try {
      print('🔄 Converting lead $leadId to customer via Cloud Function...');
      
      // Get the lead data
      final leadDoc = await _firestore.collection('creditRequests').doc(leadId).get();
      if (!leadDoc.exists) {
        print('❌ Lead not found');
        return false;
      }
      
      final lead = Lead.fromFirestore(leadDoc);
      
      // Generate email and password
      final email = _generateEmailFromCustomerId(lead.customerId);
      final password = _generatePasswordFromDob(lead.dob);
      
      // Prepare data for Cloud Function
      final userData = {
        'fullName': lead.fullName,
        'mobile': lead.mobile,
        'customerId': lead.customerId,
      };
      
      final leadData = {
        ...lead.toMap(),
        'leadId': leadId,
      };
      
      // Call Cloud Function
      final HttpsCallable callable = _functions.httpsCallable('createCustomerUser');
      final result = await callable.call({
        'email': email,
        'password': password,
        'userData': userData,
        'leadData': leadData,
      });
      
      if (result.data['success'] == true) {
        print('✅ Lead successfully converted to customer via Cloud Function');
      print('📧 Customer email: $email');
      print('🔐 Customer password: $password');
        print('👤 Firebase UID: ${result.data['userId']}');
      return true;
      } else {
        print('❌ Cloud Function returned error: ${result.data['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Error converting lead to customer: $e');
      return false;
    }
    */
  }

  // Get lead statistics for current user's referred leads
  Future<Map<String, int>> getLeadStats({String? referralCode}) async {
    try {
      print('📊 Fetching lead stats for referral code: $referralCode');
      
      Query query = _firestore.collection('creditRequests');
      
      // If referral code is provided, filter by it (for partners/sales reps)
      if (referralCode != null && referralCode.isNotEmpty) {
        query = query.where('referralCode', isEqualTo: referralCode);
      }
      
      final snapshot = await query.get();
      final leads = snapshot.docs.map((doc) => Lead.fromFirestore(doc)).toList();
      
      final stats = <String, int>{};
      
      // Calculate stats for each status
      for (final status in LeadStatus.values) {
        stats[status.value] = leads.where((lead) => lead.status == status.value).length;
      }
      
      stats['total'] = leads.length;
      
      print('📊 Stats calculated: $stats');
      return stats;
    } catch (e) {
      print('❌ Error fetching lead stats: $e');
      // Return empty stats instead of throwing error
      return {
        'total': 0,
        'NEW': 0,
        'CONTACTED': 0,
        'INTERESTED': 0,
        'NOT INTERESTED': 0,
        'NO RESPONSE': 0,
        'CONVERTED TO CUSTOMER': 0,
      };
    }
  }

  // Generate email from customer ID
  String _generateEmailFromCustomerId(String customerId) {
    return '${customerId.toLowerCase()}@futurecapital.com';
  }

  // Generate password from DOB (ddmmyyyy format)
  String _generatePasswordFromDob(String dob) {
    try {
      final date = DateTime.parse(dob);
      return DateFormat('ddMMyyyy').format(date);
    } catch (e) {
      // Fallback to a default pattern if parsing fails
      return 'fc${DateTime.now().year}';
    }
  }

  // Add remark to lead
  Future<bool> addRemarkToLead(String leadId, String remark) async {
    try {
      await _firestore.collection('creditRequests').doc(leadId).update({
        'remark': remark,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('❌ Error adding remark: $e');
      return false;
    }
  }

  // Mark lead as seen
  Future<bool> markLeadAsSeen(String leadId) async {
    try {
      await _firestore.collection('creditRequests').doc(leadId).update({
        'isSeen': true,
        'seenAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('❌ Error marking lead as seen: $e');
      return false;
    }
  }

  // Get lead by ID
  Future<Lead?> getLeadById(String leadId) async {
    try {
      final doc = await _firestore.collection('creditRequests').doc(leadId).get();
      if (doc.exists) {
        return Lead.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching lead: $e');
      return null;
    }
  }

  // Create new lead
  Future<bool> createLead(Map<String, dynamic> leadData) async {
    try {
      print('🔄 Creating new lead...');
      print('📊 Lead data summary:');
      print('  - Customer ID: ${leadData['customerId']}');
      print('  - Full Name: ${leadData['fullName']}');
      print('  - Mobile: ${leadData['mobile']}');
      print('  - Status: ${leadData['status']}');
      print('  - Documents: ${leadData['documents']?.keys?.toList() ?? 'None'}');
      print('  - Referral Code: ${leadData['referralCode']}');
      print('  - Data keys: ${leadData.keys.toList()}');
      
      // Verify required fields
      final requiredFields = ['customerId', 'fullName', 'mobile', 'status'];
      for (final field in requiredFields) {
        if (leadData[field] == null || leadData[field].toString().isEmpty) {
          print('❌ Missing required field: $field');
          return false;
        }
      }
      
      // Add the lead to Firestore
      final docRef = await _firestore.collection('creditRequests').add(leadData);
      
      print('✅ Lead created successfully with document ID: ${docRef.id}');
      
      // Verify the lead was actually saved
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        print('✅ Lead verification: Document exists in database');
        print('📄 Saved data customer ID: ${savedDoc.data()?['customerId']}');
      return true;
      } else {
        print('❌ Lead verification failed: Document not found in database');
        return false;
      }
    } catch (e) {
      print('❌ Error creating lead: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }
} 