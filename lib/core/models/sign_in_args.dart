/// Arguments for sign-in OTP flow: pass phone to Verify page.
class SignInArgs {
  const SignInArgs({required this.phone, required this.role});
  final String phone;
  final String role;
}
