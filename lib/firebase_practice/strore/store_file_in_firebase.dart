import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class StoreFile extends StatefulWidget {
  const StoreFile({Key? key}) : super(key: key);

  @override
  State<StoreFile> createState() => _StoreFileState();
}

class _StoreFileState extends State<StoreFile> {
  File? file;
  UploadTask? task;

//1
  Future uploads() async {
    if (file == null) return;

    //for basename we have to import path.dart
    final filename = p.basename(file!.path);
    final destination = 'files/$filename';


    //Get firebase download link  --> firebaseapi is a class which i created
    task = FirebaseApi.uploadfile(destination, file!);
  //setstate work when create the widget a
    setState(() {});
    if (task == null) return;

    final snapshot = await task!.whenComplete(() {});
    final urlDownload = await snapshot.ref.getDownloadURL();

    print('Download Url : $urlDownload');
  }

//2
  Future selectFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null) return;
    final path = result.files.single.path;
    setState(() {
      file = File(path!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileName = file != null ? p.basename(file!.path) : 'No file found';
    return Scaffold(
      appBar: AppBar(
        title: Text('Store File In Firebase'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              selectFile();
            },
            child: Text('Select File'),
          ),
          Text(fileName),
          ElevatedButton(
            onPressed: () async {
              uploads();
            },
            child: Text('Upload File'),
          ),
          task != null ? buildUploadStatus(task!) : Container(),

          // Center(

          //   child: isLoading
          //       ? CircularProgressIndicator()
          //       : ElevatedButton(
          //           onPressed: () {
          //             selectFile();
          //           },
          //           child: Text('Select File'),
          //         ),
          // ),
          // ElevatedButton(
          //   onPressed: () {
          //     uploads();
          //   },
          //   child: Text('Upload File'),
          // ),
          // if (pickedFile != null)
          //   Expanded(
          //     child: Container(
          //       color: Colors.green,
          //       // height: 300,
          //       // width: 300,
          //       child: Image.file(
          //         fileToDisplay!,
          //         fit: BoxFit.cover,
          //       ),
          //     ),
          //   ),
          // Center(child: Text(fileName.toString()))
        ],
      ),
    );
  }
}

//3
class FirebaseApi {
  static UploadTask? uploadfile(String destination, File file) {
    try {
      final ref = FirebaseStorage.instance.ref(destination);
      return ref.putFile(file);
    } on FirebaseException catch (e) {
      return null;
    }
  }

//byte file
  static UploadTask? uploadBytes(String destination, Uint8List data) {
    try {
      final ref = FirebaseStorage.instance.ref(destination);
      return ref.putData(data);
    } on FirebaseException catch (e) {
      return null;
    }
  }
}

//4
Widget buildUploadStatus(UploadTask task) => StreamBuilder<TaskSnapshot>(
    stream: task.snapshotEvents,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final snap = snapshot.data!;
        final prograss = snap.bytesTransferred / snap.totalBytes;
        final percentage = (prograss * 100).toStringAsFixed(2);

        return Text(
          '$percentage %',
          style: TextStyle(fontWeight: FontWeight.bold),
        );
      } else {
        return Container();
      }
    });
