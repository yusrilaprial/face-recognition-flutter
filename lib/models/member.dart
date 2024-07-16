import 'package:face_recognition/models/presence.dart';
import 'package:face_recognition/utils/sqlite_util.dart';
import 'package:sqflite/sqflite.dart';

class Member {
  int? id;
  String? name;
  String? imagePath;
  String? embedding;
  Presence? presence;

  Member({
    this.id,
    this.name,
    this.imagePath,
    this.embedding,
    this.presence,
  });

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      name: map['name'],
      imagePath: map['imagePath'],
      embedding: map['embedding'] ?? "",
      presence:
          map['presence'] != null ? Presence.fromMap(map['presence']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'embedding': embedding,
      'presence': presence?.toMap(),
    };
  }

  String toJson() => toMap().toString();
}

class MemberSQLite extends SQLiteUtil {
  Future<Member?> getMember(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      membersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Member.fromMap(maps.first);
    return null;
  }

  Future<List<Member>> getMemberList() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(membersTable);
    return List.generate(maps.length, (i) => Member.fromMap(maps[i]));
  }

  Future<List<Member>> getTodayPresenceMemberList() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT m.*, p.id AS presenceId, p.memberId AS presenceMemberId, p.startTime AS presenceStartTime, p.finishTime AS presenceFinishTime "
      "FROM $membersTable AS m "
      "LEFT JOIN $presencesTable AS p ON p.memberId = m.id AND DATE(p.startTime) = DATE('now')"
      "ORDER BY m.name",
    );

    List<Member> members = List.generate(maps.length, (i) {
      return Member.fromMap({
        ...maps[i],
        'presence': {
          'id': maps[i]['presenceId'],
          'memberId': maps[i]['presenceMemberId'],
          'startTime': maps[i]['presenceStartTime'],
          'finishTime': maps[i]['presenceFinishTime'],
        },
      });
    });

    Map<int, List<Member>> groupMember = {};
    for (var member in members) {
      if (groupMember.containsKey(member.id!)) {
        groupMember[member.id!]!.add(member);
      } else {
        groupMember[member.id!] = [member];
      }
    }

    members = [];
    for (var groupMembers in groupMember.values) {
      groupMembers.sort((a, b) {
        var aTime = a.presence?.startTime ?? DateTime(0);
        var bTime = b.presence?.startTime ?? DateTime(0);
        return aTime.compareTo(bTime);
      });
      members.add(groupMembers.last);
    }

    return members;
  }

  Future<int> insertMember(Member member) async {
    final db = await database;
    return await db.insert(
      membersTable,
      {
        'name': member.name,
        'imagePath': member.imagePath,
        'embedding': member.embedding,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateMember(Member member) async {
    final db = await database;
    return await db.update(
      membersTable,
      {
        'id': member.id,
        'name': member.name,
        'imagePath': member.imagePath,
        'embedding': member.embedding,
      },
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> deleteMember(int id) async {
    final db = await database;
    return await db.delete(
      membersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
