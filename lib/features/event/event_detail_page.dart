import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../core/api/events_api.dart';
import '../../core/api/api_config.dart';

/// Screens 57–59: Event Details — loads event by [eventId], shows banner, title, date, location, link; Join Now → register API.
class EventDetailPage extends StatefulWidget {
  const EventDetailPage({super.key, this.eventId});

  final int? eventId;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final _eventsApi = EventsApi();
  Map<String, dynamic>? _event;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _loadEvent();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadEvent() async {
    final id = widget.eventId;
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _eventsApi.getEvent(id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data is Map) {
        _event = Map<String, dynamic>.from(res.data as Map);
        _error = null;
      } else {
        _event = null;
        _error = res.error ?? 'Failed to load event';
      }
    });
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

  static String _coverImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final base = ApiConfig.baseUrl;
    if (path.startsWith(RegExp(r'^https?://'))) return path;
    final segment = path.startsWith('event-covers/') ? path : 'event-covers/$path';
    return '$base/${segment.startsWith('/') ? segment.substring(1) : segment}';
  }

  void _showRegistrationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RegistrationSheet(
        onSubmit: () {
          Navigator.pop(ctx);
          _onRegister(context);
        },
      ),
    );
  }

  Future<void> _onRegister(BuildContext context) async {
    final id = widget.eventId;
    if (id != null) {
      final res = await EventsApi().register(id);
      if (!context.mounted) return;
      if (res.isOk) {
        _showSuccessDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Registration failed')));
      }
    } else {
      _showSuccessDialog(context);
    }
  }

  Widget _buildMenu(BuildContext context, Map<String, dynamic>? e) {
    final eventId = widget.eventId;
    if (eventId == null || e == null) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
      onSelected: (value) async {
        if (value == 'edit') {
          final updated = await Navigator.pushNamed<bool>(
            context,
            AppRoutes.createEvent,
            arguments: <String, dynamic>{'eventId': eventId, 'initialEvent': e},
          );
          if (updated == true && mounted) _loadEvent();
        } else if (value == 'delete') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Event'),
              content: const Text(
                'Are you sure you want to delete this event? This action cannot be undone.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            final res = await _eventsApi.deleteEvent(eventId);
            if (!mounted) return;
            if (res.isOk) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Event deleted successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context, true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res.error ?? 'Failed to delete event'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, color: AppColors.textPrimary, size: 18),
              const SizedBox(width: 8),
              Text('Edit Event', style: AppTextStyles.bodyMedium(context)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Text('Delete Event', style: AppTextStyles.bodyMedium(context).copyWith(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: AppColors.headerYellow, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: AppColors.white, size: 48),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Registered Successfully!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium(context).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
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
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.headerYellow,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Event Details', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _event == null && widget.eventId != null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.headerYellow,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Event Details', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.bannerRed)),
              const SizedBox(height: 16),
              TextButton(onPressed: _loadEvent, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final e = _event;
    final title = e != null ? (e['event_title'] ?? '').toString() : 'Event';
    final description = e != null ? (e['description'] ?? '').toString() : '';
    final startDt = e != null ? _formatDateTime(e['start_date_time']) : '—';
    final location = e != null ? (e['location'] ?? '').toString() : '—';
    final joinLink = e != null ? (e['join_link'] ?? '').toString().trim() : '';
    final eventType = e != null ? (e['event_type'] ?? '').toString() : '';
    final typeLabel = eventType.isNotEmpty
        ? eventType.split('_').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s).join(' ')
        : 'Event';
    final user = e != null ? e['user'] : null;
    final organizerName = user is Map ? (user['name'] ?? '').toString() : '—';
    final eventLinkUrl = joinLink.isNotEmpty ? joinLink : (location.toLowerCase().startsWith('http') ? location : '');
    final isOnline = eventLinkUrl.isNotEmpty || location.toLowerCase() == 'online';
    final showAsLink = eventLinkUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Event Details', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
        actions: [_buildMenu(context, e)],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBanner(context, e),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    title,
                    style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _statusChip(context, e),
                      const Spacer(),
                      Text('—', style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Event by', style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(organizerName.isEmpty ? '—' : organizerName, style: AppTextStyles.bodyMedium(context)),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(startDt, style: AppTextStyles.bodyMedium(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(isOnline ? Icons.laptop : Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isOnline ? (eventLinkUrl.isNotEmpty ? 'Online' : location) : (location.isEmpty ? '—' : location),
                          style: AppTextStyles.bodyMedium(context),
                        ),
                      ),
                    ],
                  ),
                  if (showAsLink) ...[
                    const SizedBox(height: 8),
                    Text('Event link:', style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        eventLinkUrl,
                        style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.linkBlue, decoration: TextDecoration.underline),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppSpacing.buttonHeight,
                          child: ElevatedButton(
                            onPressed: () => _showRegistrationSheet(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.black,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
                            ),
                            child: const Text('Join Now'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.share, color: AppColors.textPrimary),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
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

  Widget _statusChip(BuildContext context, Map<String, dynamic>? e) {
    if (e == null) return const SizedBox.shrink();
    final start = e['start_date_time'] != null ? DateTime.tryParse(e['start_date_time'].toString()) : null;
    final end = e['end_date_time'] != null ? DateTime.tryParse(e['end_date_time'].toString()) : null;
    final now = DateTime.now();
    String label;
    if (start != null && now.isBefore(start)) {
      label = 'Upcoming';
    } else if (end != null && now.isAfter(end)) {
      label = 'Ended';
    } else {
      label = 'Happening now';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.headerYellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildBanner(BuildContext context, Map<String, dynamic>? e) {
    final coverPath = e != null ? (e['cover_image'] ?? '').toString() : '';
    final url = _coverImageUrl(coverPath.isEmpty ? null : coverPath);
    final eventType = e != null ? (e['event_type'] ?? '').toString() : '';
    final typeLabel = eventType.isNotEmpty
        ? eventType.split('_').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s).join(' ')
        : 'EVENT';
    final title = e != null ? (e['event_title'] ?? '').toString() : '';
    final startDt = e != null ? _formatDateTime(e['start_date_time']) : '';

    return Stack(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          color: const Color(0xFF5C6BC0),
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => _bannerPlaceholder(context),
                )
              : _bannerPlaceholder(context),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
              ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.screenHorizontal,
          right: AppSpacing.screenHorizontal,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.headerYellow, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(typeLabel.toUpperCase(), style: AppTextStyles.headingMedium(context).copyWith(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              if (title.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  title,
                  style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.white.withValues(alpha: 0.9), fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (startDt.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(startDt, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.white, fontSize: 12)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _bannerPlaceholder(BuildContext context) {
    return Image.asset(
      AppAssets.event1,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF5C6BC0),
        child: const Center(child: Icon(Icons.event, size: 64, color: Colors.white70)),
      ),
    );
  }
}

class _RegistrationSheet extends StatefulWidget {
  final VoidCallback onSubmit;

  const _RegistrationSheet({required this.onSubmit});

  @override
  State<_RegistrationSheet> createState() => _RegistrationSheetState();
}

class _RegistrationSheetState extends State<_RegistrationSheet> {
  final _nameController = TextEditingController(text: 'Sayali Rane');
  final _phoneController = TextEditingController(text: '1234567890');
  final _emailController = TextEditingController(text: 'sayalirane@gmail.com');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Full Name:', style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter full name',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Phone:', style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter phone',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Email:', style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter email',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Please fill in all required details accurately. Your registration will be confirmed after submission.',
            style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeight,
            child: ElevatedButton(
              onPressed: widget.onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
              ),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
