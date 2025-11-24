import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'dashboard.dart';
import 'forget_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await _auth.signIn(_email.text.trim(), _password.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    } catch (e) {
      _show('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _show('Enter your email first.');
      return;
    }
    try {
      await _auth.reset(email);
      _snack('Password reset email sent.');
    } catch (e) {
      _show('$e');
    }
  }

  void _show(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg.replaceFirst('Exception: ', ''))));
  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    const brandBg = Colors.white;
    const fieldFill = Color(0xFFD8E1EC);
    const fieldBorder = Color(0x33000000);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: brandBg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: bottomInset * 0.0), // keep layout stable
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/image/greenstem_logo.jpeg',
                            height: 72, // a bit smaller helps avoid jank
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Welcome !',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to access smart mech',
                          style: TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _email,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          style: const TextStyle(color: Colors.black87),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Email address*',
                            labelStyle: const TextStyle(color: Colors.black87),
                            hintText: 'example@gmail.com',
                            hintStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: fieldFill,
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: fieldBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.black87, width: 1.5),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email required';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          style: const TextStyle(color: Colors.black87),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Password*',
                            labelStyle: const TextStyle(color: Colors.black87),
                            hintText: 'Your password',
                            hintStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: fieldFill,
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: fieldBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.black87, width: 1.5),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure ? Icons.visibility : Icons.visibility_off,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password required';
                            if (v.length < 6) return 'Min 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Theme(
                              data: Theme.of(context).copyWith(
                                checkboxTheme: CheckboxThemeData(
                                  side: const BorderSide(color: Colors.black54),
                                  fillColor: MaterialStateProperty.resolveWith(
                                        (states) => states.contains(MaterialState.selected)
                                        ? Colors.black87
                                        : Colors.transparent,
                                  ),
                                  checkColor:
                                  const MaterialStatePropertyAll(Colors.white),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: _loading
                                    ? null
                                    : (v) => setState(() => _rememberMe = v ?? false),
                              ),
                            ),
                            const Text('Remember me',
                                style: TextStyle(color: Colors.black87)),
                            const Spacer(),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const ForgotPasswordPage(),
                                ),
                              ),
                              child: const Text('Forgot Password?',
                                  style: TextStyle(color: Colors.black87)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text('Sign in'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
