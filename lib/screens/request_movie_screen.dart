import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/movie_request.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_controller.dart';

class RequestMovieScreen extends StatefulWidget {
  const RequestMovieScreen({super.key});

  @override
  State<RequestMovieScreen> createState() => _RequestMovieScreenState();
}

class _RequestMovieScreenState extends State<RequestMovieScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedLanguage = 'Any';
  String _selectedQuality = 'Any';
  bool _isSubmitting = false;

  final _languages = [
    'Any',
    'English',
    'Hindi',
    'Bangla',
    'Tamil',
    'Telugu',
    'Korean',
    'Japanese',
  ];
  final _qualities = ['Any', '480p', '720p', '1080p', '4K', 'HEVC'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _yearController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<Box<MovieRequest>> _getBox() async {
    if (!Hive.isBoxOpen('movie_requests')) {
      return await Hive.openBox<MovieRequest>('movie_requests');
    }
    return Hive.box<MovieRequest>('movie_requests');
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final box = await _getBox();

      // Check for duplicates
      final existing = box.values.where(
        (r) =>
            r.movieName.toLowerCase() ==
                _nameController.text.trim().toLowerCase() &&
            r.status == 'pending',
      );

      if (existing.isNotEmpty) {
        if (mounted) {
          Get.snackbar(
            'Already Requested',
            'This movie is already in your pending requests.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }

      // Check daily limit (max 5)
      final today = DateTime.now();
      final todayRequests = box.values
          .where(
            (r) =>
                r.requestedAt.year == today.year &&
                r.requestedAt.month == today.month &&
                r.requestedAt.day == today.day,
          )
          .length;

      if (todayRequests >= 5) {
        if (mounted) {
          Get.snackbar(
            'Daily Limit Reached',
            'You can only make 5 requests per day.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }

      final request = MovieRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        movieName: _nameController.text.trim(),
        year: _yearController.text.trim().isEmpty
            ? null
            : _yearController.text.trim(),
        language: _selectedLanguage == 'Any' ? null : _selectedLanguage,
        quality: _selectedQuality == 'Any' ? null : _selectedQuality,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        requestedAt: DateTime.now(),
      );

      await box.put(request.id, request);

      // Sync to backend (fire-and-forget — won't block if offline)
      try {
        await http
            .post(
              Uri.parse('${ApiService.baseUrl}/admin/movie-requests'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'movie_name': request.movieName,
                'year': request.year,
                'language': request.language,
                'quality': request.quality,
                'note': request.note,
              }),
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Silently fail — local Hive is the fallback
      }

      if (mounted) {
        // Clear form
        _nameController.clear();
        _yearController.clear();
        _noteController.clear();
        setState(() {
          _selectedLanguage = 'Any';
          _selectedQuality = 'Any';
          _isSubmitting = false;
        });

        Get.snackbar(
          '✅ Request Submitted!',
          '"${request.movieName}" has been requested.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        );

        // Switch to My Requests tab
        _tabController.animateTo(1);
      }
    } catch (e, stack) {
      debugPrint('❌ Request submit error: $e');
      debugPrint('Stack: $stack');
      setState(() => _isSubmitting = false);
      Get.snackbar(
        'Error',
        'Failed to submit request. Try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Request Movie', style: AppTextStyles.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: tc.accentColor,
          labelColor: tc.accentColor,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'New Request'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildRequestForm(tc), _buildMyRequests()],
      ),
    );
  }

  Widget _buildRequestForm(ThemeController tc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tc.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: tc.accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: tc.accentColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Can't find a movie? Request it and we'll try to add it!",
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Movie Name
            _buildLabel('Movie Name *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: _inputDecoration('e.g. Inception, The Dark Knight'),
              validator: (v) {
                if (v == null || v.trim().length < 2) {
                  return 'Movie name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Year
            _buildLabel('Year (Optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _yearController,
              style: GoogleFonts.inter(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('e.g. 2024'),
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  final year = int.tryParse(v);
                  if (year == null || year < 1900 || year > 2030) {
                    return 'Enter a valid year (1900-2030)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Language
            _buildLabel('Language'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages.map((lang) {
                final isSelected = _selectedLanguage == lang;
                return ChoiceChip(
                  label: Text(lang),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedLanguage = lang),
                  selectedColor: tc.accentColor.withValues(alpha: 0.3),
                  backgroundColor: AppColors.surfaceLight,
                  labelStyle: GoogleFonts.inter(
                    color: isSelected
                        ? tc.accentColor
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected ? tc.accentColor : AppColors.glassBorder,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Quality
            _buildLabel('Preferred Quality'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _qualities.map((q) {
                final isSelected = _selectedQuality == q;
                return ChoiceChip(
                  label: Text(q),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedQuality = q),
                  selectedColor: tc.accentColor.withValues(alpha: 0.3),
                  backgroundColor: AppColors.surfaceLight,
                  labelStyle: GoogleFonts.inter(
                    color: isSelected
                        ? tc.accentColor
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected ? tc.accentColor : AppColors.glassBorder,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Note
            _buildLabel('Additional Note (Optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              style: GoogleFonts.inter(color: Colors.white),
              maxLines: 3,
              decoration: _inputDecoration('Any specific details...'),
            ),
            const SizedBox(height: 30),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tc.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  disabledBackgroundColor: tc.accentColor.withValues(
                    alpha: 0.3,
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Submit Request',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRequests() {
    return FutureBuilder<Box<MovieRequest>>(
      future: _getBox(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ValueListenableBuilder(
          valueListenable: snapshot.data!.listenable(),
          builder: (context, Box<MovieRequest> box, _) {
            final requests = box.values.toList()
              ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

            if (requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No requests yet',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Submit a request from the first tab',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return _buildRequestCard(req);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRequestCard(MovieRequest req) {
    final statusColor = switch (req.status) {
      'pending' => Colors.orange,
      'processing' => Colors.blue,
      'completed' => AppColors.success,
      'rejected' => Colors.red,
      _ => AppColors.textMuted,
    };

    final statusIcon = switch (req.status) {
      'pending' => Icons.schedule,
      'processing' => Icons.sync,
      'completed' => Icons.check_circle,
      'rejected' => Icons.cancel,
      _ => Icons.help_outline,
    };

    final timeDiff = DateTime.now().difference(req.requestedAt);
    final timeAgo = timeDiff.inDays > 0
        ? '${timeDiff.inDays}d ago'
        : timeDiff.inHours > 0
        ? '${timeDiff.inHours}h ago'
        : '${timeDiff.inMinutes}m ago';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  req.movieName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.textMuted,
                onPressed: () async {
                  final box = await _getBox();
                  await box.delete(req.id);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  req.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                timeAgo,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              if (req.quality != null) ...[
                const SizedBox(width: 12),
                Text(
                  req.quality!,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              if (req.language != null) ...[
                const SizedBox(width: 8),
                Text(
                  '• ${req.language}',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
      filled: true,
      fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Get.find<ThemeController>().accentColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
