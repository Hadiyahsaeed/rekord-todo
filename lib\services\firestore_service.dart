import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTasks(String userId, String userEmail) {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<void> addTask({
    required String userId,
    required String title,
    required String description,
    required String priority,
    required String tagText,
    required int tagColorHex,
    required int taskColorHex,
    required List<String> collaborators,
    DateTime? dueDate,
    String? dueTime,
    String? endTime,
  }) async {
    await _db.collection('tasks').add({
      'userId': userId,
      'title': title,
      'description': description,
      'priority': priority,
      'tagText': tagText,
      'tagColorHex': tagColorHex,
      'taskColorHex': taskColorHex,
      'collaborators': collaborators,
      'isCompleted': false,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'dueTime': dueTime,
      'endTime': endTime, 
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 🚀 NEW: Update an existing task document
  Future<void> updateTask({
    required String docId,
    required String title,
    required String description,
    required String priority,
    required String tagText,
    required int tagColorHex,
    required int taskColorHex,
    required List<String> collaborators,
    DateTime? dueDate,
    String? dueTime,
    String? endTime,
  }) async {
    await _db.collection('tasks').doc(docId).update({
      'title': title,
      'description': description,
      'priority': priority,
      'tagText': tagText,
      'tagColorHex': tagColorHex,
      'taskColorHex': taskColorHex,
      'collaborators': collaborators,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'dueTime': dueTime,
      'endTime': endTime,
    });
  }

  Future<void> toggleTaskStatus(String docId, bool currentStatus) async {
    await _db.collection('tasks').doc(docId).update({'isCompleted': !currentStatus});
  }

  Future<void> deleteTask(String docId) async {
    await _db.collection('tasks').doc(docId).delete();
  }

  Stream<DocumentSnapshot> getUserProfile(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }
}