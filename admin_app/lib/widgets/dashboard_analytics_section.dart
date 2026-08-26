import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/case_utils.dart';

class DashboardAnalyticsSection extends StatefulWidget {
  final bool isDesktop;
  final ValueChanged<int>? onNavigate;

  const DashboardAnalyticsSection({
    super.key,
    required this.isDesktop,
    this.onNavigate,
  });

  @override
  State<DashboardAnalyticsSection> createState() => _DashboardAnalyticsSectionState();
}

class _DashboardAnalyticsSectionState extends State<DashboardAnalyticsSection> {
  int _selectedTrendDays = 365; // Default 1 Year (7, 30, 180, 365)

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics & Trends',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Case filing patterns, yearly trends and crime type breakdown',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insights_rounded, size: 15, color: Color(0xFF2563EB)),
                  SizedBox(width: 5),
                  Text(
                    'Real-time Intelligence',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Stream of Cases from Firestore for live analytics
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('cases').snapshots(),
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
            final docs = snapshot.data?.docs ?? [];

            return _CasesTrendGraphCard(
              docs: docs,
              isLoading: isLoading,
              days: _selectedTrendDays,
              isDesktop: widget.isDesktop,
              onDaysChanged: (days) => setState(() => _selectedTrendDays = days),
              onNavigateToCases: () => widget.onNavigate?.call(3),
            );
          },
        ),
      ],
    );
  }
}

// Fixed, consistent color palette per crime category
const Map<String, Color> kCrimeCategoryColors = {
  'Murder': Color(0xFFEF4444),
  'Attempt to Murder': Color(0xFFDC2626),
  'Kidnapping': Color(0xFFF97316),
  'Theft': Color(0xFFF59E0B),
  'Robbery': Color(0xFFD97706),
  'Accident': Color(0xFF06B6D4),
  'Missing Person': Color(0xFF8B5CF6),
  'Non-Cognizable (NC)': Color(0xFF10B981),
  'Summons & Warrants': Color(0xFF6366F1),
  'Crime Detail Form': Color(0xFFEC4899),
  'Property & Seizure': Color(0xFF14B8A6),
  'Women & Child Safety': Color(0xFFF43F5E),
  'Narcotics (NDPS)': Color(0xFF7C3AED),
  'Cyber & Fraud': Color(0xFF3B82F6),
  'General Case': Color(0xFF64748B),
};

const List<Color> kDynamicCrimePalette = [
  Color(0xFFEF4444), // Red
  Color(0xFFF59E0B), // Amber
  Color(0xFF64748B), // Slate / Cognizable
  Color(0xFF3B82F6), // Blue
  Color(0xFF8B5CF6), // Purple
  Color(0xFF10B981), // Emerald
  Color(0xFFEC4899), // Pink
  Color(0xFF06B6D4), // Cyan
  Color(0xFFF97316), // Orange
  Color(0xFF6366F1), // Indigo
];

Color getCrimeCategoryColor(String category, [int index = 0]) {
  if (kCrimeCategoryColors.containsKey(category)) {
    return kCrimeCategoryColors[category]!;
  }
  final hash = category.hashCode.abs();
  return kDynamicCrimePalette[(hash + index) % kDynamicCrimePalette.length];
}

