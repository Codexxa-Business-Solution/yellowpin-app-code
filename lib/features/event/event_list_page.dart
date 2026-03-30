import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../core/api/api_config.dart';
import '../../core/api/events_api.dart';
import '../../widgets/dynamic_profile_header_row.dart';

/// Screen 52–54: All Events — header, search, All Events + Create an event, Job Fair | Other tabs, event cards from API, FAB.
/// When [showOnlyMyEvents] is true (e.g. from My Profile → Events), shows only events created by the logged-in user.
class EventListPage extends StatefulWidget {
  const EventListPage({super.key, this.showOnlyMyEvents = false});

  final bool showOnlyMyEvents;

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  int _selectedTab = 0; // 0 = Job Fair Events, 1 = Other Events
  final _eventsApi = EventsApi();
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = widget.showOnlyMyEvents
        ? await _eventsApi.getMyEvents(perPage: 50)
        : await _eventsApi.getEvents(perPage: 50);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data is Map) {
        final data = res.data as Map;
        final list = data['data'];
        _events = list is List
            ? list
                .map((e) => e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{})
                .toList()
            : [];
        _error = null;
      } else {
        _events = [];
        _error = res.error ?? 'Failed to load events';
      }
    });
  }

  List<Map<String, dynamic>> get _filteredEvents {
    if (_selectedTab == 0) {
      return _events.where((e) => (e['event_type'] ?? '').toString() == 'job_fair').toList();
    }
    return _events.where((e) => (e['event_type'] ?? '').toString() != 'job_fair').toList();
  }

  Future<void> _openCreateEvent() async {
    final created = await Navigator.pushNamed(context, AppRoutes.createEvent);
    if (mounted && created == true) _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerYellow,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    final filtered = _filteredEvents;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadEvents,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.showOnlyMyEvents ? 'My Events' : 'All Events',
                            style: AppTextStyles.headingMedium(context).copyWith(fontSize: 20),
                          ),
                          OutlinedButton(
                            onPressed: _openCreateEvent,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.headerYellow),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                            ),
                            child: const Text('Create an event'),
                          ),
                        ],
                      ),
                      if (!widget.showOnlyMyEvents) ...[
                        const SizedBox(height: AppSpacing.lg),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.eventList, arguments: true),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Your events', style: AppTextStyles.bodyMedium(context)),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _buildTabs(context),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        widget.showOnlyMyEvents ? 'Your created events' : 'Recommended for you',
                        style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_loading)
                        const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator()))
                      else if (_error != null)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Column(
                              children: [
                                Text(_error!, style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.bannerRed), textAlign: TextAlign.center),
                                const SizedBox(height: AppSpacing.md),
                                TextButton(onPressed: _loadEvents, child: const Text('Retry')),
                              ],
                            ),
                          ),
                        )
                      else if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Text(
                              widget.showOnlyMyEvents
                                  ? 'You haven\'t created any events yet.'
                                  : (_selectedTab == 0 ? 'No job fair events yet.' : 'No other events yet.'),
                              style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        ...filtered.map((e) => _eventCardFromMap(context, e)),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'event_list_fab',
        onPressed: _openCreateEvent,
        backgroundColor: AppColors.headerYellow,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.headerYellow,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.md),
      child: Column(
        children: [
          DynamicProfileHeaderRow(
            trailing: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.inputBorder)),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 22),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(minimumSize: Size.zero),
                    ),
                  ),
                  Positioned(top: 6, right: 6, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.bannerRed, shape: BoxShape.circle))),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search job, company, etc..',
                    hintStyle: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppSpacing.borderRadius), border: Border.all(color: AppColors.inputBorder)),
                child: const Icon(Icons.tune, color: AppColors.textSecondary, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedTab == 0 ? AppColors.headerYellow.withValues(alpha: 0.3) : AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                border: Border.all(color: _selectedTab == 0 ? AppColors.headerYellow : AppColors.inputBorder),
              ),
              child: Text(
                'Job Fair Events',
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
                color: _selectedTab == 1 ? AppColors.headerYellow.withValues(alpha: 0.3) : AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                border: Border.all(color: _selectedTab == 1 ? AppColors.headerYellow : AppColors.inputBorder),
              ),
              child: Text(
                'Other Events',
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
    );
  }

  static String _formatDateTime(dynamic v) {
    if (v == null) return '—';
    final s = v.toString().trim();
    if (s.isEmpty) return '—';
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = dt.weekday >= 1 && dt.weekday <= 7 ? days[dt.weekday - 1] : '';
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day, ${dt.day.toString().padLeft(2)} ${_month(dt.month)} ${dt.year}, ${hour.toString().padLeft(2)}:${dt.minute.toString().padLeft(2)} $period';
  }

  static String _month(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m >= 1 && m <= 12 ? months[m - 1] : '';
  }

  static final List<Color> _cardColors = [
    const Color(0xFF5C6BC0),
    const Color(0xFF1565C0),
    const Color(0xFF2E7D32),
  ];

  static String _coverImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final base = ApiConfig.baseUrl;
    if (path.startsWith(RegExp(r'^https?://'))) return path;
    final segment = path.startsWith('event-covers/') ? path : 'event-covers/$path';
    return '$base/${segment.startsWith('/') ? segment.substring(1) : segment}';
  }

  void _openEventDetail(BuildContext context, int eventId) {
    Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: eventId);
  }

  Widget _eventCardFromMap(BuildContext context, Map<String, dynamic> e) {
    final id = e['id'] is int ? e['id'] as int : (int.tryParse(e['id']?.toString() ?? '') ?? 0);
    final title = (e['event_title'] ?? '').toString();
    final desc = (e['description'] ?? title).toString();
    final location = (e['location'] ?? '').toString();
    final isOnSite = location.toLowerCase().contains('on-site') || location.toLowerCase().contains('onsite') || (location.isNotEmpty && !location.toLowerCase().startsWith('http'));
    final mode = location.isNotEmpty ? (isOnSite ? 'On-site' : 'Online') : '—';
    final dateTime = _formatDateTime(e['start_date_time']);
    final colorIndex = id % _cardColors.length;
    final imageBg = _cardColors[colorIndex];
    final asset = colorIndex == 0 ? AppAssets.event1 : (colorIndex == 1 ? AppAssets.event2 : AppAssets.event3);
    final coverPath = (e['cover_image'] ?? '').toString();
    final coverUrl = _coverImageUrl(coverPath.isEmpty ? null : coverPath);
    return GestureDetector(
      onTap: () => _openEventDetail(context, id),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 130,
              color: imageBg,
              child: coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        asset,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.event, size: 48, color: AppColors.white.withValues(alpha: 0.8)),
                      ),
                    )
                  : Image.asset(
                      asset,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.event, size: 48, color: AppColors.white.withValues(alpha: 0.8)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateTime, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(desc, style: AppTextStyles.bodyMedium(context).copyWith(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(isOnSite ? Icons.location_on_outlined : Icons.laptop, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(mode, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary)),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => _openEventDetail(context, id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.headerYellow),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                        ),
                        child: const Text('View'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.share, size: 22, color: AppColors.textSecondary),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ],
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
