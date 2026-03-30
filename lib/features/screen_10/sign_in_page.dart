import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/models/sign_in_args.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/auth_storage.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _agreed = false;
  bool _loading = false;
  /// Individual (job_seeker): single field for email or phone.
  final _identifierController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authApi = AuthApi();
  String? _selectedRole;

  void _onIdentifierChanged() => setState(() {});

  String _normalizeRole(String? role) {
    final value = (role ?? '').trim().toLowerCase();
    switch (value) {
      case 'organization':
        return 'organisation';
      case 'hr professional':
      case 'hr_professional':
        return 'hr';
      case 'job seeker':
      case 'individual user':
      case 'individual_user':
      case 'individual':
        return 'job_seeker';
      default:
        return value;
    }
  }

  bool get _isEmailOnlyRole {
    final normalized = _normalizeRole(_selectedRole);
    return normalized == 'organisation' || normalized == 'institute';
  }

  bool get _isJobSeekerRole => _normalizeRole(_selectedRole) == 'job_seeker';

  /// Show password when individual enters an email (email + password sign-in).
  bool get _individualUsingEmail =>
      _isJobSeekerRole && _identifierController.text.trim().contains('@');

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_onIdentifierChanged);
    _loadSelectedRoleFallback();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeRole = ModalRoute.of(context)?.settings.arguments as String?;
    if (routeRole == null || routeRole.trim().isEmpty) return;
    _selectedRole = _normalizeRole(routeRole);
    AuthStorage.setSelectedAuthRole(_selectedRole);
  }

  Future<void> _loadSelectedRoleFallback() async {
    final role = await AuthStorage.getSelectedAuthRole();
    if (!mounted) return;
    if (_selectedRole == null || _selectedRole!.trim().isEmpty) {
      setState(() => _selectedRole = _normalizeRole(role));
    }
  }

  @override
  void dispose() {
    _identifierController.removeListener(_onIdentifierChanged);
    _identifierController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignInTap() async {
    final role = _normalizeRole(_selectedRole);
    if (role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select role first'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.logInAs);
      return;
    }

    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Organization / Institute — email + password only.
    if (_isEmailOnlyRole) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your password'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      setState(() => _loading = true);
      final res = await _authApi.loginWithEmailPassword(email, password, role);
      if (!mounted) return;
      setState(() => _loading = false);
      if (res.isOk) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
        return;
      }
      final msg = res.data is Map && res.data['message'] != null
          ? res.data['message'].toString()
          : res.error ?? 'Failed to sign in';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Individual — email + password, or phone OTP.
    final raw = _identifierController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email or phone number'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (raw.contains('@')) {
      final password = _passwordController.text.trim();
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your password'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      setState(() => _loading = true);
      final res = await _authApi.loginWithEmailPassword(raw, password, role);
      if (!mounted) return;
      setState(() => _loading = false);
      if (res.isOk) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
        return;
      }
      final msg = res.data is Map && res.data['message'] != null
          ? res.data['message'].toString()
          : res.error ?? 'Failed to sign in';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final phoneDigits = raw.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 10 || phoneDigits.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _loading = true);
    final res = await _authApi.loginWithPhoneOTP(raw, role);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.isOk) {
      Navigator.pushNamed(context, AppRoutes.verify, arguments: SignInArgs(phone: raw, role: role));
      return;
    }

    final msg = res.data is Map && res.data['message'] != null
        ? res.data['message'].toString()
        : res.error ?? 'Failed to sign in';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
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
                          Navigator.pushReplacementNamed(context, AppRoutes.logInAs, arguments: _selectedRole);
                        }
                      },
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Sign In', style: AppTextStyles.headingLarge(context).copyWith(fontSize: 50)),
                  const SizedBox(height: AppSpacing.xxl),
                  if (_isEmailOnlyRole) ...[
                    AppTextField(
                      label: 'Email',
                      hint: 'you@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      label: 'Password',
                      hint: 'Enter password',
                      controller: _passwordController,
                      obscureText: true,
                    ),
                  ] else ...[
                    AppTextField(
                      label: 'Email/ Phone Number',
                      hint: 'Email or mobile number',
                      controller: _identifierController,
                      keyboardType: TextInputType.text,
                    ),
                    if (_individualUsingEmail) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        label: 'Password',
                        hint: 'Enter password',
                        controller: _passwordController,
                        obscureText: true,
                      ),
                    ],
                  ],
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
                    label: _loading
                        ? (_isEmailOnlyRole
                              ? 'Signing in…'
                              : (_isJobSeekerRole &&
                                        !_identifierController.text.trim().contains('@')
                                    ? 'Sending…'
                                    : 'Signing in…'))
                        : (_isEmailOnlyRole
                              ? 'Sign In'
                              : (_isJobSeekerRole &&
                                        !_identifierController.text.trim().contains('@')
                                    ? 'Next'
                                    : 'Sign In')),
                    onPressed: _loading ? null : _onSignInTap,
                  ),
                  const SizedBox(height: 72),
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, AppRoutes.signUpAs, arguments: _selectedRole),
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyLarge(context).copyWith(color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'Don’t have an account? '),
                            TextSpan(text: 'Sign up', style: AppTextStyles.bodyLarge(context).copyWith(color: AppColors.textPrimary)),
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
