import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gait_rehab/core/constants/app_colors.dart';
import 'package:gait_rehab/core/constants/app_text.dart';
import 'package:gait_rehab/core/widgets/widgets.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../instructions/instructions_screen.dart';
import '../progress/progress_screen.dart';
import '../report/reports_list_screen.dart';
import '../profile/profile_screen.dart';
import '../upload/upload_screen.dart';
import 'metric_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _lastSession;
  bool _loading = true;

  final _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final profile =
          await _client.from('profiles').select().eq('id', uid).maybeSingle();

      final sessions = await _client
          .from('sessions')
          .select()
          .eq('user_id', uid)
          .order('session_date', ascending: false)
          .limit(1);

      setState(() {
        _profile = profile;
        _lastSession = sessions.isNotEmpty ? sessions.first : null;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  final _pages = [
    const _HomeTab(),
    const ProgressScreen(),
    const ReportsListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(
              top: BorderSide(color: AppColors.primary.withOpacity(0.15))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _navItem(1, Icons.show_chart_rounded, Icons.show_chart_outlined,
                    'Progress'),
                _navItem(2, Icons.description_rounded,
                    Icons.description_outlined, 'Reports'),
                _navItem(3, Icons.person_rounded, Icons.person_outline_rounded,
                    'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? active : inactive,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _client = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _lastSession;
  bool _loading = true;

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final profile =
          await _client.from('profiles').select().eq('id', uid).maybeSingle();
      final sessions = await _client
          .from('sessions')
          .select()
          .eq('user_id', uid)
          .order('session_date', ascending: false)
          .limit(1);
      setState(() {
        _profile = profile;
        _lastSession = sessions.isNotEmpty ? sessions.first : null;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['full_name']?.toString().split(' ').first ?? 'There';
    final score = _toDouble(_lastSession?['recovery_score']);
    final risk = _lastSession?['fall_risk'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Top bar with welcome and notification icon
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.10),
                            Colors.white.withOpacity(0.0)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.04),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: AppText.h1.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDark,
                                  fontSize: 30,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Let's get moving, $name!",
                                style: AppText.body.copyWith(
                                  color: AppColors.textMid,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          // Enhanced glassmorphic notification icon with badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipOval(
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.22),
                                        Colors.white.withOpacity(0.12),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.lightBlue.withOpacity(0.6),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 12,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.notifications_none_outlined,
                                        size: 28,
                                        color: Colors.lightBlue,
                                      ),
                                      onPressed: () {},
                                      splashRadius: 24,
                                      tooltip: 'Notifications',
                                    ),
                                  ),
                                ),
                              ),
                              // Notification badge
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Hero appointment-style card ───────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.08),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: HeroCard(
                        padding: EdgeInsets.zero,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(38, 22, 140, 22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ready for your\ngait session?',
                                    style: AppText.heroTitle.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Session info pills
                                  if (score != null) ...[
                                    _InfoPill(
                                      icon: Icons.timeline_rounded,
                                      text:
                                          'Last score: ${score.toStringAsFixed(1)}/100',
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (risk != null)
                                    _InfoPill(
                                      icon: Icons.shield_outlined,
                                      text:
                                          'Fall risk: ${risk[0].toUpperCase()}${risk.substring(1)}',
                                    )
                                  else
                                    _InfoPill(
                                      icon: Icons.play_circle_outline_rounded,
                                      text: 'Start your first session',
                                    ),
                                ],
                              ),
                            ),
                            // Illustration placeholder: walking.json animation
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(24),
                                  bottomRight: Radius.circular(24),
                                ),
                                child: Container(
                                  width: 130,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.heroEnd.withOpacity(0),
                                        AppColors.heroEnd,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: 90,
                                      height: 90,
                                      child: Lottie.asset(
                                        'assets/animations/walking2.json',
                                        repeat: true,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // ── Main Actions ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Start Session',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Live Recording card
                        _ActionCard(
                          title: 'Live Recording',
                          subtitle:
                              'Real-time gait analysis with pose overlay and voice feedback',
                          icon: Icons.videocam_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A7EA4), Color(0xFF0D9FCC)],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const InstructionsScreen()),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Upload Video card
                        _ActionCard(
                          title: 'Upload Video',
                          subtitle:
                              'Analyse an existing walking video from your library',
                          icon: Icons.upload_file_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00A890), Color(0xFF00D4AA)],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UploadScreen()),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // ── Quick Stats ──
                        // Glassmorphic Your Stats card with animation
                        Container(
                          padding: const EdgeInsets.all(22),
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.09),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.bar_chart_rounded,
                                      color: Color(0xFF3AABAB), size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Your Stats',
                                    style: AppText.h2.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              AnimatedStatsBar(
                                label: 'Cadence',
                                value: _toDouble(_lastSession?['cadence']),
                                max: 200,
                                unit: 'spm',
                                icon: Icons.speed_rounded,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 16),
                              AnimatedStatsBar(
                                label: 'Symmetry',
                                value: _toDouble(_lastSession?['symmetry']),
                                max: 100,
                                unit: '%',
                                icon: Icons.balance_rounded,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(height: 16),
                              AnimatedStatsBar(
                                label: 'Stride',
                                value:
                                    _toDouble(_lastSession?['stride_length']),
                                max: 2.0,
                                unit: 'm',
                                icon: Icons.straighten_rounded,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        // ── Tips ──
                        const _TipsCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

// Animated stats bar widget
class AnimatedStatsBar extends StatefulWidget {
  final String label;
  final double? value;
  final double max;
  final String unit;
  final IconData icon;
  final Color color;

  const AnimatedStatsBar({
    required this.label,
    required this.value,
    required this.max,
    required this.unit,
    required this.icon,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedStatsBar> createState() => _AnimatedStatsBarState();
}

class _AnimatedStatsBarState extends State<AnimatedStatsBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = Tween<double>(
      begin: 0,
      end: (widget.value ?? 0) / widget.max,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedStatsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: 0,
        end: (widget.value ?? 0) / widget.max,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = widget.value == null
        ? '--'
        : widget.label == 'Stride'
            ? widget.value!.toStringAsFixed(2)
            : widget.value!.toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.color, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$displayValue ${widget.unit}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: widget.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _animation.value.clamp(0, 1),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color.withOpacity(0.7),
                          widget.color.withOpacity(0.35),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.heroEnd.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: AppText.fontFamily,
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.secondary, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Daily Tip',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'For best results, record sessions at the same time each day. Consistency helps your AI coach track improvements accurately.',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
