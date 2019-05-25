import 'dart:math';

import 'package:flutter/material.dart';
import 'package:usafe_app/status_page/status_page.dart';

import 'package:usafe_app/message_display/message_display.dart';
import 'package:usafe_app/status_page/status_page_bloc.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StatusPageBloc _statusPageBloc = StatusPageBloc();

  @override
  Widget build(BuildContext context) {
    return StatusPage(_statusPageBloc);
  }

  @override
  void dispose() {
    super.dispose();
    _statusPageBloc.dispose();
  }
}