String resolveCaseType(Map<String, dynamic> data) {
  final raw = (data['caseType'] ??
          data['crimeType'] ??
          data['classificationType'] ??
          data['category'] ??
          data['type'] ??
          data['formType'] ??
          data['title'] ??
          data['sections'] ??
          '')
      .toString()
      .trim();

  if (raw.isEmpty || raw.toLowerCase() == 'null') {
    return 'General Case';
  }

  // Strip case numbers / IDs attached after delimiters (e.g. "Murder — 12121" -> "Murder")
  String cleaned = raw;
  if (cleaned.contains('—')) {
    cleaned = cleaned.split('—').first.trim();
  } else if (cleaned.contains(' - ')) {
    cleaned = cleaned.split(' - ').first.trim();
  } else if (cleaned.contains(':')) {
    cleaned = cleaned.split(':').first.trim();
  }

  // Remove trailing numbers, slashes, or special characters
  cleaned = cleaned.replaceAll(RegExp(r'[\d\\/]+$'), '').trim();

  final lower = cleaned.toLowerCase();

  // Normalize into clean, standard police crime classifications
  if (lower.contains('attempt') && lower.contains('murder')) {
    return 'Attempt to Murder';
  }
  if (lower.contains('murder') || lower.contains('302') || lower.contains('homicide')) {
    return 'Murder';
  }
  if (lower.contains('kidnap') || lower.contains('363') || lower.contains('abduct')) {
    return 'Kidnapping';
  }
  if (lower.contains('robbery') || lower.contains('392') || lower.contains('394')) {
    return 'Robbery';
  }
  if (lower.contains('theft') || lower.contains('379') || lower.contains('burglary') || lower.contains('snatch')) {
    return 'Theft';
  }
  if (lower.contains('accident') || lower.contains('mva') || lower.contains('hit and run') || lower.contains('304a')) {
    return 'Accident';
  }
  if (lower.contains('missing')) {
    return 'Missing Person';
  }
  if (lower.contains('n.c') || lower.contains('nc') || lower.contains('non-cognizable')) {
    return 'Non-Cognizable (NC)';
  }
  if (lower.contains('warrant') || lower.contains('sam') || lower.contains('summons')) {
    return 'Summons & Warrants';
  }
  if (lower.contains('pocso') || lower.contains('rape') || lower.contains('376') || lower.contains('women')) {
    return 'Women & Child Safety';
  }
  if (lower.contains('ndps') || lower.contains('drug') || lower.contains('narcotic')) {
    return 'Narcotics (NDPS)';
  }
  if (lower.contains('seizure') || lower.contains('property')) {
    return 'Property & Seizure';
  }
  if (lower.contains('crime detail') || lower.contains('form i-v') || lower.contains('form vi') || lower.contains('form')) {
    return 'Crime Detail Form';
  }
  if (lower.contains('cyber') || lower.contains('fraud') || lower.contains('420')) {
    return 'Cyber & Fraud';
  }

  // Capitalize first letter cleanly if not matched above
  if (cleaned.isNotEmpty) {
    return cleaned[0].toUpperCase() + (cleaned.length > 1 ? cleaned.substring(1) : '');
  }

  return 'General Case';
}

// =============================================================================
// 📈 1. CASES TREND GRAPH CARD (Line / Area Chart + By Crime Type Breakdown)
// =============================================================================
class _CasesTrendGraphCard extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final bool isLoading;
  final int days;
  final bool isDesktop;
  final ValueChanged<int> onDaysChanged;
  final VoidCallback? onNavigateToCases;

  const _CasesTrendGraphCard({
    required this.docs,
    required this.isLoading,
    required this.days,
    required this.isDesktop,
    required this.onDaysChanged,
    this.onNavigateToCases,
  });

  @override
  State<_CasesTrendGraphCard> createState() => _CasesTrendGraphCardState();
}

class _CasesTrendGraphCardState extends State<_CasesTrendGraphCard> {
  bool _showByCrimeType = false; // Toggle: Overall vs By Crime Type
  final Set<String> _hiddenCrimeTypes = {}; // Interactive hide/show toggles
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isYearlyOrMultiMonth = widget.days >= 180;

    // Time buckets
    final List<DateTime> timeBuckets = [];
    final List<String> bucketLabels = [];

    if (isYearlyOrMultiMonth) {
      final monthsCount = widget.days == 365 ? 12 : 6;
      for (int i = monthsCount - 1; i >= 0; i--) {
        final dt = DateTime(now.year, now.month - i, 1);
        timeBuckets.add(dt);
        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        bucketLabels.add(monthNames[dt.month - 1]);
      }
    } else {
      final today = DateTime(now.year, now.month, now.day);
      for (int i = widget.days - 1; i >= 0; i--) {
        final dt = today.subtract(Duration(days: i));
        timeBuckets.add(dt);
        bucketLabels.add('${dt.day}/${dt.month}');
      }
    }

    final bucketCount = timeBuckets.length;
    final filedCounts = List<int>.filled(bucketCount, 0);
    final disposedCounts = List<int>.filled(bucketCount, 0);

    // 1. Dynamically extract DISTINCT crime categories present in actual database records
    final Map<String, int> totalCategoryOccurrences = {};
    for (final doc in widget.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final crimeType = resolveCaseType(data);
      totalCategoryOccurrences[crimeType] = (totalCategoryOccurrences[crimeType] ?? 0) + 1;
    }

