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

  // Ensure an order exists under users/{userId}/Order/{orderId}
  // by syncing it from the admin Order collection when needed.
  Future<void> linkOrderToUser({
    required String userId,
    required String orderId,
    Map<String, dynamic>? fallbackOrderData,
  }) async {
    if (userId.isEmpty || orderId.isEmpty) return;

    Map<String, dynamic>? sourceData = fallbackOrderData;

    if (sourceData == null) {
      final adminOrder = await _firestore.collection('Order').doc(orderId).get();
      if (adminOrder.exists) {
        sourceData = adminOrder.data();
      }
    }

    if (sourceData == null) return;

    sourceData['UserId'] = userId;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('Order')
        .doc(orderId)
        .set(sourceData, SetOptions(merge: true));

    await _firestore
        .collection('Order')
        .doc(orderId)
        .set({'UserId': userId}, SetOptions(merge: true));
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

  // Update order payment information
  Future<void> updateOrderPayment({
    required String orderId,
    required String paymentStatus,
    required String paymentMethod,
    required String paymentProvider,
    required String transactionId,
    required double paidAmount,
    String? userId,
  }) async {
    try {
      final paymentData = {
        'PaymentStatus': paymentStatus,
        'PaymentMethod': paymentMethod,
        'PaymentProvider': paymentProvider,
        'TransactionId': transactionId,
        'PaidAmount': paidAmount.toStringAsFixed(0),
        'UpdatedAt': DateTime.now().toIso8601String(),
      };

      // Update admin order (merge: true ensures it works even if doc doesn't exist fully)
      await FirebaseFirestore.instance
          .collection("Order")
          .doc(orderId)
          .set(paymentData, SetOptions(merge: true));

      // Update user order if userId is provided
      if (userId != null && userId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection("Order")
            .doc(orderId)
            .set(paymentData, SetOptions(merge: true));
      }

      print('Order payment updated successfully');
    } catch (e) {
      print('Error updating order payment: $e');
      rethrow;
    }
  }
}
