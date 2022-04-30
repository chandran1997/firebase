// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/firebaseChat/Constant/constants.dart';
import 'package:firebase/firebaseChat/Model/popup_choices.dart';
import 'package:firebase/firebaseChat/Model/user_.chat.dart';
import 'package:firebase/firebaseChat/Provider/auth_provider.dart';
import 'package:firebase/firebaseChat/Utilities/KeyBoardUtils.dart';
import 'package:firebase/firebaseChat/screens/SettingScreen.dart';
import 'package:firebase/firebaseChat/screens/chat_page.dart';
import 'package:firebase/firebaseChat/screens/loginPage.dart';
import 'package:firebase/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../Provider/HomeProvider.dart';
import '../widget/loading_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();
  TextEditingController searchTextEditingController = TextEditingController();
  StreamController<bool> buttonClearController = StreamController<bool>();

  int _limit = 20;
  int _limitIncrement = 20;
  String _textSearch = '';
  bool isLoading = false;

  late String currentUserId;
  late AuthProvider authProvider;
  late HomeProvider homeProvider;

  List<PopupChoices> choices = <PopupChoices>[
    PopupChoices(title: 'Settings', icon: Icons.settings),
    PopupChoices(title: 'Sign out', icon: Icons.exit_to_app),
  ];

  Future<void> handleSignOut() async {
    authProvider.haldleSignOut();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  void scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  //onItem menu press method
  void onItemMenuPress(PopupChoices choice) {
    if (choice.title == 'Sign out') {
      handleSignOut();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsPage(),
        ),
      );
    }
  }

  //popUp menu
  Widget buildPopupMenu() {
    return PopupMenuButton<PopupChoices>(
        icon: const Icon(Icons.more_vert, color: Colors.grey),
        onSelected: onItemMenuPress,
        itemBuilder: (BuildContext context) {
          return choices.map((PopupChoices choice) {
            return PopupMenuItem<PopupChoices>(
              value: choice,
              child: Row(
                children: <Widget>[
                  Icon(
                    choice.icon,
                    color: ColorConstants.primaryColor,
                  ),
                  Container(
                    width: 10,
                  ),
                  Text(
                    choice.title,
                    style: const TextStyle(color: ColorConstants.primaryColor),
                  )
                ],
              ),
            );
          }).toList();
        });
  }

//onBacjPress
  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

//open Dialog box to exit the application
  Future<void> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            backgroundColor: ColorConstants.primaryColor,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Exit Application',
                  style: TextStyle(color: Colors.white),
                ),
                Icon(
                  Icons.exit_to_app,
                  size: 30,
                  color: Colors.white,
                ),
              ],
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            children: [
              const SizedBox(
                height: 10,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  'Are you sure?',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                        child: const Text(
                          'Yes',
                          style: TextStyle(color: Colors.white),
                        ),
                      ))
                ],
              )
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
    }
  }

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    homeProvider = context.read<HomeProvider>();

    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }
    listScrollController.addListener(scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        leading: IconButton(
          icon: Switch(
            value: isWhite,
            onChanged: (value) {
              setState(() {
                isWhite = value;
              });
            },
            activeColor: Colors.white,
            activeTrackColor: Colors.grey,
            inactiveTrackColor: Colors.grey,
            inactiveThumbColor: Colors.black45,
          ),
          onPressed: () => '',
        ),
        actions: [
          buildPopupMenu(),
        ],
      ),
      body: WillPopScope(
        onWillPop: onBackPress,
        child: Stack(
          children: [
            Column(
              children: [
                buildSearchBar(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: homeProvider.getFirestoreData(
                        FirestoreConstants.pathUserCollection,
                        _limit,
                        _textSearch),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasData) {
                        if ((snapshot.data?.docs.length ?? 0) > 0) {
                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) =>
                                builItem(context, snapshot.data?.docs[index]),
                            controller: listScrollController,
                            separatorBuilder:
                                (BuildContext context, int index) {
                              return const Divider();
                            },
                          );
                        } else {
                          return const Center(
                            child: Text('No User found...'),
                          );
                        }
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                ),
                Positioned(
                    child: isLoading
                        ? const LoadingView()
                        : const SizedBox.shrink())
              ],
            )
          ],
        ),
      ),
    );
  }

  //buildSearchBar
  Widget buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 10,
          ),
          const Icon(
            Icons.person_search,
            size: 24,
            color: ColorConstants.primaryColor,
          ),
          const SizedBox(
            width: 5,
          ),
          Expanded(
            child: TextFormField(
              textInputAction: TextInputAction.search,
              controller: searchTextEditingController,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  buttonClearController.add(true);
                  setState(() {
                    _textSearch = value;
                  });
                } else {
                  buttonClearController.add(false);
                  setState(() {
                    _textSearch = '';
                  });
                }
              },
              decoration: const InputDecoration.collapsed(
                  hintText: 'Search here...',
                  hintStyle: TextStyle(color: ColorConstants.greyColor)),
            ),
          ),
          StreamBuilder(
              stream: buttonClearController.stream,
              builder: (context, snapshot) {
                return snapshot.data == true
                    ? GestureDetector(
                        onTap: (() {
                          searchTextEditingController.clear();
                          buttonClearController.add(false);
                          setState(() {
                            _textSearch = '';
                          });
                        }),
                        child: const Icon(
                          Icons.clear_rounded,
                          size: 20,
                          color: ColorConstants.greyColor,
                        ),
                      )
                    : const SizedBox.shrink();
              }),
        ],
      ),
    );
  }

  //builItem
  Widget builItem(BuildContext context, DocumentSnapshot? documentSnapshot) {
    final firebaseAuth = FirebaseAuth.instance;
    if (documentSnapshot != null) {
      UserChat userChat = UserChat.fromDocument(documentSnapshot);
      if (userChat.id == currentUserId) {
        return const SizedBox.shrink();
      } else {
        return TextButton(
          onPressed: () {
            if (KeyboardUtils.isKeyboardShowing()) {
              KeyboardUtils.closeKeyboard(context);
            }
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatPage(
                        peerId: userChat.id,
                        peerAvatar: userChat.photoUrl,
                        peerNickName: userChat.nickname,
                        userAvatar: firebaseAuth.currentUser!.photoURL!)));
          },
          child: ListTile(
            leading: userChat.photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      userChat.photoUrl,
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgras) {
                        if (loadingProgras == null) {
                          return child;
                        } else {
                          return SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              color: Colors.grey,
                              value: loadingProgras.expectedTotalBytes != null
                                  ? loadingProgras.cumulativeBytesLoaded /
                                      loadingProgras.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        }
                      },
                      errorBuilder: (context, object, stackTrace) {
                        return const Icon(
                          Icons.account_circle,
                          size: 50,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.account_circle_rounded,
                    size: 50,
                  ),
            title: Text(
              userChat.nickname,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }
}