    // Sort distinct categories by occurrence count descending (highest volume first)
    final List<String> distinctCrimeTypes = totalCategoryOccurrences.keys.toList()
      ..sort((a, b) => totalCategoryOccurrences[b]!.compareTo(totalCategoryOccurrences[a]!));

    // Per crime type series (only instantiated for real existing categories)
    final Map<String, List<int>> crimeTypeSeries = {};
    for (final cat in distinctCrimeTypes) {
      crimeTypeSeries[cat] = List<int>.filled(bucketCount, 0);
    }

    // Current window counts for legend
    final currentWindowStart = now.subtract(Duration(days: widget.days));
    final Map<String, int> currentPeriodCounts = {};

    for (final cat in distinctCrimeTypes) {
      currentPeriodCounts[cat] = 0;
    }

    for (final doc in widget.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dynamic createdRaw = data['createdAt'] ?? data['date'] ?? data['incidentDate'];
      final isDisposed = CaseUtils.isDisposed(data);
      final crimeType = resolveCaseType(data);

      DateTime? createdDt;
      if (createdRaw is Timestamp) {
        createdDt = createdRaw.toDate();
      } else if (createdRaw is String) {
        createdDt = DateTime.tryParse(createdRaw);
      }

      if (createdDt != null) {
        if (createdDt.isAfter(currentWindowStart)) {
          currentPeriodCounts[crimeType] = (currentPeriodCounts[crimeType] ?? 0) + 1;
        }

        // Plot bucket matching
        if (isYearlyOrMultiMonth) {
          for (int b = 0; b < bucketCount; b++) {
            final bDt = timeBuckets[b];
            if (createdDt.year == bDt.year && createdDt.month == bDt.month) {
              filedCounts[b]++;
              if (isDisposed) disposedCounts[b]++;
              if (!crimeTypeSeries.containsKey(crimeType)) {
                crimeTypeSeries[crimeType] = List<int>.filled(bucketCount, 0);
              }
              crimeTypeSeries[crimeType]![b]++;
              break;
            }
          }
        } else {
          final today = DateTime(now.year, now.month, now.day);
          final cDate = DateTime(createdDt.year, createdDt.month, createdDt.day);
          final diffDays = today.difference(cDate).inDays;
          if (diffDays >= 0 && diffDays < widget.days) {
            final idx = widget.days - 1 - diffDays;
            if (idx >= 0 && idx < bucketCount) {
              filedCounts[idx]++;
              if (isDisposed) disposedCounts[idx]++;
              if (!crimeTypeSeries.containsKey(crimeType)) {
                crimeTypeSeries[crimeType] = List<int>.filled(bucketCount, 0);
              }
              crimeTypeSeries[crimeType]![idx]++;
            }
          }
        }
      }
    }

    final totalFiled = filedCounts.fold<int>(0, (a, b) => a + b);
    final totalDisposed = disposedCounts.fold<int>(0, (a, b) => a + b);

