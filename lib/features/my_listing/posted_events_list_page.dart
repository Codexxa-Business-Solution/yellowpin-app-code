import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_bottom_nav_theme.dart';
import '../../core/api/api_config.dart';
import '../../core/api/events_api.dart';

/// My Listing → Posted Events: same layout as Posted Jobs — yellow header, search, Active | Completed tabs, event cards from API, FAB, bottom nav.
class PostedEventsListPage extends StatefulWidget {
  const PostedEventsListPage({super.key});

  @override
  State<PostedEventsListPage> createState() => _PostedEventsListPageState();
}

class _PostedEventsListPageState extends State<PostedEventsListPage> {
  int _selectedTab = 0; // 0 = Active, 1 = Completed
  final _eventsApi = EventsApi();
  final _searchController = TextEditingController();
  bool _loadingActive = false;
  bool _loadingCompleted = false;
  List<Map<String, dynamic>> _activeEvents = [];
  List<Map<String, dynamic>> _completedEvents = [];
  String? _errorActive;
  String? _errorCompleted;

  @override
  void initState() {
    super.initState();
    _loadActiveEvents();
    _loadCompletedEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveEvents() async {
    setState(() {
      _loadingActive = true;
      _errorActive = null;
    });
    final search = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
    final res = await _eventsApi.getMyEvents(status: 'active', search: search, perPage: 50);
    if (!mounted) return;
    setState(() {
      _loadingActive = false;
      if (res.isOk && res.data is Map) {
        final list = (res.data as Map)['data'];
        _activeEvents = list is List
            ? list.map((e) => e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{}).toList()
            : [];
      } else {
        _errorActive = res.error ?? 'Failed to load events';
      }
    });
  }

  Future<void> _loadCompletedEvents() async {
    setState(() {
      _loadingCompleted = true;
      _errorCompleted = null;
    });
    final search = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
    final res = await _eventsApi.getMyEvents(status: 'completed', search: search, perPage: 50);
    if (!mounted) return;
    setState(() {
      _loadingCompleted = false;
      if (res.isOk && res.data is Map) {
        final list = (res.data as Map)['data'];
        _completedEvents = list is List
            ? list.map((e) => e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{}).toList()
            : [];
      } else {
        _errorCompleted = res.error ?? 'Failed to load events';
      }
    });
  }

  static String _formatEventType(String v) {
    if (v.isEmpty) return 'Event';
    final k = v.toLowerCase().replaceAll('_', ' ');
    return k.isEmpty ? v : (k[0].toUpperCase() + k.substring(1));
  }

  static String _formatDate(dynamic v) {
    if (v == null) return '—';
    final s = v.toString().trim();
    if (s.isEmpty) return '—';
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = dt.month >= 1 && dt.month <= 12 ? months[dt.month - 1] : '';
    return '${dt.day} $m ${dt.year}';
  }

  static String _coverImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final base = ApiConfig.baseUrl;
    if (path.startsWith(RegExp(r'^https?://'))) return path;
    final segment = path.startsWith('event-covers/') ? path : 'event-covers/$path';
    return '$base/${segment.startsWith('/') ? segment.substring(1) : segment}';
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
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Posted Events', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchRow(context),
          _buildTabs(context),
          Expanded(
            child: _selectedTab == 0 ? _buildActiveList(context) : _buildCompletedList(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'posted_events_fab',
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.createEvent);
          if (mounted) {
            _loadActiveEvents();
            _loadCompletedEvents();
          }
        },
        backgroundColor: AppColors.headerYellow,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search event, organizer, etc..',
                hintStyle: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) {
                _loadActiveEvents();
                _loadCompletedEvents();
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () {
              _loadActiveEvents();
              _loadCompletedEvents();
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: const Icon(Icons.tune, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? AppColors.headerYellow.withValues(alpha: 0.25) : AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  border: Border.all(
                    color: _selectedTab == 0 ? AppColors.headerYellow : AppColors.inputBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'Active',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: _selectedTab == 0 ? FontWeight.w600 : FontWeight.normal,
                    color: _selectedTab == 0 ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? AppColors.headerYellow.withValues(alpha: 0.25) : AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  border: Border.all(
                    color: _selectedTab == 1 ? AppColors.headerYellow : AppColors.inputBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'Completed',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: _selectedTab == 1 ? FontWeight.w600 : FontWeight.normal,
                    color: _selectedTab == 1 ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveList(BuildContext context) {
    if (_loadingActive) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator()),
      );
    }
    if (_errorActive != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorActive!,
                style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: _loadActiveEvents, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_activeEvents.isEmpty) {
      return Center(
        child: Text(
          'No active posted events.',
          style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadActiveEvents,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: _activeEvents.map((e) => _eventCard(context, e)).toList(),
      ),
    );
  }

  Widget _buildCompletedList(BuildContext context) {
    if (_loadingCompleted) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator()),
      );
    }
    if (_errorCompleted != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorCompleted!,
                style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: _loadCompletedEvents, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_completedEvents.isEmpty) {
      return Center(
        child: Text(
          'No completed events.',
          style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadCompletedEvents,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: _completedEvents.map((e) => _eventCard(context, e)).toList(),
      ),
    );
  }

  Widget _eventCard(BuildContext context, Map<String, dynamic> e) {
    final id = e['id'] is int ? e['id'] as int : (int.tryParse(e['id']?.toString() ?? '') ?? 0);
    final title = (e['event_title'] ?? '').toString();
    final user = e['user'];
    final organizer = user is Map ? (user['name'] ?? 'Organizer').toString() : 'Organizer';
    final location = (e['location'] ?? '').toString();
    final count = e['registrations_count'] ?? 0;
    final meta = location.isEmpty
        ? '$count interested'
        : '$location • $count interested';
    final eventType = (e['event_type'] ?? '').toString();
    final tag = _formatEventType(eventType);
    final dateStr = _formatDate(e['start_date_time']);
    final coverPath = (e['cover_image'] ?? '').toString();
    final coverUrl = _coverImageUrl(coverPath.isEmpty ? null : coverPath);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: id),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(),
                    )
                  : _avatarFallback(),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headingMedium(context).copyWith(fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    organizer,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.applicantsGreen,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.linkBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: 11,
                      color: AppColors.linkBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateStr,
                  style: AppTextStyles.headingMedium(context).copyWith(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return Image.asset(
      AppAssets.event1,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 48,
        height: 48,
        color: AppColors.circleLightGrey,
        child: const Icon(Icons.event, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: AppColors.black),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.work_outline, 'My Jobs', false, () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 0)),
          _navItem(Icons.people_outline, 'Network', false, () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 1)),
          _navItem(Icons.home_outlined, 'Home', false, () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 2)),
          _navItem(Icons.school_outlined, 'Course', false, () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 3)),
          _navItem(Icons.event_outlined, 'Event', true, () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 4)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected ? AppBottomNavTheme.selectedColor : AppBottomNavTheme.unselectedColor,
            size: AppBottomNavTheme.iconSize,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: selected ? AppBottomNavTheme.labelSelectedStyle : AppBottomNavTheme.labelUnselectedStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
