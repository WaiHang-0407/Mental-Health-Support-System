import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal.dart';
import '../repositories/journal_table_repository.dart';

class DailyMoodData {
  final DateTime date;
  final String dayLabel;
  final int score;
  final String mood;

  DailyMoodData({
    required this.date,
    required this.dayLabel,
    required this.score,
    required this.mood,
  });
}

class WeeklyComparisonData {
  final String message;
  final Color color;

  WeeklyComparisonData({required this.message, required this.color});
}

class WeeklyReportData {
  final List<DailyMoodData> thisWeekData;
  final List<DailyMoodData> compareWeekData;
  final List<DailyMoodData> trendData;
  final WeeklyComparisonData comparison;
  final DateTime compareStartDate;
  final DateTime compareEndDate;

  WeeklyReportData({
    required this.thisWeekData,
    required this.compareWeekData,
    required this.trendData,
    required this.comparison,
    required this.compareStartDate,
    required this.compareEndDate,
  });
}

class WeeklyReportController {
  final JournalTableRepository _journalRepo = JournalTableRepository();
  final supabase = Supabase.instance.client;

  String? get currentUserId => supabase.auth.currentUser?.id;

  Future<WeeklyReportData> getWeeklyReportData({
    DateTime? compareStartDate,
    int trendDays = 7,
  }) async {
    final userId = currentUserId;

    if (userId == null) {
      final now = DateTime.now();
      return WeeklyReportData(
        thisWeekData: [],
        compareWeekData: [],
        trendData: [],
        comparison: WeeklyComparisonData(
          message: 'No user found',
          color: Colors.white,
        ),
        compareStartDate: now,
        compareEndDate: now,
      );
    }

    final journals = await _journalRepo.getJournals(userId);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final lastMonday = thisMonday.subtract(const Duration(days: 7));

    final compareStart = compareStartDate ?? lastMonday;
    final compareEnd = compareStart.add(const Duration(days: 6));

    final thisWeekData = _buildDailyMoodData(thisMonday, 7, journals);
    final compareWeekData = _buildDailyMoodData(compareStart, 7, journals);

    final trendStart = today.subtract(Duration(days: trendDays - 1));
    final trendData = _buildDailyMoodData(trendStart, trendDays, journals);

    final thisWeekAvg = _averageDailyScore(thisWeekData);
    final compareAvg = _averageDailyScore(compareWeekData);

    return WeeklyReportData(
      thisWeekData: thisWeekData,
      compareWeekData: compareWeekData,
      trendData: trendData,
      comparison: _buildComparison(thisWeekAvg, compareAvg),
      compareStartDate: compareStart,
      compareEndDate: compareEnd,
    );
  }

  List<DailyMoodData> _buildDailyMoodData(
    DateTime startDate,
    int days,
    List<JournalModel> journals,
  ) {
    return List.generate(days, (index) {
      final date = DateTime(
        startDate.year,
        startDate.month,
        startDate.day + index,
      );

      final dayJournals = journals.where((journal) {
        final createdAt = journal.createdAt?.toLocal();
        if (createdAt == null) return false;

        return createdAt.year == date.year &&
            createdAt.month == date.month &&
            createdAt.day == date.day;
      }).toList();

      if (dayJournals.isEmpty) {
        return DailyMoodData(
          date: date,
          dayLabel: _dayLabel(date.weekday),
          score: 50,
          mood: 'Neutral',
        );
      }

      final scores = dayJournals.map((j) => _emotionScore(j.emotion)).toList();
      final average = scores.reduce((a, b) => a + b) ~/ scores.length;

      return DailyMoodData(
        date: date,
        dayLabel: _dayLabel(date.weekday),
        score: average,
        mood: _scoreToMood(average),
      );
    });
  }

  int _averageDailyScore(List<DailyMoodData> data) {
    if (data.isEmpty) return 50;
    return data.map((e) => e.score).reduce((a, b) => a + b) ~/ data.length;
  }

  WeeklyComparisonData _buildComparison(int thisWeekAvg, int compareAvg) {
    final difference = thisWeekAvg - compareAvg;

    if (difference.abs() < 5) {
      return WeeklyComparisonData(
        message: 'Mood stayed stable',
        color: const Color(0xFFFFC56D),
      );
    }

    final percentage = ((difference.abs() / compareAvg) * 100).round();

    if (difference > 0) {
      return WeeklyComparisonData(
        message: '$percentage% happier than selected week!',
        color: const Color(0xFF64F58D),
      );
    }

    return WeeklyComparisonData(
      message: '$percentage% lower mood than selected week',
      color: const Color(0xFFFF6B6B),
    );
  }

  int _emotionScore(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'happy':
        return 90;
      case 'excited':
        return 85;
      case 'calm':
        return 75;
      case 'neutral':
        return 50;
      case 'anxious':
        return 40;
      case 'lonely':
        return 35;
      case 'stressed':
        return 30;
      case 'sad':
        return 20;
      case 'fearful':
        return 15;
      case 'angry':
        return 10;
      default:
        return 50;
    }
  }

  String _scoreToMood(int score) {
    if (score >= 70) return 'Happy';
    if (score >= 50) return 'Positive';
    if (score >= 40) return 'Neutral';
    return 'Low';
  }

  String _dayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thur';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }
}
