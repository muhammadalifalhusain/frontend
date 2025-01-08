import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/token_manager.dart';
import 'package:frontend/services/google_auth_service.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? errorMessage;
  final String backendUrl = "http://your-backend-url";

  Future<void> login() async {
    try {
      final response = await AuthService.login(
        emailController.text,
        passwordController.text,
      );

      await TokenManager.clearToken();
      await TokenManager.saveToken(response['token']);
      await TokenManager.saveUserId(response['user_id']);
      await TokenManager.saveKategoriId(response['kategori']);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(role: response['role']),
        ),
      );
    } catch (error) {
      setState(() {
        errorMessage = 'Login failed';
      });
    }
  }

  Future<void> googleLogin() async {
    try {
      final response = await GoogleAuthService.loginWithGoogle(backendUrl);

      if (response['success']) {
        await TokenManager.clearToken();
        await TokenManager.saveToken(response['token']);
        await TokenManager.saveUserId(response['user_id']);
        await TokenManager.saveKategoriId(response['kategori']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(role: response['role']),
          ),
        );
      } else {
        setState(() {
          errorMessage = response['message'];
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Google login failed: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login', style: TextStyle(color: Color(0xFFD0C05B))),
        backgroundColor: Color(0xFF05284E),
      ),
      body: Container(
        color: Color(0xFF05284E),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: emailController,
              style: TextStyle(color: Color(0xFFD0C05B)), // Warna teks input
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Color(0xFFD0C05B)),
                hintStyle: TextStyle(color: Color(0xFFB0B0B0)), // Warna placeholder
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD0C05B)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD0C05B)),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: passwordController,
              style: TextStyle(color: Color(0xFFD0C05B)), // Warna teks input
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Color(0xFFD0C05B)),
                hintStyle: TextStyle(color: Color(0xFFB0B0B0)), // Warna placeholder
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD0C05B)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD0C05B)),
                ),
              ),
              obscureText: true,
            ),
            if (errorMessage != null) ...[
              SizedBox(height: 10),
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: Text('Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD0C05B),
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.login, color: Colors.white),
              label: Text('Login with Google'),
              onPressed: googleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD0C05B),
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: Text(
                "Don't have an account? Register",
                style: TextStyle(color: Color(0xFFD0C05B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
