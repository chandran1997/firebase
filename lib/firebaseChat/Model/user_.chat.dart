import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/firebaseChat/Constant/constants.dart';

class UserChat {
  String id;
  String photoUrl;
  String nickname;
  String aboutMe;
  String phoneNumber;
  UserChat({
    required this.id,
    required this.photoUrl,
    required this.nickname,
    required this.aboutMe,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.nickname: nickname,
      FirestoreConstants.aboutMe: aboutMe,
      FirestoreConstants.photoUrl: photoUrl,
      FirestoreConstants.phoneNumber: phoneNumber,
    };
  }

  factory UserChat.fromDocument(DocumentSnapshot doc) {
    String aboutMe = '';
    String photoUrl = '';
    String nickname = '';
    String phoneNumber = '';

    try {
      aboutMe = doc.get(FirestoreConstants.aboutMe);
    } catch (e) {}
    try {
      photoUrl = doc.get(FirestoreConstants.photoUrl);
    } catch (e) {}
    try {
      nickname = doc.get(FirestoreConstants.nickname);
    } catch (e) {}
    try {
      phoneNumber = doc.get(FirestoreConstants.phoneNumber);
    } catch (e) {}
    return UserChat(
      id: doc.id,
      aboutMe: aboutMe,
      nickname: nickname,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
    );
  }
}
