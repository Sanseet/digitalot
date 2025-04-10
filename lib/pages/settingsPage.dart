import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
         width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(
                  255, 132, 140, 254), // Light blue (from 0% in the image)
              Color(0xFF53589B), // Muted blue (25%)
              Color(0xFF343763), // Darker blue (50%)
              Color(0xFF292D5B), // Deep blue (75%)
              Color(0xFF262955), // Near black-blue (100%)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),child: Center(child: Text( "Coming Soon!",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),),
      ),)
    );
  }
}
