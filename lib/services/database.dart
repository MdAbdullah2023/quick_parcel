import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // add user details to Firestore
  Future<void> addUserDetail(
    Map<String, dynamic> userInfoMap,
    String id,
  ) async {
    try {
      await _firestore.collection('users').doc(id).set(userInfoMap);
      print('User data added successfully to Firestore');
    } catch (e) {
      print('Error adding user data: $e');
      rethrow;
    }
  }

  // get user details by ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetail(
    String id,
  ) async {
    try {
      return await _firestore.collection('users').doc(id).get();
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUserByFirebaseUid(
    String firebaseUid,
  ) async {
    try {
      return await _firestore
          .collection('users')
          .where('FirebaseUid', isEqualTo: firebaseUid)
          .limit(1)
          .get();
    } catch (e) {
      print('Error fetching user by FirebaseUid: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUserByEmail(String email) async {
    try {
      return await _firestore
          .collection('users')
          .where('Email', isEqualTo: email)
          .limit(1)
          .get();
    } catch (e) {
      print('Error fetching user by email: $e');
      rethrow;
    }
  }

  // Update user data
  Future<void> updateUserDetail(
    String id,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      await _firestore.collection('users').doc(id).update(updatedData);
      print('User data updated successfully');
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  // Delete user data
  Future<void> deleteUser(String id) async {
    try {
      await _firestore.collection('users').doc(id).delete();
      print('User deleted successfully');
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  Future addUserOrder(
    Map<String, dynamic> userInfoMap,
    String id,
    String orderid,
  ) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("Order")
        .doc(orderid)
        .set(userInfoMap);
  }

  Future addAdminOrder(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("Order")
        .doc(id)
        .set(userInfoMap);
  }

  // Stream of all orders for a user (real-time)
  Stream<QuerySnapshot> getUserOrders(String userId) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Order")
        .orderBy("CreatedAt", descending: true)
        .snapshots();
  }
}
