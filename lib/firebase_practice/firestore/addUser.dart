import 'dart:ffi';

import 'package:flutter/material.dart';

// Import the firebase_core and cloud_firestore plugin
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddUser extends StatelessWidget {
  final String fullName;
  final String company;
  final int age;

  AddUser(this.fullName, this.company, this.age);

  @override
  Widget build(BuildContext context) {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    Future<void> addUser() async {
      return users.add(
          {'fullName': fullName, 'company': company, 'age': age}).then((value) {
        print('user Addded');
      }).catchError((error) {
        print('Failed to add user: $error');
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Cloud FireStore'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: addUser,
          child: Text('Add User'),
        ),
      ),
    );
    // Create a CollectionReference called users that references the firestore collection
  }
}
