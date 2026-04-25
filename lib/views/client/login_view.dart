import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../application/controllers/login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoginController>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Obx(() => Stack(
            children: [
              // ── Background gradient ───────────────────────────────────────
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

                        Image.asset('assets/images/optilens_transparent.png',
                            width: 220),

                        const SizedBox(height: 30),

                        Text(
                          c.isUserLogin.value ? 'User Login' : 'Welcome Back',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          c.isUserLogin.value
                              ? 'Login with your email and password.'
                              : 'Please enter your Client Code to continue.',
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 30),

                        // ── Form card ───────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4))
                            ],
                          ),
                          child: Column(
                            children: [
                              if (!c.isUserLogin.value)
                                TextField(
                                  controller: c.clientCodeController,
                                  decoration: InputDecoration(
                                    hintText: 'Client Code',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              if (c.isUserLogin.value) ...[
                                TextField(
                                  controller: c.emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: c.passwordController,
                                  obscureText: c.isObscure.value,
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        c.isObscure.value
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: c.toggleObscure,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: c.isLoading.value
                                      ? null
                                      : c.isUserLogin.value
                                          ? c.loginUser
                                          : c.loginClient,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: c.isLoading.value
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2))
                                      : const Text('LOGIN'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        GestureDetector(
                          onTap: c.toggleLoginMode,
                          child: Text(
                            c.isUserLogin.value
                                ? 'Log-in as client'
                                : 'Log-in as user',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Full-screen loading overlay ────────────────────────────────
              if (c.isLoading.value)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          )),
    );
  }
}