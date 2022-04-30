import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase/firebaseChat/Constant/color_constsnts.dart';
import 'package:firebase/firebaseChat/Constant/constants.dart';
import 'package:firebase/firebaseChat/Model/user_.chat.dart';
import 'package:firebase/firebaseChat/Provider/setting_provider.dart';
import 'package:firebase/firebaseChat/widget/loading_view.dart';
import 'package:firebase/main.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:provider/provider.dart';

import '../Constant/firebase_constants.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        iconTheme: const IconThemeData(color: ColorConstants.primaryColor),
        title: const Text(
          'Settings',
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: SettingsPage(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController? controllerNickName;
  TextEditingController? controllerAboutMe;

  String dialCodeDigit = '+00';
  final TextEditingController controller = TextEditingController();

  String id = '';
  String nickName = '';
  String aboutMe = '';
  String photoUrl = '';
  String phoneNumber = '';

  bool isloading = false;
  File? avatarImageFile;
  late SettingProvider settingProvider;

  final FocusNode focusNodeNickName = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    settingProvider = context.read<SettingProvider>();
    readLocal();
  }

  void readLocal() {
    setState(() {
      id = settingProvider.getPref(FirestoreConstants.id) ?? '';
      nickName = settingProvider.getPref(FirestoreConstants.nickname) ?? '';
      aboutMe = settingProvider.getPref(FirestoreConstants.aboutMe) ?? '';
      photoUrl = settingProvider.getPref(FirestoreConstants.photoUrl) ?? '';
      phoneNumber =
          settingProvider.getPref(FirestoreConstants.phoneNumber) ?? '';
    });
    controllerNickName = TextEditingController(text: nickName);
    controllerAboutMe = TextEditingController(text: aboutMe);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile? pickedFile =
        // ignore: deprecated_member_use
        await imagePicker.getImage(source: ImageSource.gallery).catchError((e) {
      Fluttertoast.showToast(msg: e.toString());
    });
    File? image;
    if (pickedFile != null) {
      image = File(pickedFile.path);
    }
    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isloading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = id;
    UploadTask uploadTask =
        settingProvider.uploadFile(avatarImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();

      UserChat updateInfo = UserChat(
          id: id,
          photoUrl: photoUrl,
          nickname: nickName,
          aboutMe: aboutMe,
          phoneNumber: phoneNumber);

      settingProvider
          .updateDataFirestore(
              FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
          .then((data) async {
        await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
        setState(() {
          isloading = false;
        });
      }).catchError((e) {
        setState(() {
          isloading = false;
        });
        Fluttertoast.showToast(msg: e.toString());
      });
    } on FirebaseException catch (e) {
      setState(() {
        isloading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void handleUpdateData() {
    focusNodeNickName.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isloading = true;

      if (dialCodeDigit != '+00' && controller.text != '') {
        phoneNumber = dialCodeDigit + controller.text.toString();
      }
    });

    UserChat updateInfo = UserChat(
        id: id,
        photoUrl: photoUrl,
        nickname: nickName,
        aboutMe: aboutMe,
        phoneNumber: phoneNumber);
    settingProvider
        .updateDataFirestore(
            FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
        .then((data) async {
      await settingProvider.setPref(FirestoreConstants.nickname, nickName);
      await settingProvider.setPref(FirestoreConstants.aboutMe, aboutMe);
      await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
      await settingProvider.setPref(
          FirestoreConstants.phoneNumber, phoneNumber);
      setState(() {
        isloading = false;
      });
      Fluttertoast.showToast(msg: 'Update success');
    }).catchError((e) {
      setState(() {
        isloading = false;
      });
      Fluttertoast.showToast(msg: e.toString());
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoButton(
                    onPressed: getImage,
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      child: avatarImageFile == null
                          ? photoUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(45),
                                  child: Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    width: 90,
                                    height: 90,
                                    errorBuilder:
                                        (context, object, stackTrace) {
                                      return const Icon(
                                        Icons.account_box,
                                        size: 90,
                                        color: ColorConstants.greyColor,
                                      );
                                    },
                                    loadingBuilder: (BuildContext context,
                                        Widget child,
                                        ImageChunkEvent? loadingPrograss) {
                                      if (loadingPrograss == null) {
                                        return child;
                                      } else {
                                        return SizedBox(
                                          width: 90,
                                          height: 90,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                                color: Colors.grey,
                                                value: loadingPrograss
                                                                .expectedTotalBytes !=
                                                            null &&
                                                        loadingPrograss
                                                                .expectedTotalBytes !=
                                                            null
                                                    ? loadingPrograss
                                                            .cumulativeBytesLoaded /
                                                        loadingPrograss
                                                            .expectedTotalBytes!
                                                    : null),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.account_box,
                                  size: 90,
                                  color: ColorConstants.greyColor,
                                )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(45),
                              child: Image.file(
                                avatarImageFile!,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: const Text(
                          'Name',
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.primaryColor),
                        ),
                        margin:
                            const EdgeInsets.only(left: 10, bottom: 5, top: 10),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 30, right: 30),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                              primaryColor: ColorConstants.primaryColor),
                          child: TextField(
                            style: const TextStyle(color: Colors.grey),
                            decoration: const InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: ColorConstants.greyColor2),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: ColorConstants.greyColor),
                                ),
                                hintText: 'Write your name...',
                                contentPadding: EdgeInsets.all(5),
                                hintStyle:
                                    TextStyle(color: ColorConstants.greyColor)),
                            controller: controllerNickName,
                            onChanged: (value) {
                              nickName = value;
                            },
                            focusNode: focusNodeNickName,
                          ),
                        ),
                      ),
                      Container(
                        child: const Text(
                          'About Me',
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.primaryColor),
                        ),
                        margin:
                            const EdgeInsets.only(left: 10, bottom: 5, top: 10),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 30, right: 30),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                              primaryColor: ColorConstants.primaryColor),
                          child: TextField(
                            style: const TextStyle(color: Colors.grey),
                            decoration: const InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: ColorConstants.greyColor2),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: ColorConstants.greyColor),
                                ),
                                hintText: 'Write something About yourself...',
                                contentPadding: EdgeInsets.all(5),
                                hintStyle:
                                    TextStyle(color: ColorConstants.greyColor)),
                            controller: controllerAboutMe,
                            onChanged: (value) {
                              aboutMe = value;
                            },
                            focusNode: focusNodeAboutMe,
                          ),
                        ),
                      ),
                      // Container(
                      //   child: const Text(
                      //     'Phone Number',
                      //     style: TextStyle(
                      //         fontStyle: FontStyle.italic,
                      //         fontWeight: FontWeight.bold,
                      //         color: ColorConstants.primaryColor),
                      //   ),
                      //   margin:
                      //       const EdgeInsets.only(left: 10, bottom: 5, top: 10),
                      // ),
                      // Container(
                      //   margin: const EdgeInsets.only(left: 30, right: 30),
                      //   child: Theme(
                      //     data: Theme.of(context).copyWith(
                      //         primaryColor: ColorConstants.primaryColor),
                      //     child: TextField(
                      //       style: const TextStyle(color: Colors.grey),
                      //       decoration: InputDecoration(
                      //           hintText: phoneNumber,
                      //           contentPadding: const EdgeInsets.all(5),
                      //           hintStyle: const TextStyle(
                      //               color: ColorConstants.greyColor)),
                      //       // controller: controllerNickName,
                      //       // onChanged: (value) {
                      //       //   nickName = value;
                      //       // },
                      //       // focusNode: focusNodeAboutMe,
                      //     ),
                      //   ),
                      // ),
                      Container(
                        margin:
                            const EdgeInsets.only(left: 10, top: 30, bottom: 5),
                        child: SizedBox(
                          width: 400,
                          height: 60,
                          child: CountryCodePicker(
                            onChanged: (value) {
                              dialCodeDigit = value.dialCode!;
                            },
                            initialSelection: 'IT',
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            favorite: const ['+1', 'US', '+92', 'PAX'],
                          ),
                        ),
                      ),
                      Container(
                        margin:
                            const EdgeInsets.only(left: 10, top: 30, bottom: 5),
                        child: TextField(
                          style: const TextStyle(color: Colors.grey),
                          decoration: InputDecoration(
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: ColorConstants.greyColor2),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: ColorConstants.greyColor),
                              ),
                              hintText: 'Phone Number',
                              prefix: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  dialCodeDigit,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                              hintStyle: const TextStyle(
                                  color: ColorConstants.greyColor)),
                          maxLength: 12,
                          keyboardType: TextInputType.number,
                          controller: controller,
                        ),
                      ),
                      Container(
                          margin: const EdgeInsets.only(top: 50, bottom: 50),
                          child: TextButton(
                            onPressed: (() {
                              handleUpdateData();
                            }),
                            child: const Text(
                              'Update Now',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        ColorConstants.primaryColor),
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.fromLTRB(30, 10, 30, 10),
                                )),
                          ))
                    ],
                  )
                ],
              ),
            ),
          ),
          Positioned(
              child: isloading ? const LoadingView() : const SizedBox.shrink())
        ],
      ),
    );
  }
}
