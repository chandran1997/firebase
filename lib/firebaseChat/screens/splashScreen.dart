import 'package:firebase/firebaseChat/Constant/color_constsnts.dart';
import 'package:firebase/firebaseChat/Provider/auth_provider.dart';
import 'package:firebase/firebaseChat/screens/homePage.dart';
import 'package:firebase/firebaseChat/screens/loginPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      checkSignedIn();
    });
  }

  void checkSignedIn() async {
    AuthProvider authProvider = context.read<AuthProvider>();
    bool isloggedIn = await authProvider.isLoggedIn();
    if (isloggedIn) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const HomePage()));
      return;
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/pic1.png',
              width: 300,
              height: 300,
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              'World Best Chat App',
              style: TextStyle(color: ColorConstants.themeColor),
            ),
            const SizedBox(
              height: 10,
            ),
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: ColorConstants.themeColor,
              ),
            )
          ],
        ),
      ),
    );
  }
}
