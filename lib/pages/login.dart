import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  // --- THEME COLORS ---
  final Color _bgCream = const Color(0xFFFFFEF7);
  final Color _borderColor = Colors.black;
  final Color _shadowColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. LOGO / BRANDING AREA
                _buildRetroLogo(),
                const SizedBox(height: 40),

                // 2. FORM INPUT
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildLabel("EMAIL"),
                ),
                _buildRetroTextField(_emailController, "Masukkan email..."),
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildLabel("PASSWORD"),
                ),
                _buildRetroTextField(
                  _passwordController,
                  "Masukkan password...",
                  obscureText: true,
                ),

                // 3. ERROR MESSAGE
                if (_errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      border: Border.all(color: _borderColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _shadowColor,
                          offset: const Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // 4. ACTION BUTTONS
                authProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Column(
                        children: [
                          // Main Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                setState(() => _errorMessage = null);
                                try {
                                  await authProvider.signIn(
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                                } catch (e) {
                                  setState(() => _errorMessage = e.toString());
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: const Text(
                                "MASUK",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Divider "ATAU"
                          // Row(
                          //   children: [
                          //     Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                          //     Padding(
                          //       padding: const EdgeInsets.symmetric(horizontal: 12),
                          //       child: Text("ATAU", style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
                          //     ),
                          //     Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                          //   ],
                          // ),
                          // const SizedBox(height: 16),

                          // // Admin Shortcut Button (Outline)
                          // SizedBox(
                          //   width: double.infinity,
                          //   height: 56,
                          //   child: TextButton(
                          //     onPressed: () async {
                          //       setState(() => _errorMessage = null);
                          //       try {
                          //         await authProvider.signInDefault();
                          //       } catch (e) {
                          //         setState(() => _errorMessage = e.toString());
                          //       }
                          //     },
                          //     style: TextButton.styleFrom(
                          //       foregroundColor: Colors.black,
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(12),
                          //         side: const BorderSide(color: Colors.black, width: 2),
                          //       ),
                          //     ),
                          //     child: const Text(
                          //       "LOGIN SEBAGAI ADMIN",
                          //       style: TextStyle(
                          //         fontWeight: FontWeight.bold,
                          //         fontSize: 14,
                          //       ),
                          //     ),
                          //     ),
                          //   ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildRetroLogo() {
    return Column(
      children: [
        // Ikon Aplikasi dari ic_launcher
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor, width: 2),
            // boxShadow: [
            //   BoxShadow(
            //     color: _shadowColor,
            //     offset: const Offset(4, 4),
            //     blurRadius: 0,
            //   ),
            // ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset('assets/ic_launcher.png', fit: BoxFit.cover),
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          "Pocket ERP",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: Colors.black,
          ),
        ),
        const Text(
          "Kutoarjo Grosir",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRetroTextField(
    TextEditingController ctrl,
    String hint, {
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscureText,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.normal,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _borderColor, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _borderColor, width: 3),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _emailController = TextEditingController(text: 'admin@kg.com');
//   final _passwordController = TextEditingController(text: 'admin123');
//   String? _errorMessage;

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Login')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(labelText: 'Email'),
//             ),
//             TextField(
//               controller: _passwordController,
//               decoration: const InputDecoration(labelText: 'Password'),
//               obscureText: true,
//             ),
//             if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
//             const SizedBox(height: 20),
//             authProvider.isLoading
//                 ? const CircularProgressIndicator()
//                 : ElevatedButton(
//                     onPressed: () async {
//                       setState(() => _errorMessage = null);
//                       try {
//                         await authProvider.signIn(_emailController.text, _passwordController.text);
//                         // Navigation handled by AuthWrapper
//                       } catch (e) {
//                         setState(() => _errorMessage = e.toString());
//                       }
//                     },
//                     child: const Text('Login'),
//                   ),
//             TextButton(
//               onPressed: () async {
//                 setState(() => _errorMessage = null);
//                 try {
//                   await authProvider.signInDefault();
//                   // Navigation handled by AuthWrapper
//                 } catch (e) {
//                   setState(() => _errorMessage = e.toString());
//                 }
//               },
//               child: const Text('Login as Admin'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
