import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

void errorToast(String title, dynamic context) {
  Flushbar(
    title: title,
    messageText: SizedBox.shrink(),
    duration: Duration(seconds : 2),
    animationDuration: Duration(milliseconds: 650),
  ).show(context);
}