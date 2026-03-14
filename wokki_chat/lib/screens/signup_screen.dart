import 'package:flutter/material.dart';
import 'package:wokki_chat/services/auth_service.dart';
import 'package:wokki_chat/services/api_service.dart';
import 'package:wokki_chat/theme/app_theme.dart';
import 'package:wokki_chat/widgets/form_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await _authService.saveTokens(
        accessToken: response['access_token'],
        refreshToken: response['refresh_token'],
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/setup');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeMode.slate.colors;

    return Scaffold(
      backgroundColor: colors.surfaceA0,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: colors.textA20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Create account',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: colors.textA0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign up to get started.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: colors.textA40,
                  ),
                ),
                const SizedBox(height: 36),

                FieldLabel(label: 'Display Name', colors: colors),
                const SizedBox(height: 8),
                InputField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  hintText: 'Your name',
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  prefixIcon: Icons.person_outline_rounded,
                  colors: colors,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_emailFocus),
                ),
                const SizedBox(height: 20),

                FieldLabel(label: 'Email', colors: colors),
                const SizedBox(height: 8),
                InputField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  hintText: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  prefixIcon: Icons.email_outlined,
                  colors: colors,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_passwordFocus),
                ),
                const SizedBox(height: 20),

                FieldLabel(label: 'Password', colors: colors),
                const SizedBox(height: 8),
                InputField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  hintText: '••••••••',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  prefixIcon: Icons.lock_outline_rounded,
                  colors: colors,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colors.textA40,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  onSubmitted: (_) => _handleSignup(),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  ErrorBanner(message: _errorMessage!, colors: colors),
                ],

                const SizedBox(height: 32),

                FilledButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primaryA0,
                    disabledBackgroundColor: colors.primaryA0.withOpacity(0.5),
                    foregroundColor: colors.textWhiteA0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: colors.primaryA30, width: 1),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colors.textWhiteA0),
                          ),
                        )
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: colors.textA40,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: Text(
                        'Log in',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.primaryA0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}