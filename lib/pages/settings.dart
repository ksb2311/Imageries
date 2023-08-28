import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            // color: Colors.grey,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(fontSize: 27),
        ),
      ),
      body: const Column(
        children: [
          ListTile(
            title: Text('Theme'),
          ),
          ListTile(
            title: Text('Grid Size'),
          ),
          ListTile(
            title: Text('Privacy Policy'),
          ),
          ListTile(
            title: Text('About'),
          ),
        ],
      ),
    );
  }
}
