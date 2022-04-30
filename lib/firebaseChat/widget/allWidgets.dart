import 'package:firebase/firebaseChat/Constant/color_constsnts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget messageBubble({
  required String chatcontent,
  required EdgeInsetsGeometry? margin,
  Color? color,
  Color? textColor,
}) {
  return Container(
    padding: const EdgeInsets.all(10),
    margin: margin,
    decoration:
        BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
    child: Text(
      chatcontent,
      style: TextStyle(fontSize: 16, color: textColor),
    ),
  );
}

Widget chatImage({required String imageSrc, required Function onTap}) {
  return OutlinedButton(
    onPressed: onTap(),
    child: Image.network(
      imageSrc,
      width: 200,
      height: 200,
      fit: BoxFit.cover,
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent? loadingProgass) {
        if (loadingProgass == null) {
          return child;
        } else {
          return Container(
            decoration: BoxDecoration(
              color: ColorConstants.greyColor2,
              borderRadius: BorderRadius.circular(10),
            ),
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              color: ColorConstants.primaryColor,
              value: loadingProgass.expectedTotalBytes != null &&
                      loadingProgass.expectedTotalBytes != null
                  ? loadingProgass.cumulativeBytesLoaded /
                      loadingProgass.expectedTotalBytes!
                  : null,
            ),
          );
        }
      },
      errorBuilder: (context, object, stackTrace) => errorContainer(),
    ),
  );
}

Widget errorContainer() {
  return Container(
    clipBehavior: Clip.hardEdge,
    child: Image.asset('assets/img_not_available.jpeg'),
    height: 200,
    width: 200,
  );
}
