import 'package:flutter/material.dart';

import 'home_screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool isCustomer = true;

  // Text editing controllers for form fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo and Title
              Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart, size: 60, color: Colors.green),
                    SizedBox(height: 10),
                    Text(
                      'QuickMart',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text('Create your account', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              SizedBox(height: 40),

              // Toggle buttons for Customer and Vendor
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isCustomer = true;
                      });
                    },
                    child: Text('Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCustomer ? Colors.black : Colors.grey,
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isCustomer = false;
                      });
                    },
                    child: Text('Vendor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCustomer ? Colors.grey : Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Input Fields
              _buildTextField(nameController, 'Full Name', Icons.person),
              _buildTextField(emailController, 'Email', Icons.email),
              _buildTextField(phoneController, 'Phone Number', Icons.phone),
              _buildTextField(
                passwordController,
                'Password',
                Icons.lock,
                isPassword: true,
              ),

              SizedBox(height: 20),

              // Create Account Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(),
                      ), // Navigate to HomePage
                    );
                  },
                  child: Text('Create Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Sign in prompt and demo credentials
              Center(
                child: Column(
                  children: [
                    Text('Already have an account? Sign in'),
                    SizedBox(height: 10),
                    Text('Demo Credentials:'),
                    Text('Email: demo@example.com'),
                    Text('Password: demo123'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
