import 'package:firebase/firebaseChat/Constant/color_constsnts.dart';
import 'package:flutter/material.dart';

const kTextInputDecoration = InputDecoration(
  labelStyle: TextStyle(color: ColorConstants.greyColor),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: ColorConstants.greyColor, width: 1.5),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: ColorConstants.greyColor, width: 1.5),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
  errorBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.red, width: 1.5),
    borderRadius: BorderRadius.all(
      Radius.circular(10),
    ),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.red, width: 1.5),
    borderRadius: BorderRadius.all(
      Radius.circular(10),
    ),
  ),
);
