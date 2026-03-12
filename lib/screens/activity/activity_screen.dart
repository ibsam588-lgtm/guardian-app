import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart' show _BottomNav;

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Screen Time & Activity'),
        backgroundColor: AppColors.navy,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _WeeklyBarChart(),
            _AppUsageCard(),
            _TimeLimitsCard(),
            _WebSitesCard(),
            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 2),
    );
  }
}

// ── Weekly bar chart using fl_chart ───────────
class _WeeklyBarChart extends StatelessWidget {
  final List<double> hours = const [3.2, 4.1, 3.8, 4.2, 0, 0, 0];
  final List<String> days = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('4h 12m', style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, fontFamily: 'Nunito',
                    )),
                    const Text('Total screen time today', style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted, fontFamily: 'Nunito',
                    )),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.amberLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('+22% vs avg', style: TextStyle(
                    color: AppColors.amber, fontSize: 11,
                    fontWeight: FontWeight.w700, fontFamily: 'Nunito',
                  )),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 6,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) => Text(
                          days[v.toInt()],
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                            color: v.toInt() == 3 ? AppColors.blue : AppColors.textMuted,
                          ),
                        ),
                        reservedSize: 20,
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(7, (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: hours[i],
                        color: i == 3 ? AppColors.blue : const Color(0xFFCBD5E1),
                        width: 28,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App usage list ─────────────────────────────
class _AppUsageCard extends StatelessWidget {
  final apps = const [
    _AppData('TikTok', 120, 120, AppColors.red, AppColors.redLight),
    _AppData('YouTube', 45, 90, AppColors.amber, AppColors.amberLight),
    _AppData('Roblox', 30, 60, AppColors.purple, AppColors.purpleLight),
    _AppData('WhatsApp', 22, 60, AppColors.green, AppColors.greenLight),
    _AppData('Chrome', 15, 60, AppColors.blue, AppColors.blueLight),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('APP USAGE', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted,
                  fontFamily: 'Nunito', letterSpacing: 0.5,
                )),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('Set Limits', style: TextStyle(
                    color: AppColors.blue, fontSize: 12,
                    fontWeight: FontWeight.w700, fontFamily: 'Nunito',
                  )),
                ),
              ],
            ),
            ...apps.map((a) => _AppUsageRow(app: a)),
          ],
        ),
      ),
    );
  }
}

class _AppData {
  final String name;
  final int used, limit;
  final Color color, bg;
  const _AppData(this.name, this.used, this.limit, this.color, this.bg);

  String get formattedTime {
    if (used < 60) return '${used}m';
    return '${used ~/ 60}h ${used % 60 > 0 ? '${used % 60}m' : ''}';
  }

  double get pct => used / limit;
  bool get isMaxed => used >= limit;
}

class _AppUsageRow extends StatelessWidget {
  final _AppData app;
  const _AppUsageRow({required this.app});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: app.bg, borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(app.name[0], style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: app.color, fontFamily: 'Nunito',
              )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(app.name, style: const TextStyle(
                      fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 13,
                    )),
                    if (app.isMaxed) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.redLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Limit reached', style: TextStyle(
                          color: AppColors.red, fontSize: 9,
                          fontWeight: FontWeight.w700, fontFamily: 'Nunito',
                        )),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: app.pct.clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation(app.color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(app.formattedTime, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.textMuted, fontFamily: 'Nunito',
          )),
        ],
      ),
    );
  }
}

// ── Time limits toggles ────────────────────────
class _TimeLimitsCard extends StatefulWidget {
  @override
  State<_TimeLimitsCard> createState() => _TimeLimitsCardState();
}

class _TimeLimitsCardState extends State<_TimeLimitsCard> {
  bool _tiktokLimit = true;
  bool _ytLimit = true;
  bool _gamingLimit = true;
  bool _bedtime = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DAILY TIME LIMITS', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted,
              fontFamily: 'Nunito', letterSpacing: 0.5,
            )),
            const SizedBox(height: 12),
            _LimitRow(title: 'TikTok', sub: '2 hrs/day · Used: 2h (maxed)',
                value: _tiktokLimit, onChanged: (v) => setState(() => _tiktokLimit = v)),
            _LimitRow(title: 'YouTube', sub: '1.5 hrs/day · Used: 45m',
                value: _ytLimit, onChanged: (v) => setState(() => _ytLimit = v)),
            _LimitRow(title: 'Gaming (all apps)', sub: '1 hr/day · Used: 30m',
                value: _gamingLimit, onChanged: (v) => setState(() => _gamingLimit = v)),
            _LimitRow(title: 'Bedtime Lock', sub: 'All apps blocked 9:30 PM – 7:00 AM',
                value: _bedtime, onChanged: (v) => setState(() => _bedtime = v), last: true),
          ],
        ),
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  final String title, sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;
  const _LimitRow({
    required this.title, required this.sub,
    required this.value, required this.onChanged, this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: last ? null : const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 14,
                )),
                Text(sub, style: const TextStyle(
                  color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 12,
                )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.blue,
          ),
        ],
      ),
    );
  }
}

// ── Web sites ──────────────────────────────────
class _WebSitesCard extends StatelessWidget {
  final sites = const [
    _SiteData('YouTube', 'Y', Color(0xFFEF4444), '47 visits', true),
    _SiteData('Wikipedia', 'W', Color(0xFF1A56DB), '12 visits', true),
    _SiteData('Roblox', 'R', Color(0xFF8B5CF6), '8 visits', true),
    _SiteData('Discord', 'D', Color(0xFF5865F2), '5 visits', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('TOP SITES TODAY', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted,
                fontFamily: 'Nunito', letterSpacing: 0.5,
              )),
            ),
            const SizedBox(height: 12),
            ...sites.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: s.color, borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(s.initial, style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800,
                      fontSize: 14, fontFamily: 'Nunito',
                    ))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(
                          fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 13,
                        )),
                        Text(s.visits, style: const TextStyle(
                          color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 11,
                        )),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: s.isSafe ? AppColors.greenLight : AppColors.amberLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s.isSafe ? 'Safe' : 'Review',
                        style: TextStyle(
                          color: s.isSafe ? AppColors.green : AppColors.amber,
                          fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Nunito',
                        )),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _SiteData {
  final String name, initial, visits;
  final Color color;
  final bool isSafe;
  const _SiteData(this.name, this.initial, this.color, this.visits, this.isSafe);
}
