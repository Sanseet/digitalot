import 'package:digitalot/pages/home_page.dart';
import 'package:digitalot/pages/signuppage.dart';
import 'package:flutter/material.dart';
import 'package:digitalot/pages/homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController =
      TextEditingController(text: '123456789');
  final TextEditingController _passwordController =
      TextEditingController(text: '123456');

  void _login() {
    if (_emailController.text == "123456789" &&
        _passwordController.text == "123456") {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => MyHomePage()));
    }
  }

  void _addDevice() {
    print("Add Device Button Pressed");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFC2C9FB),
                Color(0xFF333385),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 30),
                    const Text(
                      'Welcome Back !',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                    const SizedBox(height: 30),
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(
                          "https://img.freepik.com/free-vector/blue-circle-with-white-user_78370-4707.jpg?t=st=1743101238~exp=1743104838~hmac=110f2c9160f2d98cf2379874a29ba9051491c083d1f5f4a729522c8409572a3d&w=826"),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E2B40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const SignupPage()),
                        );
                      },
                      child: const Text(
                        "Don't have an account? Create",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
