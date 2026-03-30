import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/api/events_api.dart';
import '../../core/api/api_config.dart';
import '../../widgets/app_text_field.dart';

/// Create an event form: upload cover, mode, type, name, dates/times, link, description, moderators. Submit → Event Posted Successfully.
/// When [eventId] and [initialEvent] are set, runs in edit mode: form prefilled and submit calls update API.
class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key, this.eventId, this.initialEvent});

  final int? eventId;
  final Map<String, dynamic>? initialEvent;

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  bool _eventModeOnSite = true;
  String? _eventType = 'Job fair';
  bool _hasEndDateAndTime = true;
  final _nameController = TextEditingController();
  final _startDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endDateController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _joinLinkController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _moderatorsController = TextEditingController();
  final _eventsApi = EventsApi();
  bool _submitting = false;
  String? _coverFilePath;
  /// When editing, URL of the existing cover image from API (for preview).
  String? _existingCoverUrl;

  @override
  void initState() {
    super.initState();
    final e = widget.initialEvent;
    if (e != null) _prefillFromEvent(e);
  }

  void _prefillFromEvent(Map<String, dynamic> e) {
    _nameController.text = (e['event_title'] ?? '').toString();
    final et = (e['event_type'] ?? '').toString();
    _eventType = et == 'job_fair' ? 'Job fair' : 'Other';
    _descriptionController.text = (e['description'] ?? '').toString();
    final joinLinkFromApi = (e['join_link'] ?? '').toString().trim();
    final loc = (e['location'] ?? '').toString();
    if (joinLinkFromApi.isNotEmpty) {
      _eventModeOnSite = false;
      _joinLinkController.text = joinLinkFromApi;
    } else if (loc.toLowerCase().startsWith('http') || loc.toLowerCase() == 'online') {
      _eventModeOnSite = false;
      _joinLinkController.text = loc.toLowerCase().startsWith('http') ? loc : '';
    } else {
      _eventModeOnSite = true;
      _joinLinkController.text = loc == 'On-site' ? '' : loc;
    }
    final start = e['start_date_time'];
    if (start != null) {
      final dt = DateTime.tryParse(start.toString());
      if (dt != null) {
        _startDateController.text = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        _startTimeController.text = '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
      }
    }
    final end = e['end_date_time'];
    if (end != null && end.toString().trim().isNotEmpty) {
      final dt = DateTime.tryParse(end.toString());
      if (dt != null) {
        _hasEndDateAndTime = true;
        _endDateController.text = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        _endTimeController.text = '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
      }
    }
    final coverPath = (e['cover_image'] ?? '').toString();
    if (coverPath.isNotEmpty) {
      _existingCoverUrl = _coverImageUrl(coverPath);
    }
    _moderatorsController.text = (e['moderators'] ?? '').toString();
  }

  static String _coverImageUrl(String path) {
    if (path.isEmpty) return '';
    final base = ApiConfig.baseUrl;
    if (path.startsWith(RegExp(r'^https?://'))) return path;
    final segment = path.startsWith('event-covers/') ? path : 'event-covers/$path';
    return '$base/${segment.startsWith('/') ? segment.substring(1) : segment}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    _endDateController.dispose();
    _endTimeController.dispose();
    _joinLinkController.dispose();
    _descriptionController.dispose();
    _moderatorsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, TextEditingController c) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      c.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  Future<void> _pickTime(BuildContext context, TextEditingController c) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      c.text = '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
    }
  }

  /// Parse "dd/mm/yyyy" and "h:mm AM/PM" into DateTime (local).
  DateTime? _parseDateTime(String dateStr, String timeStr) {
    final d = dateStr.trim().split(RegExp(r'[/\-.]'));
    if (d.length != 3) return null;
    final day = int.tryParse(d[0].trim());
    final month = int.tryParse(d[1].trim());
    final year = int.tryParse(d[2].trim());
    if (day == null || month == null || year == null) return null;
    int hour = 0, minute = 0;
    if (timeStr.isNotEmpty) {
      final t = timeStr.trim().toLowerCase();
      final am = t.contains('am');
      final pm = t.contains('pm');
      final numPart = t.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = numPart.split(':');
      if (parts.isNotEmpty) {
        hour = int.tryParse(parts[0].trim()) ?? 0;
        if (parts.length > 1) minute = int.tryParse(parts[1].trim()) ?? 0;
        if (pm && hour < 12) hour += 12;
        if (am && hour == 12) hour = 0;
      }
    }
    try {
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickCover() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (xFile != null && mounted) {
        setState(() => _coverFilePath = xFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: ${e.toString()}'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showSuccessDialog() {
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
                widget.eventId != null ? 'Event Updated Successfully!' : 'Event Posted Successfully!',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: AppTextStyles.headingMedium(context).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
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

  Future<void> _submit() async {
    final title = _nameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event name is required')));
      return;
    }
    final startDt = _parseDateTime(_startDateController.text, _startTimeController.text);
    if (startDt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start date and time')));
      return;
    }
    setState(() => _submitting = true);
    final eventType = _eventType == 'Job fair' ? 'job_fair' : (_eventType == 'Other' ? 'seminar' : 'job_fair');
    final joinLink = _joinLinkController.text.trim();
    final location = _eventModeOnSite ? 'On-site' : (joinLink.isEmpty ? 'Online' : 'Online');
    final moderators = _moderatorsController.text.trim();
    final body = <String, dynamic>{
      'event_title': title,
      'event_type': eventType,
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'location': location.isEmpty ? null : location,
      'start_date_time': startDt.toUtc().toIso8601String(),
      'booking_enabled': false,
      if (moderators.isNotEmpty) 'moderators': moderators,
      if (joinLink.isNotEmpty) 'join_link': joinLink,
    };
    if (_hasEndDateAndTime) {
      final endDt = _parseDateTime(_endDateController.text, _endTimeController.text);
      if (endDt != null) body['end_date_time'] = endDt.toUtc().toIso8601String();
    }
    final eventId = widget.eventId;
    final res = eventId != null
        ? await _eventsApi.updateEvent(eventId, body, coverPath: _coverFilePath)
        : await _eventsApi.createEvent(body, coverPath: _coverFilePath);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.isOk) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? (eventId != null ? 'Failed to update event' : 'Failed to create event'))),
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
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.eventId != null ? 'Edit Event' : 'Create an event', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            _buildUploadCover(context),
            const SizedBox(height: AppSpacing.xl),
            _buildEventMode(context),
            const SizedBox(height: AppSpacing.lg),
            _buildEventType(context),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Event Name', hint: 'Enter event name', controller: _nameController),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Start Date',
              hint: 'Select date',
              controller: _startDateController,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 22),
                onPressed: () => _pickDate(context, _startDateController),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Start Time',
              hint: 'Select time',
              controller: _startTimeController,
              suffixIcon: IconButton(
                icon: const Icon(Icons.access_time, color: AppColors.textSecondary, size: 22),
                onPressed: () => _pickTime(context, _startTimeController),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildEndDateCheckbox(context),
            if (_hasEndDateAndTime) ...[
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'End Date',
                hint: 'Select date',
                controller: _endDateController,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 22),
                  onPressed: () => _pickDate(context, _endDateController),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'End Time',
                hint: 'Select time',
                controller: _endTimeController,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time, color: AppColors.textSecondary, size: 22),
                  onPressed: () => _pickTime(context, _endTimeController),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Event Join Link', hint: 'https://...', controller: _joinLinkController, keyboardType: TextInputType.url),
            const SizedBox(height: AppSpacing.lg),
            _buildDescription(context),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Event Moderators', hint: 'Enter moderators', controller: _moderatorsController),
            const SizedBox(height: AppSpacing.xl),
            _buildPolicy(context),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
                ),
                child: _submitting
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Text('Submit'),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCover(BuildContext context) {
    final hasNewCover = _coverFilePath != null && _coverFilePath!.isNotEmpty;
    final hasExistingCover = _existingCoverUrl != null && _existingCoverUrl!.isNotEmpty;
    return GestureDetector(
      onTap: _pickCover,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.textFieldBackground,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(color: AppColors.inputBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasNewCover
            ? Image.file(
                File(_coverFilePath!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => _uploadPlaceholder(context),
              )
            : hasExistingCover
                ? Image.network(
                    _existingCoverUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => _uploadPlaceholder(context),
                  )
                : _uploadPlaceholder(context),
      ),
    );
  }

  Widget _uploadPlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.linkBlue.withValues(alpha: 0.8)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Upload cover image',
          style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEventMode(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Event Mode', style: AppTextStyles.bodyMedium(context)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                value: true,
                groupValue: _eventModeOnSite,
                onChanged: (v) => setState(() => _eventModeOnSite = true),
                title: Text('On-site', style: AppTextStyles.bodyMedium(context)),
                activeColor: AppColors.headerYellow,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                value: false,
                groupValue: _eventModeOnSite,
                onChanged: (v) => setState(() => _eventModeOnSite = false),
                title: Text('Online', style: AppTextStyles.bodyMedium(context)),
                activeColor: AppColors.headerYellow,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventType(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Event Type', style: AppTextStyles.bodyMedium(context)),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: _eventType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.textFieldBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          ),
          items: const [
            DropdownMenuItem(value: 'Job fair', child: Text('Job fair')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: (v) => setState(() => _eventType = v),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        ),
      ],
    );
  }

  Widget _buildEndDateCheckbox(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _hasEndDateAndTime,
            onChanged: (v) => setState(() => _hasEndDateAndTime = v ?? true),
            activeColor: AppColors.applicantsGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: () => setState(() => _hasEndDateAndTime = !_hasEndDateAndTime),
          child: Text('end date and time', style: AppTextStyles.bodyMedium(context)),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Event Description', style: AppTextStyles.bodyMedium(context)),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'EX: Topics, Schedule etc',
            hintStyle: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.textFieldBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('By continuing, you agree with ', style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary)),
            GestureDetector(
              onTap: () {},
              child: Text('Fortune events policy.', style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.linkBlue, decoration: TextDecoration.underline)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Make the most of Fortune Events. ', style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary)),
            GestureDetector(
              onTap: () {},
              child: Text('Learn More', style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.linkBlue, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ],
    );
  }
}
