import 'package:sqflite/sqflite.dart';
import 'package:face_recognition/utils/sqlite_util.dart';
import 'package:face_recognition/models/member.dart';

class Presence {
  int? id;
  int? memberId;
  Member? member;
  DateTime? startTime;
  DateTime? finishTime;

  Presence({
    this.id,
    this.memberId,
    this.member,
    this.startTime,
    this.finishTime,
  });

  factory Presence.fromMap(Map<String, dynamic> map) {
    return Presence(
      id: map['id'],
      memberId: map['memberId'],
      member: map['member'] != null ? Member.fromMap(map['member']) : null,
      startTime:
          map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      finishTime:
          map['finishTime'] != null ? DateTime.parse(map['finishTime']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'member': member?.toMap(),
      'startTime': startTime?.toIso8601String(),
      'finishTime': finishTime?.toIso8601String(),
    };
  }

  String toJson() => toMap().toString();
}

class PresenceSQLite extends SQLiteUtil {
  Future<List<Presence>> getTodayPresenceList() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT p.*, m.name AS memberName, m.imagePath AS memberImagePath "
      "FROM $presencesTable AS p "
      "LEFT JOIN $membersTable AS m ON m.id = p.memberId "
      "WHERE DATE(p.startTime) = DATE('now')"
      "ORDER BY p.id DESC",
    );
    final List<Presence> presences = List.generate(maps.length, (i) {
      return Presence.fromMap({
        'id': maps[i]['id'],
        'memberId': maps[i]['memberId'],
        'member': {
          'id': maps[i]['memberId'],
          'name': maps[i]['memberName'],
          'imagePath': maps[i]['memberImagePath'],
        },
        'startTime': maps[i]['startTime'],
        'finishTime': maps[i]['finishTime'],
      });
    });
    return presences;
  }

  Future<int> insertPresence(Presence presence) async {
    final db = await database;
    return await db.insert(
      presencesTable,
      {
        'memberId': presence.memberId,
        'startTime': presence.startTime?.toIso8601String(),
        'finishTime': presence.finishTime?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updatePresence(Presence presence) async {
    final db = await database;
    return await db.update(
      presencesTable,
      {
        'id': presence.id,
        'memberId': presence.memberId,
        'startTime': presence.startTime?.toIso8601String(),
        'finishTime': presence.finishTime?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [presence.id],
    );
  }
}
