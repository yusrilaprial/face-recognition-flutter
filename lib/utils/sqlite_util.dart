import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteUtil {
  static String dbName = "face_recognition";
  final String membersTable = "members";
  final String presencesTable = "presences";

  Future<Database> get database async {
    return await openDatabase(
      join(await getDatabasesPath(), "$dbName.db"),
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE $membersTable("
          "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "  name TEXT,"
          "  imagePath TEXT,"
          "  embedding TEXT"
          ")",
        );
        await db.execute(
          "CREATE TABLE $presencesTable("
          "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "  memberId INTEGER,"
          "  startTime TEXT,"
          "  finishTime TEXT,"
          "  FOREIGN KEY (memberId) REFERENCES $membersTable(id) ON DELETE CASCADE"
          ")",
        );
      },
      version: 1,
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
