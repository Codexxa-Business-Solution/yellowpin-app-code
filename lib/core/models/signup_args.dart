/// Data passed through sign-up flow: Verify → SignUpAs → ProfileForm.
class SignUpArgs {
  const SignUpArgs({
    required this.phone,
    this.role,
    this.otpDebug,
    this.isEditProfile = false,
  });

  final String phone;
  /// Backend role: hr | organisation | institute | job_seeker
  final String? role;
  /// OTP returned by API in debug mode (for testing only).
  final String? otpDebug;
  /// When true, [ProfileFormPage] loads existing user data and saves via profile API (job seeker / organisation).
  final bool isEditProfile;

  SignUpArgs copyWith({
    String? phone,
    String? role,
    String? otpDebug,
    bool? isEditProfile,
  }) {
    return SignUpArgs(
      phone: phone ?? this.phone,
      role: role ?? this.role,
      otpDebug: otpDebug ?? this.otpDebug,
      isEditProfile: isEditProfile ?? this.isEditProfile,
    );
  }
}
