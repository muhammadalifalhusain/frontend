import 'package:flutter/material.dart';
import 'package:frontend/screens/login_page.dart';
import '../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? successMessage;

  Future<void> register() async {
    try {
      await AuthService.register(
        usernameController.text,
        emailController.text,
        passwordController.text,
        'user',
        '5',
      );

      setState(() {
        successMessage = 'Registration successful';
      });
    } catch (error) {
      setState(() {
        successMessage = 'Registration failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register', style: TextStyle(color: Color(0xFFD0C05B))),
        backgroundColor: Color(0xFF05284E),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Color(0xFF05284E),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Color(0xFFD0C05B)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD0C05B)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD0C05B)),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Color(0xFFD0C05B)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD0C05B)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD0C05B)),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Color(0xFFD0C05B)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD0C05B)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD0C05B)),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD0C05B),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                ),
                onPressed: register,
                child: Text('Register'),
              ),
              if (successMessage != null) ...[
                SizedBox(height: 10),
                Text(
                  successMessage!,
                  style: TextStyle(
                    color: successMessage == 'Registration successful'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(color: Color(0xFFD0C05B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
