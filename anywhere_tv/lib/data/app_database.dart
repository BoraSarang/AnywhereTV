import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../models/epg_program.dart';

part 'app_database.g.dart';

class EpgCacheEntries extends Table {
  TextColumn get channelId => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {channelId, startTime};
}

class WatchHistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get channelId => text()();
  DateTimeColumn get watchedAt => dateTime()();
}

@DriftDatabase(tables: [EpgCacheEntries, WatchHistoryEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'anywhere_tv'));

  @override
  int get schemaVersion => 1;

  Future<void> saveEpgCache(List<EpgProgram> programs, String channelId) async {
    await transaction(() async {
      final now = DateTime.now();
      final maxStart = now.subtract(const Duration(hours: 12));
      await (delete(epgCacheEntries)
            ..where((t) => t.channelId.equals(channelId) & t.startTime.isSmallerThanValue(maxStart)))
          .go();
      for (final p in programs) {
        await into(epgCacheEntries).insertOnConflictUpdate(
          EpgCacheEntriesCompanion.insert(
            channelId: channelId,
            startTime: p.startTime,
            endTime: p.endTime,
            title: p.title,
            description: Value(p.description),
            category: Value(p.category),
            fetchedAt: now,
          ),
        );
      }
    });
  }

  Future<List<EpgProgram>> loadEpgCache(String channelId) async {
    final rows = await (select(epgCacheEntries)
          ..where((t) => t.channelId.equals(channelId))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime)]))
        .get();
    return rows
        .map((r) => EpgProgram(
              channelId: r.channelId,
              title: r.title,
              startTime: r.startTime,
              endTime: r.endTime,
              description: r.description,
              category: r.category,
            ))
        .toList();
  }

  Future<DateTime?> lastEpgFetch(String channelId) async {
    final row = await (selectOnly(epgCacheEntries)
          ..addColumns([epgCacheEntries.fetchedAt.max()])
          ..where(epgCacheEntries.channelId.equals(channelId)))
        .getSingleOrNull();
    return row?.read(epgCacheEntries.fetchedAt.max());
  }

  Future<void> recordWatch(String channelId) async {
    await into(watchHistoryEntries).insert(
      WatchHistoryEntriesCompanion.insert(
        channelId: channelId,
        watchedAt: DateTime.now(),
      ),
    );
    final rows = await (select(watchHistoryEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.watchedAt)]))
        .get();
    if (rows.length > 20) {
      final excess = rows.skip(20).map((r) => r.id).toList();
      await (delete(watchHistoryEntries)..where((t) => t.id.isIn(excess))).go();
    }
  }

  Future<List<String>> loadWatchHistory() async {
    final rows = await (select(watchHistoryEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.watchedAt)]))
        .get();
    final ids = <String>[];
    for (final r in rows) {
      if (!ids.contains(r.channelId)) ids.add(r.channelId);
    }
    return ids;
  }
}