import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:project/models/coach_result.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ai_camera_coach.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        final columns = [
          'brightness',
          'exposure',
          'contrast',
          'temperature',
          'saturation',
          'fade'
        ];
        for (var col in columns) {
          try {
            await db.execute('ALTER TABLE photos ADD COLUMN $col REAL DEFAULT 0.0');
          } catch (e) {
            // Column already exists
          }
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE photos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT,
        overall_score REAL,
        composition_score REAL,
        tags TEXT,
        instruction TEXT,
        timestamp TEXT,
        brightness REAL DEFAULT 0.0,
        exposure REAL DEFAULT 0.0,
        contrast REAL DEFAULT 0.0,
        temperature REAL DEFAULT 0.0,
        saturation REAL DEFAULT 0.0,
        fade REAL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE badges(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        unlocked_at TEXT
      )
    ''');
  }

  // Save a new photo capture
  Future<int> savePhoto({
    required String path,
    required CoachResult result,
    required List<String> tags,
  }) async {
    final db = await database;
    return await db.insert('photos', {
      'path': path,
      'overall_score': 0.0,
      'composition_score': 0.0,
      'tags': tags.join(','),
      'instruction': result.instruction,
      'timestamp': DateTime.now().toIso8601String(),
      'brightness': 0.0,
      'exposure': 0.0,
      'contrast': 0.0,
      'temperature': 0.0,
      'saturation': 0.0,
      'fade': 0.0,
    });
  }

  // Get all photos for history screen
  Future<List<Map<String, dynamic>>> getPhotoHistory() async {
    final db = await database;
    return await db.query('photos', orderBy: 'timestamp DESC');
  }

  // Delete a photo by ID
  Future<int> deletePhoto(int id) async {
    final db = await database;
    return await db.delete('photos', where: 'id = ?', whereArgs: [id]);
  }

  // Update photo adjustments
  Future<int> updatePhotoAdjustments(
    int id, {
    required double brightness,
    required double exposure,
    required double contrast,
    required double temperature,
    required double saturation,
    required double fade,
  }) async {
    final db = await database;
    return await db.update(
      'photos',
      {
        'brightness': brightness,
        'exposure': exposure,
        'contrast': contrast,
        'temperature': temperature,
        'saturation': saturation,
        'fade': fade,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get statistics for progress screen
  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final List<Map<String, dynamic>> photos = await db.query('photos');
    
    if (photos.isEmpty) return {'total': 0, 'avgScore': 0.0};

    double totalScore = 0;
    for (var photo in photos) {
      totalScore += photo['overall_score'];
    }

    return {
      'total': photos.length,
      'avgScore': totalScore / photos.length,
    };
  }
}
