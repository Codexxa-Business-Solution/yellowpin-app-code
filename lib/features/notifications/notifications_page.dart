import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_bottom_nav_theme.dart';
import '../../core/constants/app_routes.dart';

/// Notifications screen: white header, search, filter tabs (All, Jobs, Courses, Events), notification list.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedTab = 0; // 0 = All, 1 = Jobs, 2 = Courses, 3 = Events

  static const _tabs = ['All', 'Jobs', 'Courses', 'Events'];

  final _notifications = [
    _NotificationItem('Social Media Marketing Group by Josh Turner', '8 comments • 8 shares', '20min'),
    _NotificationItem('Full Name followed you', null, '1h'),
    _NotificationItem('Full Name reposted: Lorem ipsum dolor amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et...', null, '3h'),
    _NotificationItem('Forum Name and 8 people viewed your profile', null, '5h'),
    _NotificationItem('A post by an employee at Page name is popular: Lorem ipsum dolor sit amet, consectetur adipiscing elit...', '8 comments • 8 shares', '8h'),
  ];

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
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Faint yellowish-orange circular patterns behind header
          Positioned(
            top: 0,
            right: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.headerYellow.withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.headerYellow.withValues(alpha: 0.15),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchRow(context),
              _buildTabs(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.md),
                  children: _notifications.map((e) => _notificationCard(context, e)).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.sm),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search messages',
          hintStyle: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            borderSide: BorderSide(color: AppColors.headerYellow.withValues(alpha: 0.5), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            borderSide: BorderSide(color: AppColors.headerYellow.withValues(alpha: 0.5), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            borderSide: const BorderSide(color: AppColors.headerYellow, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Row(
        children: List.generate(
          _tabs.length,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < _tabs.length - 1 ? AppSpacing.sm : 0),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == i ? AppColors.headerYellow : AppColors.circleLightGrey,
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  ),
                  child: Text(
                    _tabs[i],
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: _selectedTab == i ? FontWeight.w600 : FontWeight.normal,
                      color: _selectedTab == i ? AppColors.white : AppColors.textPrimary,
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

  Widget _notificationCard(BuildContext context, _NotificationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.circleLightGrey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.time,
                style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 12),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: AppBottomNavTheme.barHeight + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: AppBottomNavTheme.backgroundColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(context, Icons.work_outline, 'My Jobs', () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 0)),
          _navItem(context, Icons.people_outline, 'Network', () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 1)),
          _navItem(context, Icons.home_outlined, 'Home', () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 2), selected: true),
          _navItem(context, Icons.school_outlined, 'Course', () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 3)),
          _navItem(context, Icons.event_outlined, 'Event', () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 4)),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool selected = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          selected
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: Icon(icon, color: AppBottomNavTheme.selectedColor, size: AppBottomNavTheme.iconSize),
                )
              : Icon(icon, color: AppBottomNavTheme.unselectedColor, size: AppBottomNavTheme.iconSize),
          const SizedBox(height: 2),
          Text(label, style: selected ? AppBottomNavTheme.labelSelectedStyle : AppBottomNavTheme.labelUnselectedStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _NotificationItem {
  final String title;
  final String? subtitle;
  final String time;

  _NotificationItem(this.title, this.subtitle, this.time);
}
