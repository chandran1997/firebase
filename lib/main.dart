import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/firebaseChat/Constant/app_constant.dart';
import 'package:firebase/firebaseChat/Provider/setting_provider.dart';
import 'package:firebase/firebaseChat/screens/splashScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebaseChat/Provider/HomeProvider.dart';
import 'firebaseChat/Provider/auth_provider.dart';
import 'firebaseChat/Provider/chatProvider.dart';

bool isWhite = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  MyApp({
    Key? key,
    required this.prefs,
  }) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            firebaseAuth: FirebaseAuth.instance,
            googleSignIn: GoogleSignIn(),
            prefs: prefs,
            firebaseFirestore: firebaseFirestore,
          ),
        ),
        Provider<SettingProvider>(
            create: (_) => SettingProvider(
                prefs: prefs,
                firebaseFirestore: firebaseFirestore,
                firebaseStorage: firebaseStorage)),
        Provider<HomeProvider>(
            create: (_) => HomeProvider(firebaseFirestore: firebaseFirestore)),
        Provider<ChatProvider>(
            create: (_) => ChatProvider(
                firebaseStorage: firebaseStorage,
                firebaseFirestore: firebaseFirestore,
                prefs: prefs))
      ],
      child: const MaterialApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}
