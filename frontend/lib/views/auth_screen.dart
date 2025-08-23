import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/AuthViewmodel.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/login1.png', height: 200),
              const SizedBox(height: 16),
              Text(
                'Log in',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[600],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: "Username",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      authVM.loading
                          ? CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[600],
                                  // Adjust intensity: 100–900
                                  foregroundColor: Colors.white,
                                  // Text color
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  final username = _usernameController.text
                                      .trim();
                                  final password = _passwordController.text
                                      .trim();

                                  if (username.isEmpty || password.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Please fill up all fields",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  authVM.login(username, password);
                                },
                                child: Text(
                                  "Sign in",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,

                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              Builder(
                builder: (context) {
                  if (authVM.error != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(authVM.error!),
                          backgroundColor: Colors.red,
                        ),
                      );
                      authVM.clearError();
                    });
                  } else if (authVM.loginResponse != null &&
                      authVM.loginResponse!.success) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacementNamed(context, '/principle');
                      authVM.clearLoginResponse();
                    });
                  }
                  return SizedBox.shrink();
                },
              ),
              SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                icon: Icon(Icons.person_add, color: Colors.purple[600]),
                label: Text(
                  "Sign up",
                  style: TextStyle(color: Colors.purple[600]),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.purple[600]!), // Purple border
                ),
              ),

              if (authVM.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    "Error : ${authVM.error}",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (authVM.loginResponse != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    authVM.loginResponse!.success
                        ? "Successfully connected !"
                        : "Failed : ${authVM.loginResponse!.message}",
                    style: TextStyle(
                      color: authVM.loginResponse!.success
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
