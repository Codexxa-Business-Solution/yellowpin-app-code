import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/models/signup_args.dart';
import '../../core/models/sign_in_args.dart';
import '../../core/api/auth_api.dart';
import '../../widgets/app_primary_button.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final TextEditingController _emailOtpController = TextEditingController();
  final _authApi = AuthApi();
  bool _loading = false;
  bool _resending = false;
  bool _emailVerified = false;

  SignUpArgs? get _signUpArgs {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is SignUpArgs ? args : null;
  }

  SignInArgs? get _signInArgs {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is SignInArgs ? args : null;
  }

  String get _phoneDisplay {
    final signIn = _signInArgs;
    if (signIn != null) return signIn.phone;
    final signUp = _signUpArgs;
    return signUp?.phone ?? '';
  }

  bool get _isEmailFlow => _phoneDisplay.contains('@');

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _emailOtpController.dispose();
    super.dispose();
  }

  void _verifyEmailOtp() {
    final entered = _emailOtpController.text.trim();
    final expected = (_signUpArgs?.otpDebug?.trim().isNotEmpty ?? false) ? _signUpArgs!.otpDebug!.trim() : '123456';
    if (entered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email OTP'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _emailVerified = entered == expected);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_emailVerified ? 'Verified' : 'Invalid OTP code'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onConfirm() async {
    if (_isEmailFlow) {
      if (!_emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify email OTP first'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      final args = _signUpArgs;
      if (args != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.profileForm, arguments: args);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.logInAs);
      }
      return;
    }

    final enteredOtp = _controllers.map((c) => c.text).join();
    if (enteredOtp.isNotEmpty && enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 6-digit code'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final otp = enteredOtp.length == 6 ? enteredOtp : '123456';

    final signInArgs = _signInArgs;
    if (signInArgs != null) {
      setState(() => _loading = true);
      final res = await _authApi.verifyLoginOtp(signInArgs.phone, otp, signInArgs.role);
      if (!mounted) return;
      setState(() => _loading = false);
      if (res.isOk) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
      } else {
        final msg = res.data is Map && res.data['message'] != null
            ? res.data['message'].toString()
            : res.error ?? 'Verification failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    final args = _signUpArgs;
    if (args == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.signUpAs);
      return;
    }

    setState(() => _loading = true);
    final role = args.role?.trim() ?? '';
    final res = await _authApi.verifyOtp(args.phone, otp, role);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.isOk) {
      Navigator.pushReplacementNamed(context, AppRoutes.profileForm, arguments: args);
    } else {
      final msg = res.data is Map && res.data['message'] != null
          ? res.data['message'].toString()
          : res.error ?? 'Verification failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _onResendSms() async {
    if (_resending) return;
    final signInArgs = _signInArgs;
    final signUpArgs = _signUpArgs;
    final phone = signInArgs?.phone ?? signUpArgs?.phone;
    if (phone == null || phone.isEmpty) return;
    final role = signInArgs?.role ?? signUpArgs?.role ?? '';
    setState(() => _resending = true);
    final res = signInArgs != null
        ? await _authApi.loginWithPhoneOTP(phone, role)
        : await _authApi.verifyWithPhone(phone, role);
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.isOk ? 'Code resent' : (res.error ?? 'Failed to resend')),
        behavior: SnackBarBehavior.floating,
      ),
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
                  const SizedBox(height: 44),
                  Text('Verify', style: AppTextStyles.headingLarge(context).copyWith(fontSize: 50)),
                  const SizedBox(height: 36),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.vertical(top: Radius.elliptical(500, 120)),
                    ),
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 46, AppSpacing.screenHorizontal, AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Enter Verification Code',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headingMedium(context).copyWith(fontSize: 26),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          _isEmailFlow ? 'We have sent an OTP to' : 'We have sent a verification code to',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge(context).copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _phoneDisplay,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge(context).copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (_isEmailFlow) ...[
                          TextField(
                            controller: _emailOtpController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              labelText: 'Email OTP',
                              hintText: 'Enter OTP code',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.inputBorder),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPrimaryButton(
                            label: _emailVerified ? 'Verified' : 'Verify',
                            onPressed: _verifyEmailOtp,
                          ),
                        ] else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (i) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: SizedBox(
                                  width: 42,
                                  child: TextField(
                                    controller: _controllers[i],
                                    focusNode: _focusNodes[i],
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.inputBorder)),
                                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.inputBorder)),
                                    ),
                                    onChanged: (v) {
                                      if (v.isNotEmpty && i < 5) FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
                                      if (v.isEmpty && i > 0) FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
                                    },
                                  ),
                                ),
                              );
                            }),
                          ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppPrimaryButton(
                          label: _loading ? 'Verifying…' : 'Confirm',
                          onPressed: _loading ? null : _onConfirm,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: Column(
                            children: [
                              Text('Didn’t receive SMS?', style: AppTextStyles.bodyLarge(context).copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: (_signInArgs != null || _signUpArgs != null) ? _onResendSms : () {},
                                child: Text(_resending ? 'Sending…' : 'Resend code by SMS', style: AppTextStyles.link(context)),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {},
                                child: Text('Resend code by phone call', style: AppTextStyles.link(context)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
