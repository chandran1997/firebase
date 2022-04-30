import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/firebaseChat/Constant/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase/firebaseChat/Constant/firebase_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Model/user_.chat.dart';

enum Status {
  uninitialized,
  authenticated,
  authenticating,
  authenticateError,
  authenticateCanceled
}

class AuthProvider extends ChangeNotifier {
  final GoogleSignIn googleSignIn;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences prefs;

  AuthProvider({
    required this.googleSignIn,
    required this.firebaseAuth,
    required this.firebaseFirestore,
    required this.prefs,
  });

  Status _status = Status.uninitialized;
  Status get status => _status;

  String? getUserFirebaseId() {
    return prefs.getString(FirestoreConstants.id);
  }

  Future<bool> isLoggedIn() async {
    bool isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn &&
        prefs.getString(FirestoreConstants.id)!.isNotEmpty == true) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> handleSignIn() async {
    _status = Status.authenticating;
    notifyListeners();

    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

      User? firebaseuser =
          (await firebaseAuth.signInWithCredential(credential)).user;

      if (firebaseuser != null) {
        final QuerySnapshot result = await firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .where(FirestoreConstants.id, isEqualTo: firebaseuser.uid)
            .get();
        final List<DocumentSnapshot> document = result.docs;
        if (document.isEmpty) {
          firebaseFirestore
              .collection(FirestoreConstants.pathUserCollection)
              .doc(firebaseuser.uid)
              .set({
            FirestoreConstants.nickname: firebaseuser.displayName,
            FirestoreConstants.photoUrl: firebaseuser.photoURL,
            FirestoreConstants.id: firebaseuser.uid,
            'createdAt': DateTime.now().microsecondsSinceEpoch.toString(),
            FirestoreConstants.chattingWith: null
          });

          User? currentUser = firebaseuser;
          await prefs.setString(FirestoreConstants.id, currentUser.uid);
          await prefs.setString(
              FirestoreConstants.nickname, currentUser.displayName ?? '');
          await prefs.setString(
              FirestoreConstants.photoUrl, currentUser.photoURL ?? '');
          await prefs.setString(
              FirestoreConstants.phoneNumber, currentUser.phoneNumber ?? '');
        } else {
          DocumentSnapshot documentSnapshot = document[0];
          UserChat userChat = UserChat.fromDocument(documentSnapshot);

          await prefs.setString(FirestoreConstants.id, userChat.id);
          await prefs.setString(FirestoreConstants.nickname, userChat.nickname);
          await prefs.setString(FirestoreConstants.photoUrl, userChat.photoUrl);
          await prefs.setString(FirestoreConstants.aboutMe, userChat.aboutMe);
          await prefs.setString(
              FirestoreConstants.phoneNumber, userChat.phoneNumber);
        }
        _status = Status.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }
    } else {
      _status = Status.authenticateCanceled;
      notifyListeners();
      return false;
    }
  }

  Future<void> haldleSignOut() async {
    _status = Status.uninitialized;
    await firebaseAuth.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
  }
}
