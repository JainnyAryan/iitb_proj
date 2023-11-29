// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iitb_proj/screens/enter_name_screen.dart';
import 'package:iitb_proj/screens/pattern_lock_screen.dart';

void main() async {
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pattern Lock Screen',
      home: GetStorage().hasData("parkinsonUserDetails") ? const PatternLockScreen() : const EnterNameScreen()
    );
  }
}
