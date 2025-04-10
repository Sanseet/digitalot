import 'package:digitalot/approutes.dart';
import 'package:digitalot/pages/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black, // App color
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
      ),
      initialRoute: AppRoutes.splashscreen,
      // routes: AppRoutes.pages,
      // home: MyHomePage(),
      home: LoginPage(),
    );
  }
}
