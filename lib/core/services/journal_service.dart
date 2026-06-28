import 'dart:convert';
import 'package:ascend/data/models/journal_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalService {
  static const String _entriesKey = 'journal_entries_data';
  static List<JournalEntry> _entries = [];

  static List<JournalEntry> get entries => List.unmodifiable(_entries);

  static Future<void> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? entriesJson = prefs.getString(_entriesKey);
    if (entriesJson != null) {
      final List<dynamic> decoded = jsonDecode(entriesJson);
      _entries = decoded.map((e) => JournalEntry.fromJson(e)).toList();
    } else {
      _entries = [];
    }
  }

  static Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded =
        jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_entriesKey, encoded);
  }

  static Future<JournalEntry> addEntry(JournalEntry entry) async {
    _entries.add(entry);
    await _saveEntries();
    return entry;
  }

  static Future<void> updateEntry(JournalEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      entry.updatedAt = DateTime.now();
      _entries[index] = entry;
      await _saveEntries();
    }
  }

  static Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((e) => e.id == entryId);
    await _saveEntries();
  }

  static JournalEntry? getEntryByDate(DateTime date) {
    try {
      return _entries.firstWhere((e) =>
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day);
    } catch (_) {
      return null;
    }
  }

  static List<JournalEntry> getEntriesForMonth(int year, int month) {
    return _entries.where((e) {
      return e.date.year == year && e.date.month == month;
    }).toList();
  }

  static List<JournalEntry> searchEntries(String query) {
    final lowerQuery = query.toLowerCase();
    return _entries.where((e) {
      final textMatch =
          e.textContent?.toLowerCase().contains(lowerQuery) ?? false;
      final tagMatch =
          e.tags.any((t) => t.toLowerCase().contains(lowerQuery));
      return textMatch || tagMatch;
    }).toList();
  }

  static List<String> getAllTags() {
    final Set<String> tags = {};
    for (var entry in _entries) {
      tags.addAll(entry.tags);
    }
    return tags.toList()..sort();
  }

  static Map<Mood, int> getMoodStats() {
    final Map<Mood, int> stats = {};
    for (var entry in _entries) {
      stats[entry.mood] = (stats[entry.mood] ?? 0) + 1;
    }
    return stats;
  }

  static int getStreak() {
    if (_entries.isEmpty) return 0;

    final sortedEntries = List<JournalEntry>.from(_entries)
      ..sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime? lastDate;

    for (var entry in sortedEntries) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);

      if (lastDate == null) {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        if (entryDate == todayDate ||
            entryDate == todayDate.subtract(const Duration(days: 1))) {
          lastDate = entryDate;
          streak++;
        } else {
          break;
        }
      } else {
        final diff = lastDate.difference(entryDate).inDays;
        if (diff == 1) {
          lastDate = entryDate;
          streak++;
        } else if (diff > 1) {
          break;
        }
      }
    }

    return streak;
  }
}
