import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/AuthViewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/inscription.png',
                height: 200,
              ),
              const SizedBox(height: 24),
              Text(
                "Sign up",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[600],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              authVM.loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final username = _usernameController.text.trim();
                    final password = _passwordController.text.trim();

                    if (username.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                          Text("Please fill in all the fields."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      authVM.register(username, password);
                    }
                  },
                  child: const Text(
                    "Sign up",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Already registered ? Sign in",
                  style: TextStyle(color: Colors.purple),
                ),
              ),
              if (authVM.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    "Erreur : ${authVM.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (authVM.registerResponse != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    authVM.registerResponse!.success
                        ? "Registration Successful!"
                        : "Failed : ${authVM.registerResponse!.message}",
                    style: TextStyle(
                      color: authVM.registerResponse!.success
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


