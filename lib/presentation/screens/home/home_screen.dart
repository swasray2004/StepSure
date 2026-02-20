import 'package:flutter/material.dart';
import 'package:gait_rehab/core/constants/app_colors.dart';
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
    final lastScore = _lastSession?['recovery_score'] as double?;
    final lastRisk = _lastSession?['fall_risk'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Hero Header ──
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $name 👋',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ready to walk?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.notifications_outlined,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Last session pill
                        if (lastScore != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.25)),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Last Session Score',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${lastScore.toStringAsFixed(1)}/100',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (lastRisk != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${lastRisk[0].toUpperCase()}${lastRisk.substring(1)} Risk',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.25)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.white70, size: 18),
                                SizedBox(width: 10),
                                Text(
                                  'No sessions yet — start your first walk!',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                      ],
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
                        const Text(
                          'Your Stats',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _QuickStats(lastSession: _lastSession),

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

class _QuickStats extends StatelessWidget {
  final Map<String, dynamic>? lastSession;

  const _QuickStats({this.lastSession});

  @override
  Widget build(BuildContext context) {
    final cadence =
        (lastSession?['cadence'] as double?)?.toStringAsFixed(0) ?? '--';
    final symmetry =
        (lastSession?['symmetry'] as double?)?.toStringAsFixed(0) ?? '--';
    final stride =
        (lastSession?['stride_length'] as double?)?.toStringAsFixed(2) ?? '--';

    return Row(
      children: [
        Expanded(
            child: MetricCard(
          label: 'Cadence',
          value: cadence,
          unit: 'spm',
          icon: Icons.speed_rounded,
          color: AppColors.primary,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: MetricCard(
          label: 'Symmetry',
          value: symmetry,
          unit: '%',
          icon: Icons.balance_rounded,
          color: AppColors.secondary,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: MetricCard(
          label: 'Stride',
          value: stride,
          unit: 'm',
          icon: Icons.straighten_rounded,
          color: AppColors.primary,
        )),
      ],
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
