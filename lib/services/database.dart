// lib/services/database.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Add user details to Firestore
  Future<void> addUserDetail(
    Map<String, dynamic> userInfoMap,
    String id,
  ) async {
    try {
      await _firestore.collection('users').doc(id).set(userInfoMap);
      print('✅ User data added successfully to Firestore');
    } catch (e) {
      print('❌ Error adding user data: $e');
      rethrow;
    }
  }

  // 🔹 Get user details by ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetail(
    String id,
  ) async {
    try {
      return await _firestore.collection('users').doc(id).get();
    } catch (e) {
      print('❌ Error fetching user data: $e');
      rethrow;
    }
  }

  // 🔹 Update user data (for example, profile edit)
  Future<void> updateUserDetail(
    String id,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      await _firestore.collection('users').doc(id).update(updatedData);
      print('✅ User data updated successfully');
    } catch (e) {
      print('❌ Error updating user data: $e');
      rethrow;
    }
  }

  // 🔹 Delete user data
  Future<void> deleteUser(String id) async {
    try {
      await _firestore.collection('users').doc(id).delete();
      print('✅ User deleted successfully');
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    }
  }
}
