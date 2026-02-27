import 'package:flutter/material.dart';

class FriendsPage extends StatefulWidget {
  final String title;

  const FriendsPage({super.key, required this.title});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title),),
      body: Center(

      ),
    );
  }
}