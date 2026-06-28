import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ascend/core/enums/app_enums.dart';
import 'package:ascend/data/models/habit.dart';
import 'package:ascend/data/models/habit_entry.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  
  static Database? _database;
  
  DatabaseService._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ascend_habits.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop old tables and recreate
      await db.execute('DROP TABLE IF EXISTS habits');
      await db.execute('DROP TABLE IF EXISTS entries');
      await db.execute('DROP TABLE IF EXISTS custom_days');
      await db.execute('DROP TABLE IF EXISTS unlocked_achievements');
      await db.execute('DROP TABLE IF EXISTS unlocked_themes');
      await db.execute('DROP TABLE IF EXISTS unlocked_icons');
      await db.execute('DROP TABLE IF EXISTS motivational_messages');
      await _createDatabase(db, newVersion);
    }
  }
  
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        type INTEGER NOT NULL,
        category INTEGER NOT NULL,
        icon INTEGER,
        color INTEGER,
        frequency INTEGER NOT NULL,
        targetValue REAL,
        targetUnit TEXT,
        reminderHour INTEGER,
        reminderMinute INTEGER,
        hasReminder INTEGER NOT NULL,
        priority INTEGER NOT NULL,
        durationMinutes INTEGER NOT NULL,
        isArchived INTEGER NOT NULL,
        isPaused INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        completedAt TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId TEXT NOT NULL,
        date TEXT NOT NULL,
        dayNumber INTEGER NOT NULL,
        count INTEGER NOT NULL,
        value REAL,
        unit TEXT,
        notes TEXT,
        isSkipped INTEGER NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE custom_days(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId TEXT NOT NULL,
        dayIndex INTEGER NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
  }
  
  // HABIT OPERATIONS
  
  Future<List<Habit>> loadAllHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> habitMaps = await db.query('habits');
    
    List<Habit> habits = [];
    for (var habitMap in habitMaps) {
      final habit = await _loadHabitWithRelations(habitMap);
      habits.add(habit);
    }
    
    return habits;
  }
  
  Future<Habit> _loadHabitWithRelations(Map<String, dynamic> habitMap) async {
    final db = await database;
    final String habitId = habitMap['id'];
    
    // Load entries
    final List<Map<String, dynamic>> entryMaps = await db.query(
      'entries',
      where: 'habitId = ?',
      whereArgs: [habitId],
    );
    
    List<HabitEntry> entries = entryMaps.map((entryMap) {
      return HabitEntry(
        date: DateTime.parse(entryMap['date']),
        count: entryMap['count'],
        dayNumber: entryMap['dayNumber'],
        value: entryMap['value'],
        unit: entryMap['unit'],
        notes: entryMap['notes'],
        isSkipped: entryMap['isSkipped'] == 1,
      );
    }).toList();
    
    // Load custom days
    final List<Map<String, dynamic>> dayMaps = await db.query(
      'custom_days',
      where: 'habitId = ?',
      whereArgs: [habitId],
    );
    List<int> customDays = dayMaps.map((dayMap) => dayMap['dayIndex'] as int).toList();
    
    return Habit(
      id: habitMap['id'],
      name: habitMap['name'],
      description: habitMap['description'],
      type: HabitType.values[habitMap['type']],
      category: HabitCategory.values[habitMap['category']],
      icon: habitMap['icon'] != null ? IconData(habitMap['icon'], fontFamily: 'MaterialIcons') : null,
      color: habitMap['color'] != null ? Color(habitMap['color']) : null,
      frequency: HabitFrequency.values[habitMap['frequency']],
      customDays: customDays,
      targetValue: habitMap['targetValue']?.toDouble(),
      targetUnit: habitMap['targetUnit'],
      reminderHour: habitMap['reminderHour'],
      reminderMinute: habitMap['reminderMinute'],
      hasReminder: habitMap['hasReminder'] == 1,
      priority: HabitPriority.values[habitMap['priority']],
      durationMinutes: habitMap['durationMinutes'] ?? 0,
      isArchived: habitMap['isArchived'] == 1,
      isPaused: habitMap['isPaused'] == 1,
      entries: entries,
      createdAt: DateTime.parse(habitMap['createdAt']),
      completedAt: habitMap['completedAt'] != null ? DateTime.parse(habitMap['completedAt']) : null,
    );
  }
  
  Future<void> saveHabit(Habit habit) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.insert(
        'habits',
        {
          'id': habit.id,
          'name': habit.name,
          'description': habit.description,
          'type': habit.type.index,
          'category': habit.category.index,
          'icon': habit.icon?.codePoint,
          'color': habit.color?.value,
          'frequency': habit.frequency.index,
          'targetValue': habit.targetValue,
          'targetUnit': habit.targetUnit,
          'reminderHour': habit.reminderHour,
          'reminderMinute': habit.reminderMinute,
          'hasReminder': habit.hasReminder ? 1 : 0,
          'priority': habit.priority.index,
          'durationMinutes': habit.durationMinutes,
          'isArchived': habit.isArchived ? 1 : 0,
          'isPaused': habit.isPaused ? 1 : 0,
          'createdAt': habit.createdAt.toIso8601String(),
          'completedAt': habit.completedAt?.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Save entries
      for (var entry in habit.entries) {
        await txn.insert(
          'entries',
          {
            'habitId': habit.id,
            'date': entry.date.toIso8601String(),
            'dayNumber': entry.dayNumber,
            'count': entry.count,
            'value': entry.value,
            'unit': entry.unit,
            'notes': entry.notes,
            'isSkipped': entry.isSkipped ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      // Delete and re-insert custom days
      await txn.delete(
        'custom_days',
        where: 'habitId = ?',
        whereArgs: [habit.id],
      );
      
      for (var day in habit.customDays) {
        await txn.insert(
          'custom_days',
          {
            'habitId': habit.id,
            'dayIndex': day,
          },
        );
      }
    });
  }
  
  Future<void> deleteHabit(Habit habit) async {
    final db = await database;
    await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }
  
  Future<void> updateEntry(Habit habit, HabitEntry oldEntry, HabitEntry newEntry) async {
    final db = await database;
    
    await db.transaction((txn) async {
      final List<Map<String, dynamic>> entries = await txn.query(
        'entries',
        where: 'habitId = ? AND dayNumber = ?',
        whereArgs: [habit.id, oldEntry.dayNumber],
      );
      
      if (entries.isNotEmpty) {
        await txn.update(
          'entries',
          {
            'date': newEntry.date.toIso8601String(),
            'dayNumber': newEntry.dayNumber,
            'count': newEntry.count,
            'value': newEntry.value,
            'unit': newEntry.unit,
            'notes': newEntry.notes,
            'isSkipped': newEntry.isSkipped ? 1 : 0,
          },
          where: 'id = ?',
          whereArgs: [entries.first['id']],
        );
        
        final index = habit.entries.indexWhere((e) => e.dayNumber == oldEntry.dayNumber);
        if (index != -1) {
          habit.entries[index] = newEntry;
        }
      }
    });
  }
  
  Future<void> deleteEntry(Habit habit, HabitEntry entry) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete(
        'entries',
        where: 'habitId = ? AND dayNumber = ?',
        whereArgs: [habit.id, entry.dayNumber],
      );
      
      habit.entries.removeWhere((e) => e.dayNumber == entry.dayNumber);
    });
  }
  
  Future<void> migrateFromJson(List<Habit> habits) async {
    for (var habit in habits) {
      await saveHabit(habit);
    }
  }
}
