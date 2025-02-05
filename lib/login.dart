import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final SupabaseClient _supabaseClient = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>(); 

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      if (username.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username tidak boleh kosong")),
        );
      }
      
      else if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password tidak boleh kosong")),
        );
      } else {
        final response = await _supabaseClient
            .from('user')
            .select()
            .eq('username', username)
            .eq('password', password)
            .maybeSingle();

        if (response != null) {
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login Successful! Welcome, ${response['username']}")),
          );

      
        } else {
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Incorrect username or password.")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f4f5), 
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey, 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const Text(
                  "Login",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: "Username",
                    hintStyle: TextStyle(color: Colors.grey[600]), 
                    filled: true,
                    fillColor: const Color(0xffe0e0e0), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  style: const TextStyle(color: Colors.black), 
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username tidak boleh kosong'; 
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    hintStyle: TextStyle(color: Color.fromARGB(255, 136, 132, 132)), 
                    filled: true,
                    fillColor: const Color(0xffe0e0e0), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  style: const TextStyle(color: Colors.black), 
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong'; 
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 4, 43, 64), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 5,
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16, 
                      color: Colors.white, 
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}