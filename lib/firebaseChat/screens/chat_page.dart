import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/firebaseChat/Constant/constants.dart';
import 'package:firebase/firebaseChat/Model/chatMesssage.dart';
import 'package:firebase/firebaseChat/Provider/auth_provider.dart';
import 'package:firebase/firebaseChat/Provider/chatProvider.dart';
import 'package:firebase/firebaseChat/Provider/setting_provider.dart';
import 'package:firebase/firebaseChat/screens/loginPage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../Constant/textField_constant.dart';
import '../widget/allWidgets.dart';

class ChatPage extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String peerNickName;
  final String userAvatar;
  const ChatPage({
    Key? key,
    required this.peerId,
    required this.peerAvatar,
    required this.peerNickName,
    required this.userAvatar,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late String currenUderId;

  List<QueryDocumentSnapshot> listMessage = [];

  int _limit = 20;
  final int _limitIncrement = 20;

  String groupChatId = '';
  String imageUrl = '';

  File? imageFile;
  bool isShowSticker = false;
  bool isLoading = false;

  final TextEditingController textEditingController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  late AuthProvider authProvider;
  late ChatProvider chatProvider;

  @override
  void initState() {
    super.initState();
    chatProvider = context.read<ChatProvider>();
    authProvider = context.read<AuthProvider>();

    focusNode.addListener(onFocusChanged);
    scrollController.addListener(_scrollListener);
    readLocal();
  }

  _scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onFocusChanged() {
    if (focusNode.hasFocus) {
      setState(() {
        isShowSticker = false;
      });
    }
  }

  readLocal() {
    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currenUderId = authProvider.getUserFirebaseId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false);
    }
    if (currenUderId.compareTo(widget.peerId) > 0) {
      groupChatId = '$currenUderId - ${widget.peerId}';
    } else {
      groupChatId = '${widget.peerId} - $currenUderId';
    }
    chatProvider.updateFirestoreData(FirestoreConstants.pathUserCollection,
        currenUderId, {FirestoreConstants.chattingWith: widget.peerId});
  }

  //get the image
  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile;
    pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadImageFile();
      }
    }
  }

  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future<bool> onBackPressed() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      chatProvider.updateFirestoreData(FirestoreConstants.pathUserCollection,
          currenUderId, {FirestoreConstants.chattingWith: null});
    }
    return Future.value(false);
  }

  //upload Image
  void uploadImageFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadImageFile(imageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, MessageType.image);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  //call Phone number metod (appbar)
  void callPhoneNumber(String phoneNumber) async {
    var url = 'tel://$phoneNumber';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Error Occurred';
    }
  }

  //Message Send Function
  bool isMessageSend(int index) {
    if ((index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) !=
                currenUderId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  //Message recived
  bool isMessageReceived(int index) {
    if ((index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) ==
                currenUderId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  //send Message textfield
  void onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      textEditingController.clear();
      chatProvider.sendChatMessage(
          content, type, groupChatId, currenUderId, widget.peerId);
      // scrollController.animateTo(0,
      //     duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
          msg: 'Nothing To Send', backgroundColor: ColorConstants.greyColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatting with ${widget.peerNickName}'.trim()),
        actions: [
          IconButton(
            onPressed: () {
              SettingProvider settingProvider;
              settingProvider = context.read<SettingProvider>();
              String callPhoneNumberString =
                  settingProvider.getPref(FirestoreConstants.phoneNumber) ?? '';
              callPhoneNumber(callPhoneNumberString);
            },
            icon: const Icon(Icons.phone),
          )
        ],
      ),
      body: SafeArea(
          child: Column(
        children: [
          // buildListMessage(),
          // buildMessageInput(),
        ],
      )),
    );
  }

  Widget buildListMessage() {
    return Flexible(
        child: groupChatId.isNotEmpty
            ? StreamBuilder<QuerySnapshot>(
                stream: chatProvider.getChatMessage(groupChatId, _limit),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasData) {
                    listMessage = snapshot.data!.docs;
                    if (listMessage.isNotEmpty) {
                      return ListView.builder(
                        itemCount: snapshot.data?.docs.length,
                        reverse: true,
                        controller: scrollController,
                        itemBuilder: (context, index) =>
                            builItem(index, snapshot.data?.docs[index]),
                      );
                    } else {
                      return const Center(
                        child: Text('No Message...'),
                      );
                    }
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ColorConstants.primaryColor,
                      ),
                    );
                  }
                })
            : const Center(
                child: CircularProgressIndicator(
                  color: ColorConstants.primaryColor,
                ),
              ));
  }

