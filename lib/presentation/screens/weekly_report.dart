import 'package:flutter/material.dart';

import '../../../controllers/weekly_report_controller.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/bottom_nav_bar.dart';
import '../../../widgets/button_gradient.dart';

class WeeklyReportPage extends StatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  State<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends State<WeeklyReportPage> {
  final WeeklyReportController _controller = WeeklyReportController();

  bool _isLoading = true;

  List<DailyMoodData> _thisWeekData = [];
  List<DailyMoodData> _compareWeekData = [];
  List<DailyMoodData> _trendData = [];

  WeeklyComparisonData? _comparison;

  DailyMoodData? _selectedThisWeekDay;
  DailyMoodData? _selectedCompareDay;
  DailyMoodData? _selectedTrendDay;

  DateTime? _compareStartDate;
  DateTime? _compareEndDate;

  int _trendDays = 7;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    final report = await _controller.getWeeklyReportData(
      compareStartDate: _compareStartDate,
      trendDays: _trendDays,
    );

    if (!mounted) return;

    setState(() {
      _thisWeekData = report.thisWeekData;
      _compareWeekData = report.compareWeekData;
      _trendData = report.trendData;
      _comparison = report.comparison;
      _compareStartDate = report.compareStartDate;
      _compareEndDate = report.compareEndDate;
      _isLoading = false;
    });
  }

  Future<void> _changeCompareWeek(int offsetDays) async {
    if (_compareStartDate == null) return;

    setState(() {
      _isLoading = true;
      _selectedCompareDay = null;
      _compareStartDate = _compareStartDate!.add(Duration(days: offsetDays));
    });

    await _loadWeeklyData();
  }

  bool _canGoForwardCompareWeek() {
    if (_compareStartDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final latestAllowedCompareStart = thisMonday.subtract(
      const Duration(days: 7),
    );

    return _compareStartDate!.isBefore(latestAllowedCompareStart);
  }

  Future<void> _changeTrendDays(int days) async {
    setState(() {
      _trendDays = days;
      _isLoading = true;
      _selectedTrendDay = null;
    });

    await _loadWeeklyData();
  }

  String _rangeText(List<DailyMoodData> data) {
    if (data.isEmpty) return '';

    final start = data.first.date.day;
    final end = data.last.date.day;

    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[data.first.date.month];
    return '$start - $end $month';
  }

  String _compareRangeText() {
    if (_compareStartDate == null || _compareEndDate == null) return '';
    return '${_compareStartDate!.day} - ${_compareEndDate!.day} ${_monthShort(_compareEndDate!.month)}';
  }

  String _monthShort(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  Color _barColor(int score) {
    if (score > 50) return const Color(0xFF9EF6B0);
    if (score == 50) return const Color(0xFFFFC56D);
    return const Color(0xFFE55151);
  }

  String _scoreLabel(DailyMoodData day) {
    if (day.score > 50) return '${day.score}% positive';
    if (day.score == 50) return '${day.score}% neutral';
    return '${day.score}% negative';
  }

  Color _scoreLabelColor(int score) {
    if (score > 50) return const Color(0xFF64F58D);
    if (score == 50) return const Color(0xFFFFC56D);
    return const Color(0xFFFF6B6B);
  }

  String _moodEmoji(int score) {
    if (score >= 70) return '😊';
    if (score >= 40) return '😐';
    return '☹️';
  }

  Color _moodBoxColor(int score) {
    if (score >= 70) return const Color(0xFF9EF6B0);
    if (score >= 40) return const Color(0xFFFFC56D);
    return const Color(0xFFFF6B6B);
  }

  String _trendTooltip(DailyMoodData day) {
    return '${day.dayLabel}, ${_monthShort(day.date.month)} ${day.date.day}\n${_moodEmoji(day.score)} ${day.mood} (${day.score}%)';
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: BottomNavBar(currentIndex: 1),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 100),
                  children: [
                    IconButton(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      icon: Image.asset(
                        'assets/images/back.png',
                        height: 24,
                        width: 24,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Weekly report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            "This week's report!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_comparison != null)
                          SizedBox(
                            width: 125,
                            child: Text(
                              _comparison!.message,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: _comparison!.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _MoodBarChart(
                      title: _rangeText(_thisWeekData),
                      data: _thisWeekData,
                      selectedDay: _selectedThisWeekDay,
                      onDayTap: (day) {
                        setState(() {
                          _selectedThisWeekDay = day;
                        });
                      },
                      barColor: _barColor,
                      scoreLabel: _scoreLabel,
                      scoreLabelColor: _scoreLabelColor,
                    ),

                    const SizedBox(height: 28),

                    _CompareHeader(
                      rangeText: _compareRangeText(),
                      onPrevious: () => _changeCompareWeek(-7),
                      onNext: _canGoForwardCompareWeek()
                          ? () => _changeCompareWeek(7)
                          : null,
                    ),

                    const SizedBox(height: 12),

                    _MoodBarChart(
                      title: 'Compared week',
                      data: _compareWeekData,
                      selectedDay: _selectedCompareDay,
                      onDayTap: (day) {
                        setState(() {
                          _selectedCompareDay = day;
                        });
                      },
                      barColor: _barColor,
                      scoreLabel: _scoreLabel,
                      scoreLabelColor: _scoreLabelColor,
                    ),

                    const SizedBox(height: 28),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: ButtonGradient.decoration(radius: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mood history',
                            style: TextStyle(
                              color: ButtonGradient.text,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _thisWeekData.map((day) {
                              return Container(
                                width: 42,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: _moodBoxColor(day.score),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _moodEmoji(day.score),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(height: 6),
                                    Column(
                                      children: [
                                        Text(
                                          day.dayLabel,
                                          style: const TextStyle(
                                            color: ButtonGradient.text,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${day.date.day}',
                                          style: const TextStyle(
                                            color: ButtonGradient.text,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: ButtonGradient.decoration(radius: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Mood trend',
                                  style: TextStyle(
                                    color: ButtonGradient.text,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              _TrendRangeButton(
                                text: '7d',
                                selected: _trendDays == 7,
                                onTap: () => _changeTrendDays(7),
                              ),
                              const SizedBox(width: 6),
                              _TrendRangeButton(
                                text: '14d',
                                selected: _trendDays == 14,
                                onTap: () => _changeTrendDays(14),
                              ),
                              const SizedBox(width: 6),
                              _TrendRangeButton(
                                text: '28d',
                                selected: _trendDays == 28,
                                onTap: () => _changeTrendDays(28),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            height: 220,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTapDown: (details) {
                                      final box = context.findRenderObject();
                                      if (box == null) return;

                                      final localX = details.localPosition.dx
                                          .clamp(0, double.infinity);

                                      if (_trendData.isEmpty) return;

                                      final width =
                                          MediaQuery.of(context).size.width -
                                          56 -
                                          28;

                                      final index =
                                          ((localX / width) *
                                                  (_trendData.length - 1))
                                              .round()
                                              .clamp(0, _trendData.length - 1);

                                      setState(() {
                                        _selectedTrendDay = _trendData[index];
                                      });
                                    },
                                    child: CustomPaint(
                                      painter: _MoodTrendPainter(
                                        data: _trendData,
                                        selectedDay: _selectedTrendDay,
                                      ),
                                    ),
                                  ),
                                ),

                                if (_selectedTrendDay != null)
                                  Positioned(
                                    top: 10,
                                    right: 20,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xDD1A2340),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      child: Text(
                                        _trendTooltip(_selectedTrendDay!),
                                        style: TextStyle(
                                          color: _scoreLabelColor(
                                            _selectedTrendDay!.score,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Center(
                            child: Text(
                              'Tap on the line to view date and mood',
                              style: TextStyle(
                                color: ButtonGradient.text,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CompareHeader extends StatelessWidget {
  final String rangeText;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  const _CompareHeader({
    required this.rangeText,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Compare with another week',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        Text(
          rangeText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(
            Icons.chevron_right,
            color: onNext == null ? Colors.white24 : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _MoodBarChart extends StatelessWidget {
  final String title;
  final List<DailyMoodData> data;
  final DailyMoodData? selectedDay;
  final Function(DailyMoodData day) onDayTap;
  final Color Function(int score) barColor;
  final String Function(DailyMoodData day) scoreLabel;
  final Color Function(int score) scoreLabelColor;

  const _MoodBarChart({
    required this.title,
    required this.data,
    required this.selectedDay,
    required this.onDayTap,
    required this.barColor,
    required this.scoreLabel,
    required this.scoreLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: ButtonGradient.decoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ButtonGradient.text,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: data.map((day) {
                final height = 35 + (day.score * 1.15);
                final isSelected = selectedDay?.date == day.date;

                return GestureDetector(
                  onTap: () => onDayTap(day),
                  child: SizedBox(
                    width: 36,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: isSelected ? 18 : 14,
                              height: 145,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDADADA),
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: isSelected ? 18 : 14,
                                height: height.clamp(20, 145),
                                decoration: BoxDecoration(
                                  color: barColor(day.score),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${day.dayLabel}\n${day.date.day}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: ButtonGradient.text,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: -26,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xDD1A2340),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                scoreLabel(day),
                                style: TextStyle(
                                  color: scoreLabelColor(day.score),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendRangeButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _TrendRangeButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: selected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? ButtonGradient.start : Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: ButtonGradient.text,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MoodTrendPainter extends CustomPainter {
  final List<DailyMoodData> data;
  final DailyMoodData? selectedDay;

  _MoodTrendPainter({required this.data, required this.selectedDay});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final leftPadding = 34.0;
    final bottomPadding = 28.0;
    final topPadding = 12.0;
    final chartWidth = size.width - leftPadding - 8;
    final chartHeight = size.height - bottomPadding - topPadding;

    final axisPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1;

    final gridPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );

    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(leftPadding + chartWidth, topPadding + chartHeight),
      axisPaint,
    );

    for (int i = 0; i < 3; i++) {
      final y = topPadding + (chartHeight / 2) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );
    }

    _drawText(canvas, '😊', Offset(2, topPadding - 4), 18);
    _drawText(canvas, '😐', Offset(2, topPadding + chartHeight / 2 - 10), 18);
    _drawText(canvas, '☹️', Offset(2, topPadding + chartHeight - 18), 18);

    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = leftPadding + (chartWidth / (data.length - 1)) * i;
      final y =
          topPadding + chartHeight - ((data[i].score / 100) * chartHeight);
      points.add(Offset(x, y));
    }

    for (int i = 0; i < points.length - 1; i++) {
      final avgScore = ((data[i].score + data[i + 1].score) / 2).round();

      final paint = Paint()
        ..color = avgScore >= 50
            ? const Color(0xFF9EF6B0)
            : const Color(0xFFFF6B6B)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawLine(points[i], points[i + 1], paint);
    }

    for (int i = 0; i < points.length; i++) {
      final isSelected = selectedDay?.date == data[i].date;

      if (!isSelected) continue;

      final selectedPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(points[i].dx, topPadding),
        Offset(points[i].dx, topPadding + chartHeight),
        selectedPaint,
      );

      final pointPaint = Paint()
        ..color = data[i].score >= 50
            ? const Color(0xFF9EF6B0)
            : const Color(0xFFFF6B6B)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(points[i], 6, pointPaint);

      final outlinePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(points[i], 6, outlinePaint);
    }

    final labelStep = data.length <= 7 ? 1 : (data.length / 4).ceil();

    for (int i = 0; i < data.length; i += labelStep) {
      final point = points[i];
      _drawText(
        canvas,
        '${data[i].date.day}/${data[i].date.month}',
        Offset(point.dx - 14, topPadding + chartHeight + 8),
        10,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, double size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: ButtonGradient.text,
          fontSize: size,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _MoodTrendPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.selectedDay != selectedDay;
  }
}
