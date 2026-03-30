import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/models/signup_args.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/auth_storage.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _agreed = false;
  bool _loading = false;
  final _identifierController = TextEditingController();
  final _authApi = AuthApi();
  String? _selectedRole;
  bool _loadedRoleFallback = false;

  bool _isValidEmail(String value) {
    final v = value.trim();
    return v.contains('@') && v.contains('.');
  }

  bool _isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 15;
  }

  String _normalizeRole(String? role) {
    final value = (role ?? '').trim().toLowerCase();
    switch (value) {
      case 'organization':
        return 'organisation';
      case 'hr professional':
      case 'hr_professional':
        return 'hr';
      case 'job seeker':
        return 'job_seeker';
      default:
        return value;
    }
  }

  bool get _isEmailOnlyRole {
    final normalized = _normalizeRole(_selectedRole);
    return normalized == 'organisation' || normalized == 'institute';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedRole ??= _normalizeRole(ModalRoute.of(context)?.settings.arguments as String?);
    if (_loadedRoleFallback) return;
    _loadedRoleFallback = true;
    if (_selectedRole == null || _selectedRole!.isEmpty) {
      AuthStorage.getSelectedAuthRole().then((storedRole) {
        if (!mounted || storedRole == null || storedRole.trim().isEmpty) return;
        setState(() => _selectedRole = _normalizeRole(storedRole));
      });
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _onSignUpTap() async {
    final role = _normalizeRole(_selectedRole);
    if (role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select role first'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.signUpAs);
      return;
    }
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEmailOnlyRole ? 'Please enter your email' : 'Please enter your email/phone'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_isEmailOnlyRole) {
      if (!_isValidEmail(identifier)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
    } else {
      final valid = _isValidEmail(identifier) || _isValidPhone(identifier);
      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter valid email or mobile number'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
    }
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _loading = true);
    final res = await _authApi.verifyWithPhone(identifier, role);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.isOk) {
      final otpDebug = res.data is Map ? res.data['otp_debug']?.toString() : null;
      Navigator.pushNamed(
        context,
        AppRoutes.verify,
        arguments: SignUpArgs(phone: identifier, role: role, otpDebug: otpDebug),
      );
    } else {
      final msg = res.data is Map && res.data['message'] != null
          ? res.data['message'].toString()
          : res.error ?? 'Failed to send OTP';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerYellow,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(AppAssets.authBackground, fit: BoxFit.cover)),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(context, AppRoutes.signUpAs, arguments: _selectedRole);
                        }
                      },
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Sign Up', style: AppTextStyles.headingLarge(context).copyWith(fontSize: 50)),
                  const SizedBox(height: AppSpacing.xxl),
                  AppTextField(
                    label: _isEmailOnlyRole ? 'Email' : 'Email/ Phone Number',
                    hint: _isEmailOnlyRole ? 'you@example.com' : '',
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                        activeColor: AppColors.headerYellow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 9),
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, height: 1.35),
                              children: [
                                const TextSpan(text: 'By clicking Agree & Join or Continue, you agree to the Fortune '),
                                TextSpan(text: 'User Agreement', style: AppTextStyles.link(context), recognizer: TapGestureRecognizer()..onTap = () {}),
                                const TextSpan(text: ', '),
                                TextSpan(text: 'Privacy Policy', style: AppTextStyles.link(context), recognizer: TapGestureRecognizer()..onTap = () {}),
                                const TextSpan(text: ', and '),
                                TextSpan(text: 'Cookie Policy', style: AppTextStyles.link(context), recognizer: TapGestureRecognizer()..onTap = () {}),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppPrimaryButton(
                    label: _loading ? 'Sending…' : 'Next',
                    onPressed: _loading ? null : _onSignUpTap,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.inputBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text('or sign up with', style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary)),
                      ),
                      const Expanded(child: Divider(color: AppColors.inputBorder)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Container(
                      width: 90,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('G', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 72),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.logInAs, arguments: _selectedRole),
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyLarge(context).copyWith(color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'Already on Fortune? '),
                            TextSpan(text: 'Sign in', style: AppTextStyles.bodyLarge(context).copyWith(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