//buildMessageInput(),

  Widget buildMessageInput() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Row(children: [
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
              color: ColorConstants.primaryColor,
              borderRadius: BorderRadius.circular(30)),
          child: IconButton(
            onPressed: getImage,
            icon: const Icon(
              Icons.camera_alt,
              size: 28,
            ),
            color: Colors.white,
          ),
        ),
        Flexible(
          child: TextField(
            focusNode: focusNode,
            textInputAction: TextInputAction.send,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            controller: textEditingController,
            decoration:
                kTextInputDecoration.copyWith(hintText: 'write here...'),
            onSubmitted: (value) {
              onSendMessage(textEditingController.text, MessageType.text);
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: ColorConstants.primaryColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: IconButton(
              onPressed: () {
                onSendMessage(textEditingController.text, MessageType.text);
              },
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
              ),
              color: ColorConstants.primaryColor),
        ),
      ]),
    );
  }

  //builItem
  Widget builItem(int index, DocumentSnapshot? documentSnapshot) {
    if (documentSnapshot != null) {
      ChatMessage chatMessage = ChatMessage.fromDocument(documentSnapshot);
      if (chatMessage.idFrom == currenUderId) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                chatMessage.type == MessageType.text
                    ? messageBubble(
                        chatcontent: chatMessage.content,
                        color: const Color(0xff2b3a67),
                        textColor: ColorConstants.primaryColor,
                        margin: const EdgeInsets.only(right: 10),
                      )
                    : chatMessage.type == MessageType.image
                        ? Container(
                            margin: const EdgeInsets.only(right: 10, top: 10),
                            child: chatImage(
                                imageSrc: chatMessage.content, onTap: () {}),
                          )
                        : const SizedBox.shrink(),
                isMessageSend(index)
                    ? Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.network(
                          widget.userAvatar,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgrss) {
                            if (loadingProgrss == null) {
                              return child;
                            } else {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstants.primaryColor,
                                  value: loadingProgrss.expectedTotalBytes !=
                                              null &&
                                          loadingProgrss.expectedTotalBytes !=
                                              null
                                      ? loadingProgrss.cumulativeBytesLoaded /
                                          loadingProgrss.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            }
                          },
                          errorBuilder: (context, object, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 35,
                              color: ColorConstants.greyColor,
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 35,
                      )
              ],
            ),
            isMessageSend(index)
                ? Container(
                    margin:
                        const EdgeInsets.only(right: 50, left: 6, bottom: 8),
                    child: Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          int.parse(chatMessage.timestamp),
                        ),
                      ),
                      style: const TextStyle(
                          color: ColorConstants.greyColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                  )
                : const SizedBox.shrink()
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                isMessageReceived(index)
                    ? Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.network(
                          widget.peerAvatar,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgrss) {
                            if (loadingProgrss == null) {
                              return child;
                            } else {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstants.primaryColor,
                                  value: loadingProgrss.expectedTotalBytes !=
                                              null &&
                                          loadingProgrss.expectedTotalBytes !=
                                              null
                                      ? loadingProgrss.cumulativeBytesLoaded /
                                          loadingProgrss.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            }
                          },
                          errorBuilder: (context, object, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 35,
                              color: ColorConstants.greyColor,
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 35,
                      ),
                chatMessage.type == MessageType.text
                    ? messageBubble(
                        chatcontent: chatMessage.content,
                        color: const Color(0xff2b3a67),
                        textColor: ColorConstants.primaryColor,
                        margin: const EdgeInsets.only(right: 10),
                      )
                    : chatMessage.type == MessageType.image
                        ? Container(
                            margin: const EdgeInsets.only(right: 10, top: 10),
                            child: chatImage(
                                imageSrc: chatMessage.content, onTap: () {}),
                          )
                        : const SizedBox.shrink(),
              ],
            ),
            isMessageReceived(index)
                ? Container(
                    margin:
                        const EdgeInsets.only(right: 50, left: 6, bottom: 8),
                    child: Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          int.parse(chatMessage.timestamp),
                        ),
                      ),
                      style: const TextStyle(
                          color: ColorConstants.greyColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                  )
                : const SizedBox.shrink()
          ],
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }
}
