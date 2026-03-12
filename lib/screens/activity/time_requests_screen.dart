import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../models/time_request.dart';
import '../../services/time_request_service.dart';

// ─────────────────────────────────────────────
//  Full screen: all time requests
// ─────────────────────────────────────────────
class TimeRequestsScreen extends StatelessWidget {
  const TimeRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = TimeRequestService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Time Requests'),
        backgroundColor: AppColors.navy,
      ),
      body: StreamBuilder<List<TimeRequest>>(
        stream: svc.watchAllRequests(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snap.data ?? [];
          final pending = requests.where((r) => r.isPending && !r.isExpired).toList();
          final history = requests.where((r) => !r.isPending || r.isExpired).toList();

          if (requests.isEmpty) {
            return const _EmptyState();
          }

          return ListView(
            children: [
              if (pending.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Waiting for your response',
                  badge: '${pending.length}',
                  badgeColor: AppColors.red,
                ),
                ...pending.map((r) => _PendingRequestCard(request: r, service: svc)),
              ],
              if (history.isNotEmpty) ...[
                const _SectionHeader(title: 'Request history'),
                ...history.map((r) => _HistoryRequestCard(request: r)),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Pending request card — full action
// ─────────────────────────────────────────────
class _PendingRequestCard extends StatefulWidget {
  final TimeRequest request;
  final TimeRequestService service;
  const _PendingRequestCard({required this.request, required this.service});

  @override
  State<_PendingRequestCard> createState() => _PendingRequestCardState();
}

class _PendingRequestCardState extends State<_PendingRequestCard> {
  late Timer _timer;
  bool _responding = false;
  int _customMinutes = 0;

  @override
  void initState() {
    super.initState();
    _customMinutes = widget.request.requestedMinutes;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Duration get _remaining => widget.request.expiresAt.difference(DateTime.now());
  bool get _isExpired => _remaining.isNegative;
  double get _progress => _isExpired
      ? 0
      : _remaining.inSeconds /
          widget.request.expiresAt
              .difference(widget.request.createdAt)
              .inSeconds;

  Color get _appColor {
    final hex = widget.request.appIconColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Future<void> _approve([int? mins]) async {
    setState(() => _responding = true);
    await widget.service.approveRequest(widget.request,
        customMinutes: mins ?? _customMinutes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${widget.request.childName} gets ${mins ?? _customMinutes} more minutes on ${widget.request.appName}!'),
        backgroundColor: AppColors.green,
      ));
    }
  }

  Future<void> _deny() async {
    setState(() => _responding = true);
    await widget.service.denyRequest(widget.request.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Request denied for ${widget.request.appName}.'),
        backgroundColor: AppColors.textMuted,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isExpired ? AppColors.border : AppColors.amber.withOpacity(0.5),
          width: _isExpired ? 1 : 2,
        ),
        boxShadow: _isExpired ? [] : [
          BoxShadow(
            color: AppColors.amber.withOpacity(0.15),
            blurRadius: 12, offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                // App icon
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _appColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(
                    widget.request.appName[0],
                    style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: _appColor, fontFamily: 'Nunito',
                    ),
                  )),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Nunito', fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: widget.request.childName,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const TextSpan(text: ' wants more time on '),
                            TextSpan(
                              text: widget.request.appName,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.purpleLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Requested: ${widget.request.requestedMinutes} min',
                              style: const TextStyle(
                                color: AppColors.purple, fontSize: 11,
                                fontWeight: FontWeight.w700, fontFamily: 'Nunito',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Child note (if any)
          if (widget.request.childNote != null &&
              widget.request.childNote!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    '"${widget.request.childNote}"',
                    style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 13,
                      fontStyle: FontStyle.italic, color: AppColors.textPrimary,
                    ),
                  )),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Countdown timer bar
          if (!_isExpired)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Auto-denies in', style: TextStyle(
                        color: AppColors.textMuted, fontSize: 11,
                        fontFamily: 'Nunito', fontWeight: FontWeight.w600,
                      )),
                      Text(
                        '${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: _remaining.inMinutes < 2
                              ? AppColors.red : AppColors.amber,
                          fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress.clamp(0.0, 1.0),
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(
                        _remaining.inMinutes < 2 ? AppColors.red : AppColors.amber,
                      ),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Request expired — no response given',
                    style: TextStyle(
                      color: AppColors.textMuted, fontSize: 11,
                      fontFamily: 'Nunito', fontWeight: FontWeight.w600,
                    )),
              ),
            ),

          // Grant time picker + action buttons
          if (!_isExpired && !_responding) ...[
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Grant how much time?', style: TextStyle(
                fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 13,
              )),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [15, 30, 60].map((min) {
                  final selected = _customMinutes == min;
                  return GestureDetector(
                    onTap: () => setState(() => _customMinutes = min),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.blue : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.blue : AppColors.border,
                        ),
                      ),
                      child: Text(_fmtMins(min), style: TextStyle(
                        color: selected ? Colors.white : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito', fontSize: 13,
                      )),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deny,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Deny'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: const BorderSide(color: AppColors.red),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _approve(_customMinutes),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text('Allow $_customMinutes min'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_responding) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else ...[
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  String _fmtMins(int m) {
    if (m < 60) return '${m}m';
    return '${m ~/ 60}h';
  }
}

// ─────────────────────────────────────────────
//  History card — compact read-only
// ─────────────────────────────────────────────
class _HistoryRequestCard extends StatelessWidget {
  final TimeRequest request;
  const _HistoryRequestCard({required this.request});

  Color get _appColor {
    final hex = request.appIconColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    switch (request.status) {
      case TimeRequestStatus.approved:
        statusColor = AppColors.green;
        statusBg = AppColors.greenLight;
        statusLabel = 'Approved · ${request.grantedMinutes}m granted';
        statusIcon = Icons.check_circle_outline;
      case TimeRequestStatus.denied:
        statusColor = AppColors.red;
        statusBg = AppColors.redLight;
        statusLabel = 'Denied';
        statusIcon = Icons.cancel_outlined;
      case TimeRequestStatus.expired:
      default:
        statusColor = AppColors.textMuted;
        statusBg = AppColors.surfaceSecondary;
        statusLabel = 'Expired — no response';
        statusIcon = Icons.timer_off_outlined;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _appColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(request.appName[0], style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800,
              color: _appColor, fontFamily: 'Nunito',
            ))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${request.childName} · ${request.appName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito', fontSize: 13,
                    )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusLabel, style: TextStyle(
                      color: statusColor, fontSize: 11,
                      fontWeight: FontWeight.w700, fontFamily: 'Nunito',
                    )),
                  ],
                ),
              ],
            ),
          ),
          Text(
            _timeAgo(request.createdAt),
            style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11, fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─────────────────────────────────────────────
//  Inline notification banner (used in home screen / alerts)
// ─────────────────────────────────────────────
class TimeRequestBanner extends StatefulWidget {
  final TimeRequest request;
  final TimeRequestService service;
  const TimeRequestBanner({
    super.key,
    required this.request,
    required this.service,
  });

  @override
  State<TimeRequestBanner> createState() => _TimeRequestBannerState();
}

class _TimeRequestBannerState extends State<TimeRequestBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _slide;
  bool _responding = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Color get _appColor {
    final hex = widget.request.appIconColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_slide),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.amber, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber.withOpacity(0.2),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _appColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(widget.request.appName[0], style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: _appColor, fontFamily: 'Nunito',
                  ))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textPrimary),
                      children: [
                        TextSpan(text: widget.request.childName,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        const TextSpan(text: ' is asking for '),
                        TextSpan(text: '${widget.request.requestedMinutes} more min',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        const TextSpan(text: ' on '),
                        TextSpan(text: widget.request.appName,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (widget.request.childNote != null) ...[
              const SizedBox(height: 8),
              Text('"${widget.request.childNote}"', style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 12,
                fontStyle: FontStyle.italic, color: AppColors.textMuted,
              )),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _responding ? null : () async {
                      setState(() => _responding = true);
                      await widget.service.denyRequest(widget.request.id);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      minimumSize: const Size(0, 38),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Deny', style: TextStyle(fontFamily: 'Nunito', fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _responding ? null : () async {
                      setState(() => _responding = true);
                      await widget.service.approveRequest(widget.request);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      minimumSize: const Size(0, 38),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Allow ${widget.request.requestedMinutes} min',
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CHILD SIDE: Request More Time screen
//  (This lives in the GuardIan Child App)
// ─────────────────────────────────────────────
class ChildRequestTimeScreen extends StatefulWidget {
  final String appName;
  final String packageName;
  final String appIconColor;
  final String childId;
  final String childName;
  final String parentUid;

  const ChildRequestTimeScreen({
    super.key,
    required this.appName,
    required this.packageName,
    required this.appIconColor,
    required this.childId,
    required this.childName,
    required this.parentUid,
  });

  @override
  State<ChildRequestTimeScreen> createState() => _ChildRequestTimeScreenState();
}

class _ChildRequestTimeScreenState extends State<ChildRequestTimeScreen> {
  int _selectedMinutes = 15;
  String _note = '';
  bool _sending = false;
  bool _sent = false;
  final _noteCtrl = TextEditingController();
  final _svc = TimeRequestService();

  Color get _appColor {
    final hex = widget.appIconColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Future<void> _sendRequest() async {
    setState(() => _sending = true);
    await _svc.sendTimeRequest(
      childId: widget.childId,
      childName: widget.childName,
      parentUid: widget.parentUid,
      appName: widget.appName,
      packageName: widget.packageName,
      appIconColor: widget.appIconColor,
      requestedMinutes: _selectedMinutes,
      childNote: _note.trim().isEmpty ? null : _note.trim(),
    );
    setState(() { _sending = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSentState() : _buildRequestForm(),
        ),
      ),
    );
  }

  Widget _buildSentState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: AppColors.green, size: 48),
        ),
        const SizedBox(height: 24),
        const Text('Request sent!', style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Nunito',
        )),
        const SizedBox(height: 10),
        Text(
          'Your parent got a notification. Check back in a minute!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted, fontFamily: 'Nunito',
            fontSize: 15, height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        // Waiting animation dots
        _WaitingDots(),
        const SizedBox(height: 16),
        const Text('Waiting for parent response...', style: TextStyle(
          color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 13,
        )),
      ],
    );
  }

  Widget _buildRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App blocked banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.redLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _appColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(widget.appName[0], style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: _appColor, fontFamily: 'Nunito',
                ))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.appName, style: const TextStyle(
                      fontWeight: FontWeight.w800, fontFamily: 'Nunito', fontSize: 16,
                    )),
                    const Text('Your time limit is up for today', style: TextStyle(
                      color: AppColors.red, fontFamily: 'Nunito',
                      fontSize: 12, fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        const Text('Ask for more time', style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Nunito',
        )),
        const SizedBox(height: 6),
        const Text('Send a request to your parent. They\'ll get a notification!',
            style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 14)),

        const SizedBox(height: 28),

        const Text('How much extra time?', style: TextStyle(
          fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 15,
        )),
        const SizedBox(height: 12),

        // Time options
        Row(
          children: [
            _TimeOption(minutes: 15, selected: _selectedMinutes == 15,
                onTap: () => setState(() => _selectedMinutes = 15)),
            const SizedBox(width: 10),
            _TimeOption(minutes: 30, selected: _selectedMinutes == 30,
                onTap: () => setState(() => _selectedMinutes = 30)),
            const SizedBox(width: 10),
            _TimeOption(minutes: 60, selected: _selectedMinutes == 60,
                onTap: () => setState(() => _selectedMinutes = 60)),
          ],
        ),

        const SizedBox(height: 24),

        const Text('Leave a message for your parent (optional)', style: TextStyle(
          fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 14,
        )),
        const SizedBox(height: 8),
        TextField(
          controller: _noteCtrl,
          onChanged: (v) => setState(() => _note = v),
          maxLength: 100,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. Please! I\'m almost done with this level 🙏',
            counterText: '',
          ),
        ),

        const Spacer(),

        ElevatedButton(
          onPressed: _sending ? null : _sendRequest,
          child: _sending
              ? const SizedBox(height: 22, width: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text('Send Request for $_selectedMinutes minutes'),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go back', style: TextStyle(
              color: AppColors.textMuted, fontFamily: 'Nunito',
            )),
          ),
        ),
      ],
    );
  }
}

class _TimeOption extends StatelessWidget {
  final int minutes;
  final bool selected;
  final VoidCallback onTap;
  const _TimeOption({required this.minutes, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                minutes < 60 ? '$minutes' : '1',
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
              Text(
                minutes < 60 ? 'min' : 'hour',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: selected ? Colors.white70 : AppColors.textMuted,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaitingDots extends StatefulWidget {
  @override
  State<_WaitingDots> createState() => _WaitingDotsState();
}

class _WaitingDotsState extends State<_WaitingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final val = (((_ctrl.value + delay) % 1.0) < 0.5) ? 1.0 : 0.3;
            return Container(
              width: 10, height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(val),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Section header widget
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  final Color badgeColor;

  const _SectionHeader({
    required this.title,
    this.badge,
    this.badgeColor = AppColors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: AppColors.textMuted, fontFamily: 'Nunito', letterSpacing: 1,
          )),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badge!, style: const TextStyle(
                color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w700, fontFamily: 'Nunito',
              )),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Empty state
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.greenLight, shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                color: AppColors.green, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('No requests', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Nunito',
          )),
          const SizedBox(height: 8),
          const Text(
            'When Emma asks for extra time\non an app, you\'ll see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted, fontFamily: 'Nunito', height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
