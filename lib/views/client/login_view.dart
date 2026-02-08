import 'package:flutter/material.dart';
import '../../../application/controllers/CustomerController.dart';
import '../../widgets/zoom_drawer_page.dart';
import '../../../application/controllers/login_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _clientCodeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;
  bool isUserLogin = false;

  void loginClient() async {
    final code = _clientCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer le code client")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await CustomerController().fetchCustomer(code);
      if (response != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ZoomDrawerPage(customer: response.customer, isUser: false),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Code client invalide"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email et mot de passe requis")),
      );
      return;
    }

    print("🔵 Tentative de login avec email: $email");

    setState(() => isLoading = true);

    try {
      final response = await LoginController().login(
        email: email,
        password: password,
      );

      setState(() => isLoading = false);

      if (response != null) {
        print("🟢 Login réussi - Username: ${response.user.name}");
        print("🟢 Token reçu: ${response.user.sid}");
        print("🟢 Token length: ${response.user.sid?.length ?? 0}");
        print("🟢 Token is null? ${response.user.sid == null}");
        print("🟢 Token is empty? ${response.user.sid?.isEmpty ?? true}");
        
        // ✅ Vérification critique avant navigation
        if (response.user.sid == null || response.user.sid!.isEmpty) {
          print("❌ ERREUR CRITIQUE: Le serveur a renvoyé un token vide ou null!");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Erreur: Token manquant dans la réponse du serveur. Contactez l'administrateur."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }
        
        print("✅ Navigation vers ZoomDrawerPage avec token: ${response.user.sid}");
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ZoomDrawerPage(
              isUser: true,
              userName: response.user.name,
              token: response.user.sid,
            ),
          ),
        );
      } else {
        print("🔴 Login échoué - response est null");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Identifiants invalides - Vérifiez votre email et mot de passe"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print("🔴 Exception dans loginUser: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur de connexion: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE0F2F1), Color(0xFF80CBC4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    Image.asset(
                      'assets/images/optilens_transparent.png',
                      width: 220,
                    ),

                    const SizedBox(height: 30),

                    Text(
                      isUserLogin ? 'User Login' : 'Welcome Back',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isUserLogin
                          ? 'Login with your email and password.'
                          : 'Please enter your Client Code to continue.',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (!isUserLogin)
                            TextField(
                              controller: _clientCodeController,
                              decoration: InputDecoration(
                                hintText: 'Client Code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          if (isUserLogin) ...[
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : isUserLogin
                                  ? loginUser
                                  : loginClient,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('LOGIN'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isUserLogin = !isUserLogin;
                        });
                      },
                      child: Text(
                        isUserLogin ? 'Log-in as client' : 'Log-in as user',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}