import 'package:cloud_firestore/cloud_firestore.dart';

import '../Constant/firebase_constants.dart';

class HomeProvider {
  final FirebaseFirestore firebaseFirestore;
  HomeProvider({
    required this.firebaseFirestore,
  });

  Future<void> updateFireStoreData(
      String collectionPath, String path, Map<String, dynamic> updateData) {
    return firebaseFirestore
        .collection(collectionPath)
        .doc(path)
        .update(updateData);
  }

  //To receive a snapshot of data from the Cloud Firestore database:

  Stream<QuerySnapshot> getFirestoreData(
    String collectionPath,
    int limit,
    String? textsearch,
  ) {
    if (textsearch?.isNotEmpty == true) {
      return firebaseFirestore
          .collection(collectionPath)
          .limit(limit)
          .where(FirestoreConstants.nickname, isEqualTo: textsearch)
          .snapshots();
    } else {
      return firebaseFirestore
          .collection(collectionPath)
          .limit(limit)
          .snapshots();
    }
  }
}