    // Calculate max value for Y-axis scale
    int maxVal = 1;
    if (_showByCrimeType) {
      for (final entry in crimeTypeSeries.entries) {
        if (!_hiddenCrimeTypes.contains(entry.key)) {
          for (final val in entry.value) {
            if (val > maxVal) maxVal = val;
          }
        }
      }
    } else {
      maxVal = math.max(1, [
        ...filedCounts,
        ...disposedCounts,
      ].fold<int>(0, (prev, e) => math.max(prev, e)));
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Controls Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.show_chart_rounded, color: Color(0xFF2563EB), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _showByCrimeType ? 'Crime-Type Dynamics & Trends' : 'Cases Trend Analysis',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _showByCrimeType
                              ? 'Month-over-month trajectory by crime classification'
                              : 'Filed vs. Disposed registration volume over time',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                // View Mode & Range Switchers
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Mode Switcher: Overall vs By Crime Type
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeBtn('Overall', false),
                          _buildModeBtn('By Crime Type', true),
                        ],
                      ),
                    ),

                    // Range Switcher: 7D / 30D / 6M / 1Y
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRangeBtn('7 Days', 7),
                          _buildRangeBtn('30 Days', 30),
                          _buildRangeBtn('6 Months', 180),
                          _buildRangeBtn('1 Year', 365),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Legend & Interactive Filter Bar
            if (!_showByCrimeType)
              Row(
                children: [
                  _buildLegendPill('Filed Cases', const Color(0xFF2563EB), totalFiled, null),
                  const SizedBox(width: 16),
                  _buildLegendPill('Disposed Cases', const Color(0xFF10B981), totalDisposed, null),
                  const Spacer(),
                  if (_hoveredIndex != null && _hoveredIndex! < bucketCount)
                    _buildHoverBadge('${bucketLabels[_hoveredIndex!]}: ${filedCounts[_hoveredIndex!]} Filed, ${disposedCounts[_hoveredIndex!]} Disposed'),
                ],
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...distinctCrimeTypes.map((cat) {
                    final color = getCrimeCategoryColor(cat);
                    final count = currentPeriodCounts[cat] ?? 0;
                    final isHidden = _hiddenCrimeTypes.contains(cat);
                    return _buildLegendPill(
                      cat,
                      color,
                      count,
                      () {
                        setState(() {
                          if (isHidden) {
                            _hiddenCrimeTypes.remove(cat);
                          } else {
                            _hiddenCrimeTypes.add(cat);
                          }
                        });
                      },
                      isHidden: isHidden,
                    );
                  }),
                  if (_hoveredIndex != null && _hoveredIndex! < bucketCount)
                    _buildHoverBadge('${bucketLabels[_hoveredIndex!]} Point Inspected'),
                ],
              ),

            const SizedBox(height: 18),

            // Line Chart Canvas Area
            SizedBox(
              height: 240,
              child: widget.isLoading
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  : (totalFiled == 0 && totalDisposed == 0)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.analytics_outlined, size: 36, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              const Text(
                                'No case records registered in this time period',
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : MouseRegion(
                          onHover: (event) {
                            final box = context.findRenderObject() as RenderBox?;
                            if (box != null) {
                              final localX = event.localPosition.dx - 30; // padding offset
                              final chartW = box.size.width - 60;
                              if (chartW > 0) {
                                final idx = ((localX / chartW) * (bucketCount - 1)).round().clamp(0, bucketCount - 1);
                                if (_hoveredIndex != idx) {
                                  setState(() => _hoveredIndex = idx);
                                }
                              }
                            }
                          },
                          onExit: (_) => setState(() => _hoveredIndex = null),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _MultiSeriesTrendPainter(
                              labels: bucketLabels,
                              showByCrimeType: _showByCrimeType,
                              filed: filedCounts,
                              disposed: disposedCounts,
                              crimeTypeSeries: crimeTypeSeries,
                              hiddenCrimeTypes: _hiddenCrimeTypes,
                              maxVal: maxVal,
                              hoveredIndex: _hoveredIndex,
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBtn(String label, bool isCrimeTypeMode) {
    final isSelected = _showByCrimeType == isCrimeTypeMode;
    return GestureDetector(
      onTap: () => setState(() => _showByCrimeType = isCrimeTypeMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeBtn(String label, int val) {
    final isSelected = widget.days == val;
    return GestureDetector(
      onTap: () => widget.onDaysChanged(val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendPill(
    String label,
    Color color,
    int count,
    VoidCallback? onTap, {
    bool isHidden = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isHidden ? 0.35 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isHidden ? const Color(0xFFF1F5F9) : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isHidden ? const Color(0xFFCBD5E1) : color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isHidden ? Colors.grey : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isHidden ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                  decoration: isHidden ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isHidden ? const Color(0xFF94A3B8) : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoverBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// 🎨 Custom Painter for Multi-Series Trend Curves
class _MultiSeriesTrendPainter extends CustomPainter {
  final List<String> labels;
  final bool showByCrimeType;
  final List<int> filed;
  final List<int> disposed;
  final Map<String, List<int>> crimeTypeSeries;
  final Set<String> hiddenCrimeTypes;
  final int maxVal;
  final int? hoveredIndex;

  _MultiSeriesTrendPainter({
    required this.labels,
    required this.showByCrimeType,
    required this.filed,
    required this.disposed,
    required this.crimeTypeSeries,
    required this.hiddenCrimeTypes,
    required this.maxVal,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 35.0;
    const padB = 25.0;
    final w = size.width - padL - 10;
    final h = size.height - padB - 10;

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    const textStyle = TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w500);

    // Draw horizontal grid lines & Y-axis labels
    const gridSteps = 4;
    for (int i = 0; i <= gridSteps; i++) {
      final y = 10 + (h / gridSteps) * i;
      final val = (maxVal * (gridSteps - i) / gridSteps).round();
      canvas.drawLine(Offset(padL, y), Offset(size.width - 10, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(text: '$val', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padL - tp.width - 6, y - tp.height / 2));
    }

    final n = labels.length;
    if (n < 2) return;

    if (!showByCrimeType) {
      // 1. Overall: Filed vs Disposed
      final filedPoints = <Offset>[];
      final disposedPoints = <Offset>[];

      for (int i = 0; i < n; i++) {
        final x = padL + (w / (n - 1)) * i;
        final yF = 10 + h - (filed[i] / maxVal) * h;
        final yD = 10 + h - (disposed[i] / maxVal) * h;
        filedPoints.add(Offset(x, yF));
        disposedPoints.add(Offset(x, yD));
      }

      _drawCurvedArea(canvas, filedPoints, h + 10, const Color(0xFF2563EB));
      _drawCurvedArea(canvas, disposedPoints, h + 10, const Color(0xFF10B981));
      _drawCurvedLine(canvas, filedPoints, const Color(0xFF2563EB), 2.5);
      _drawCurvedLine(canvas, disposedPoints, const Color(0xFF10B981), 2.5);

      for (int i = 0; i < n; i++) {
        final isHovered = hoveredIndex == i;
        _drawDot(canvas, filedPoints[i], const Color(0xFF2563EB), isHovered);
        _drawDot(canvas, disposedPoints[i], const Color(0xFF10B981), isHovered);
      }
    } else {
      // 2. By Crime Type Series
      for (final entry in crimeTypeSeries.entries) {
        if (hiddenCrimeTypes.contains(entry.key)) continue;
        final color = getCrimeCategoryColor(entry.key);
        final points = <Offset>[];

        for (int i = 0; i < n; i++) {
          final x = padL + (w / (n - 1)) * i;
          final y = 10 + h - (entry.value[i] / maxVal) * h;
          points.add(Offset(x, y));
        }

        _drawCurvedArea(canvas, points, h + 10, color.withValues(alpha: 0.15));
        _drawCurvedLine(canvas, points, color, 2.2);

        for (int i = 0; i < n; i++) {
          final isHovered = hoveredIndex == i;
          _drawDot(canvas, points[i], color, isHovered);
        }
      }
    }

    // Hover vertical indicator line
    if (hoveredIndex != null && hoveredIndex! < n) {
      final x = padL + (w / (n - 1)) * hoveredIndex!;
      canvas.drawLine(
        Offset(x, 10),
        Offset(x, h + 10),
        Paint()
          ..color = const Color(0xFF64748B).withValues(alpha: 0.3)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
    }

    // Draw X-Axis Date/Month Labels
    final step = (n / 12).ceil().clamp(1, n);
    for (int i = 0; i < n; i += step) {
      final x = padL + (w / (n - 1)) * i;
      final lbl = labels[i];
      final tp = TextPainter(
        text: TextSpan(text: lbl, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - padB + 6));
    }
  }

  void _drawDot(Canvas canvas, Offset pt, Color color, bool isHovered) {
    canvas.drawCircle(pt, isHovered ? 5.5 : 3.5, Paint()..color = Colors.white);
    canvas.drawCircle(pt, isHovered ? 4.2 : 2.5, Paint()..color = color);
  }

  void _drawCurvedArea(Canvas canvas, List<Offset> points, double bottomY, Color color) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, bottomY);
    path.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }
    path.lineTo(points.last.dx, bottomY);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(points.first.dx, 0, points.last.dx, bottomY));

    canvas.drawPath(path, paint);
  }

  void _drawCurvedLine(Canvas canvas, List<Offset> points, Color color, double strokeWidth) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MultiSeriesTrendPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.showByCrimeType != showByCrimeType ||
        oldDelegate.hiddenCrimeTypes != hiddenCrimeTypes ||
        oldDelegate.labels != labels ||
        oldDelegate.filed != filed ||
        oldDelegate.disposed != disposed;
  }
}



