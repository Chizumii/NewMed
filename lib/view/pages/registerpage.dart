import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/database_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  
  // Default role
  String _selectedRole = 'mahasiswa';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("UCommittee", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 237, 220, 64))),
              const SizedBox(height: 8),
              const Text("Create your account", style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 30),

              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _institutionCtrl,
                      decoration: const InputDecoration(labelText: "School / University", prefixIcon: Icon(Icons.school), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    // Dropdown Role
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(labelText: "Register As", prefixIcon: Icon(Icons.badge), border: OutlineInputBorder()),
                      items: ['mahasiswa', 'siswa'].map((role) {
                        return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Confirm Password", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),

                    if (provider.isLoading)
                      const CircularProgressIndicator()
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_passCtrl.text != _confirmPassCtrl.text) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password tidak sama!")));
                              return;
                            }
                            // Panggil Provider Register
                            String? error = await provider.register(
                              _emailCtrl.text.trim(), // <--- SUDAH DITAMBAHKAN TRIM
                              _passCtrl.text, 
                              _nameCtrl.text, 
                              _selectedRole,
                              _institutionCtrl.text
                            );

                            if (error == null && mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful!'), backgroundColor: Colors.green));
                               Navigator.pop(context); // Balik ke Login
                            } else if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? "Error"), backgroundColor: Colors.red));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF0E68C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Create Account"),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Already have an account? Sign In", style: TextStyle(color: Color.fromARGB(255, 237, 220, 64))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}