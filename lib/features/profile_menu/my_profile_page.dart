import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/models/signup_args.dart';
import '../../core/constants/app_assets.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/auth_storage.dart';
import '../../core/api/profile_api.dart';
import '../../core/api/api_config.dart';

/// My Profile: profile block, editable fields (recent job title, recent company, total experience), Bookmarks, My Listing, Help Center, Privacy Policy, Log Out.
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  bool _myListingExpanded = false;
  String? _userRole;
  final _authApi = AuthApi();
  final _profileApi = ProfileApi();
  bool _profileLoading = true;
  String _profileName = '';
  String _profileBio = '';
  String _profileImageUrl = '';
  String _jobTitle = '';
  String _companyName = '';
  String _totalExperience = '';
  String _educationDetails = '';

  /// Job seeker: qualification line under name (from API or placeholder).
  String _educationLine = '';

  bool get _isJobSeeker =>
      _userRole == 'job seeker' || _userRole == 'job_seeker';
  bool get _isOrganisation =>
      _userRole == 'organisation' || _userRole == 'organization';

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadProfile();
  }

  Future<void> _loadRole() async {
    final role = await AuthStorage.getUserRole();
    if (!mounted) return;
    setState(() => _userRole = role?.trim().toLowerCase());
  }

  Future<void> _loadProfile() async {
    setState(() => _profileLoading = true);
    final res = await _profileApi.getProfile();
    if (!mounted) return;
    setState(() => _profileLoading = false);
    if (res.isOk && res.data is Map) {
      final data = res.data as Map;
      final user = data['data'];
      if (user is Map) {
        final imageUrl = (user['image'] ?? '').toString().trim();
        setState(() {
          _profileName = (user['name'] ?? '').toString().trim();
          _profileBio = (user['bio'] ?? '').toString().trim();
          _profileImageUrl = imageUrl;
        });
        if (imageUrl.isNotEmpty) AuthStorage.setProfileImageUrl(imageUrl);
        final hr = user['hr_profile'];
        if (hr is Map) {
          setState(() {
            _jobTitle = (hr['job_title'] ?? '').toString().trim();
            _companyName = (hr['company_name'] ?? '').toString().trim();
            final te = hr['total_experience'];
            _totalExperience = te != null ? te.toString() : '';
            _educationDetails = (hr['education_details'] ?? '')
                .toString()
                .trim();
          });
        }
        final js = user['job_seeker_profile'];
        if (js is Map) {
          final edu =
              (js['education'] ??
                      js['qualification'] ??
                      js['field_of_study'] ??
                      js['degree'] ??
                      '')
                  .toString()
                  .trim();
          setState(() => _educationLine = edu);
        }
      }
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
      backgroundColor: _isJobSeeker
          ? AppColors.scaffoldBackground
          : AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Profile',
          style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.profileMenuItem,
              arguments: 'Settings',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: _userRole == 'institute'
            ? _buildInstituteProfileLayout(context)
            : _isJobSeeker
            ? _buildJobSeekerProfileLayout(context)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  _buildProfileBlock(context),
                  const SizedBox(height: AppSpacing.xl),
                  if (_profileLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (!_isOrganisation) ...[
                    _buildInfoField(context, 'recent job title', _jobTitle),
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoField(context, 'recent company', _companyName),
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoField(
                      context,
                      'Total experience',
                      _totalExperience,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoField(
                      context,
                      'Education details',
                      _educationDetails,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  _buildMenuList(context),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
      ),
    );
  }

  Widget _buildInstituteProfileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        _buildProfileBlock(context),
        const SizedBox(height: AppSpacing.md),
        _buildProfileCompletionCard(context),
        const SizedBox(height: AppSpacing.sm),
        _menuTile(
          context,
          icon: Icons.photo_library_outlined,
          label: 'College Information',
          trailing: Icons.chevron_right,
          onTap: () => Navigator.pushNamed(context, AppRoutes.collegeInfo),
        ),
        const Divider(height: 1),
        _menuTile(
          context,
          icon: Icons.bookmark_border,
          label: 'Bookmarks',
          trailing: Icons.chevron_right,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.profileMenuItem,
            arguments: 'Bookmarks',
          ),
        ),
        const Divider(height: 1),
        _menuTile(
          context,
          icon: Icons.list_alt_outlined,
          label: 'My Listing',
          trailing: _myListingExpanded ? Icons.expand_less : Icons.expand_more,
          onTap: () => setState(() => _myListingExpanded = !_myListingExpanded),
        ),
        const Divider(height: 1),
        if (_myListingExpanded) ...[
          _subMenuItem(
            context,
            Icons.work_outline,
            'My Jobs',
            () => Navigator.pushNamed(context, AppRoutes.postedJobsList),
          ),
          _subMenuItem(
            context,
            Icons.people_outline,
            'Job Seekers',
            () => Navigator.pushNamed(context, AppRoutes.jobSeekersList),
          ),
          _subMenuItem(
            context,
            Icons.school_outlined,
            'Organization',
            () => Navigator.pushNamed(context, AppRoutes.institutesList),
          ),
          _subMenuItem(
            context,
            Icons.chat_bubble_outline,
            'Applications',
            () => Navigator.pushNamed(context, AppRoutes.applicationsList),
          ),
          _subMenuItem(
            context,
            Icons.menu_book_outlined,
            'Courses',
            () => Navigator.pushNamed(context, AppRoutes.courseList),
          ),
          _subMenuItem(
            context,
            Icons.event_outlined,
            'Events',
            () => Navigator.pushNamed(context, AppRoutes.postedEventsList),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1),
        _menuTile(
          context,
          icon: Icons.help_outline,
          label: 'Help Center',
          trailing: Icons.chevron_right,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.profileMenuItem,
            arguments: 'Help Center',
          ),
        ),
        _menuTile(
          context,
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          trailing: Icons.chevron_right,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.profileMenuItem,
            arguments: 'Privacy Policy',
          ),
        ),
        _menuTile(
          context,
          icon: Icons.logout,
          label: 'Log Out',
          trailing: null,
          onTap: _onLogOut,
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  /// Job seeker: profile cards, completion ring, Application Status / Bookmarks / My List / Resume / help / logout.
  Widget _buildJobSeekerProfileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        _buildProfileBlock(context, jobSeekerStyle: true),
        const SizedBox(height: AppSpacing.md),
        _buildProfileCompletionCard(context, showEdit: true),
        const SizedBox(height: AppSpacing.md),
        _menuTile(
          context,
          icon: Icons.visibility_outlined,
          label: 'Application Status',
          trailing: Icons.chevron_right,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.profileMenuItem,
            arguments: 'Application Status',
          ),
        ),
        const Divider(height: 1),
        _menuTile(
          context,
          icon: Icons.bookmark_border,
          label: 'Bookmarks',
          trailing: Icons.chevron_right,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.profileMenuItem,
            arguments: 'Bookmarks',
          ),
        ),
        const Divider(height: 1),
        _menuTile(
          context,
          icon: Icons.book_outlined,
          label: 'My List',
          trailing: _myListingExpanded ? Icons.expand_less : Icons.expand_more,
          onTap: () => setState(() => _myListingExpanded = !_myListingExpanded),
        ),
        const Divider(height: 1),
        if (_myListingExpanded) ...[
          _subMenuItem(
            context,
            Icons.work_outline,
            'My Jobs',
            () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (r) => false,
              arguments: 0,
            ),
          ),
          _subMenuItem(
            context,
            Icons.group_outlined,
            'Organization',
            () => Navigator.pushNamed(context, AppRoutes.instituteProfileList),
          ),
          _subMenuItem(
            context,
            Icons.workspace_premium_outlined,
            'Courses',
            () => Navigator.pushNamed(context, AppRoutes.courseList),
          ),
          _subMenuItem(
            context,
            Icons.event_outlined,
            'Events',
            () => Navigator.pushNamed(context, AppRoutes.eventList),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1),
        _menuTile(
          context,
          icon: Icons.assignment_outlined,
          label: 'Resume',
          trailing: Icons.chevron_right,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.profileMenuItem,
            arguments: 'Resume',
          ),
        ),
        const Divider(height: 1),
        _menuTile(
          context,
          icon: Icons.error_outline,
          label: 'Help Center',
          trailing: Icons.chevron_right,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.profileMenuItem,
            arguments: 'Help Center',
          ),
        ),
        const Divider(height: 1),
        _menuTile(
          context,
          icon: Icons.shield_outlined,
          label: 'Privacy Policy',
          trailing: Icons.chevron_right,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.profileMenuItem,
            arguments: 'Privacy Policy',
          ),
        ),
        const Divider(height: 1),
        _menuTile(
          context,
          icon: Icons.logout,
          label: 'Log Out',
          trailing: null,
          onTap: _onLogOut,
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildProfileCompletionCard(
    BuildContext context, {
    bool showEdit = false,
  }) {
    void openPersonalInfo() {
      Navigator.pushNamed(context, AppRoutes.personalInfo).then((_) {
        if (mounted) _loadProfile();
      });
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: openPersonalInfo,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            border: Border.all(
              color: AppColors.headerYellow.withValues(alpha: 0.85),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (showEdit)
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: openPersonalInfo,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
              Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: 0.85,
                            strokeWidth: 5,
                            backgroundColor: AppColors.inputBorder,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryOrange,
                            ),
                          ),
                        ),
                        Text(
                          '85%',
                          style: AppTextStyles.headingMedium(
                            context,
                          ).copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: showEdit ? 28 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Completion !',
                            style: AppTextStyles.headingMedium(
                              context,
                            ).copyWith(fontSize: 17),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You\'re almost there! Complete the remaining steps to finish your profile.',
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Full URL for profile image (backend may return relative path).
  String get _displayImageUrl {
    if (_profileImageUrl.isEmpty) return '';
    if (_profileImageUrl.startsWith(RegExp(r'^https?://')))
      return _profileImageUrl;
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/v1$'), '');
    return base +
        (_profileImageUrl.startsWith('/') ? '' : '/') +
        _profileImageUrl;
  }

  Widget _buildProfileBlock(
    BuildContext context, {
    bool jobSeekerStyle = false,
  }) {
    final name = _profileName.isNotEmpty ? _profileName : 'User';
    final bio = _profileBio.isNotEmpty
        ? _profileBio
        : 'Exploring opportunities to learn, grow, and make an impact in [industry].';
    final education = _educationLine.isNotEmpty
        ? _educationLine
        : (jobSeekerStyle ? 'Diploma / BE Production / Industrial' : '');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: jobSeekerStyle
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.textSecondary,
                size: 22,
              ),
              onPressed: () async {
                final String route;
                final Object? args;
                if (_userRole == 'organisation' || _userRole == 'organization') {
                  route = AppRoutes.profileForm;
                  args = const SignUpArgs(phone: '', role: 'organisation', isEditProfile: true);
                } else if (_userRole == 'institute') {
                  route = AppRoutes.profileForm;
                  args = const SignUpArgs(phone: '', role: 'institute', isEditProfile: true);
                } else {
                  route = AppRoutes.hrEditProfile;
                  args = null;
                }
                final updated = await Navigator.pushNamed(
                  context,
                  route,
                  arguments: args,
                );
                if (updated == true && mounted) _loadProfile();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showImageSourceBottomSheet,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipOval(
                      child: _profileImageUrl.isNotEmpty
                          ? Image.network(
                              _displayImageUrl,
                              key: ValueKey(_displayImageUrl),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderAvatar(),
                            )
                          : Image.asset(
                              AppAssets.dummyProfile,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderAvatar(),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: jobSeekerStyle
                              ? AppColors.white
                              : AppColors.textPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: jobSeekerStyle
                                ? AppColors.inputBorder
                                : AppColors.white,
                            width: 2,
                          ),
                          boxShadow: jobSeekerStyle
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          jobSeekerStyle
                              ? Icons.camera_alt_outlined
                              : Icons.camera_alt,
                          color: jobSeekerStyle
                              ? AppColors.textSecondary
                              : AppColors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: AppTextStyles.headingMedium(context).copyWith(
                        fontSize: jobSeekerStyle ? 20 : 18,
                        fontWeight: jobSeekerStyle
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    if (jobSeekerStyle && education.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        education,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontStyle: FontStyle.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      bio,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        height: 1.35,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.circleLightGrey,
      child: const Icon(Icons.person, size: 40, color: AppColors.textSecondary),
    );
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              'Profile photo',
              style: AppTextStyles.headingMedium(
                context,
              ).copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.textPrimary,
              ),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.textPrimary,
              ),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    XFile? xFile;
    try {
      final picker = ImagePicker();
      xFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'channel-error'
          ? 'Image picker could not start. Fully close the app and open it again, then try again.'
          : (e.message ?? e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open picker: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (xFile == null || !mounted) return;
    final file = File(xFile.path);
    setState(() => _profileLoading = true);
    final res = await _profileApi.uploadProfileImage(file);
    if (!mounted) return;
    setState(() => _profileLoading = false);
    if (res.isOk && res.data is Map) {
      final url = res.data['image']?.toString();
      if (url != null && url.isNotEmpty) {
        setState(() => _profileImageUrl = url);
        await AuthStorage.setProfileImageUrl(url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.error ?? 'Failed to update photo'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildInfoField(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.textFieldBackground,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value.isEmpty ? '-' : value,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: value.isEmpty
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Column(
      children: [
        _menuTile(
          context,
          icon: Icons.bookmark_border,
          label: 'Bookmarks',
          trailing: Icons.chevron_right,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.profileMenuItem,
            arguments: 'Bookmarks',
          ),
        ),
        _menuTile(
          context,
          icon: Icons.list_alt_outlined,
          label: 'My Listing',
          trailing: _myListingExpanded ? Icons.expand_less : Icons.expand_more,
          onTap: () => setState(() => _myListingExpanded = !_myListingExpanded),
        ),
        if (_myListingExpanded) ...[
          _subMenuItem(
            context,
            Icons.work_outline,
            'Posted Jobs',
            () => Navigator.pushNamed(context, AppRoutes.postedJobsList),
          ),
          _subMenuItem(
            context,
            Icons.people_outline,
            'Job Seekers',
            () => Navigator.pushNamed(context, AppRoutes.jobSeekersList),
          ),
          _subMenuItem(
            context,
            Icons.school_outlined,
            'Institutes',
            () => Navigator.pushNamed(context, AppRoutes.institutesList),
          ),
          _subMenuItem(
            context,
            Icons.chat_bubble_outline,
            'Applications',
            () => Navigator.pushNamed(context, AppRoutes.applicationsList),
          ),
          _subMenuItem(
            context,
            Icons.menu_book_outlined,
            'Courses',
            () => Navigator.pushNamed(context, AppRoutes.courseList),
          ),
          _subMenuItem(
            context,
            Icons.event_outlined,
            'Events',
            () => Navigator.pushNamed(context, AppRoutes.postedEventsList),
          ),
        ],
        const Divider(height: 24, thickness: 1),
        _menuTile(
          context,
          icon: Icons.help_outline,
          label: 'Help Center',
          trailing: Icons.chevron_right,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.profileMenuItem,
            arguments: 'Help Center',
          ),
        ),
        _menuTile(
          context,
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          trailing: Icons.chevron_right,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.profileMenuItem,
            arguments: 'Privacy Policy',
          ),
        ),
        _menuTile(
          context,
          icon: Icons.logout,
          label: 'Log Out',
          trailing: null,
          onTap: _onLogOut,
        ),
      ],
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    IconData? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textPrimary, size: 24),
      title: Text(label, style: AppTextStyles.bodyMedium(context)),
      trailing: trailing != null
          ? Icon(trailing, color: AppColors.textSecondary, size: 24)
          : null,
      onTap: onTap,
    );
  }

  Widget _subMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xl),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.textSecondary, size: 22),
        title: Text(
          label,
          style: AppTextStyles.bodyMedium(context).copyWith(fontSize: 14),
        ),
        onTap: onTap,
      ),
    );
  }

  void _onLogOut() {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Logout',
                style: AppTextStyles.headingMedium(
                  context,
                ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Are you sure you want to Log Out ?',
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.inputBorder),
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _authApi.signOut();
                        await AuthApi.clearAuth();
                        rootNavigator.pushNamedAndRemoveUntil(
                          AppRoutes.logInAs,
                          (_) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.headerYellow,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                      child: const Text('Yes, Logout'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
