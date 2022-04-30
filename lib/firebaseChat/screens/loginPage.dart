import 'package:firebase/firebaseChat/Provider/auth_provider.dart';
import 'package:firebase/firebaseChat/screens/homePage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../widget/loading_view.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);

    switch (authProvider.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: 'Sign in failed');
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: 'Sign in Canceled');
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: 'Sign in Sucess');
        break;
      default:
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
              padding: const EdgeInsets.all(20),
              child: Image.asset('assets/pic2.png')),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: (() async {
                bool isSucess = await authProvider.handleSignIn();
                if (isSucess) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const HomePage()));
                }
              }),
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/google_pic.jpg'),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            child: authProvider.status == Status.authenticating
                ? const LoadingView()
                : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }
}
