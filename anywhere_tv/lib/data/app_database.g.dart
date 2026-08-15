// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EpgCacheEntriesTable extends EpgCacheEntries
    with TableInfo<$EpgCacheEntriesTable, EpgCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpgCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    channelId,
    startTime,
    endTime,
    title,
    description,
    category,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'epg_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpgCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {channelId, startTime};
  @override
  EpgCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpgCacheEntry(
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $EpgCacheEntriesTable createAlias(String alias) {
    return $EpgCacheEntriesTable(attachedDatabase, alias);
  }
}

class EpgCacheEntry extends DataClass implements Insertable<EpgCacheEntry> {
  final String channelId;
  final DateTime startTime;
  final DateTime endTime;
  final String title;
  final String? description;
  final String? category;
  final DateTime fetchedAt;
  const EpgCacheEntry({
    required this.channelId,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.description,
    this.category,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['channel_id'] = Variable<String>(channelId);
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  EpgCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return EpgCacheEntriesCompanion(
      channelId: Value(channelId),
      startTime: Value(startTime),
      endTime: Value(endTime),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory EpgCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpgCacheEntry(
      channelId: serializer.fromJson<String>(json['channelId']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String?>(json['category']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'channelId': serializer.toJson<String>(channelId),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String?>(category),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  EpgCacheEntry copyWith({
    String? channelId,
    DateTime? startTime,
    DateTime? endTime,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> category = const Value.absent(),
    DateTime? fetchedAt,
  }) => EpgCacheEntry(
    channelId: channelId ?? this.channelId,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    category: category.present ? category.value : this.category,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  EpgCacheEntry copyWithCompanion(EpgCacheEntriesCompanion data) {
    return EpgCacheEntry(
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpgCacheEntry(')
          ..write('channelId: $channelId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    channelId,
    startTime,
    endTime,
    title,
    description,
    category,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpgCacheEntry &&
          other.channelId == this.channelId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.fetchedAt == this.fetchedAt);
}

class EpgCacheEntriesCompanion extends UpdateCompanion<EpgCacheEntry> {
  final Value<String> channelId;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> category;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const EpgCacheEntriesCompanion({
    this.channelId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpgCacheEntriesCompanion.insert({
    required String channelId,
    required DateTime startTime,
    required DateTime endTime,
    required String title,
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : channelId = Value(channelId),
       startTime = Value(startTime),
       endTime = Value(endTime),
       title = Value(title),
       fetchedAt = Value(fetchedAt);
  static Insertable<EpgCacheEntry> custom({
    Expression<String>? channelId,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (channelId != null) 'channel_id': channelId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpgCacheEntriesCompanion copyWith({
    Value<String>? channelId,
    Value<DateTime>? startTime,
    Value<DateTime>? endTime,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? category,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return EpgCacheEntriesCompanion(
      channelId: channelId ?? this.channelId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpgCacheEntriesCompanion(')
          ..write('channelId: $channelId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WatchHistoryEntriesTable extends WatchHistoryEntries
    with TableInfo<$WatchHistoryEntriesTable, WatchHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchHistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, channelId, watchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_history_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_watchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WatchHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchHistoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      )!,
    );
  }

  @override
  $WatchHistoryEntriesTable createAlias(String alias) {
    return $WatchHistoryEntriesTable(attachedDatabase, alias);
  }
}

class WatchHistoryEntry extends DataClass
    implements Insertable<WatchHistoryEntry> {
  final int id;
  final String channelId;
  final DateTime watchedAt;
  const WatchHistoryEntry({
    required this.id,
    required this.channelId,
    required this.watchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['channel_id'] = Variable<String>(channelId);
    map['watched_at'] = Variable<DateTime>(watchedAt);
    return map;
  }

  WatchHistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return WatchHistoryEntriesCompanion(
      id: Value(id),
      channelId: Value(channelId),
      watchedAt: Value(watchedAt),
    );
  }

  factory WatchHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchHistoryEntry(
      id: serializer.fromJson<int>(json['id']),
      channelId: serializer.fromJson<String>(json['channelId']),
      watchedAt: serializer.fromJson<DateTime>(json['watchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'channelId': serializer.toJson<String>(channelId),
      'watchedAt': serializer.toJson<DateTime>(watchedAt),
    };
  }

  WatchHistoryEntry copyWith({
    int? id,
    String? channelId,
    DateTime? watchedAt,
  }) => WatchHistoryEntry(
    id: id ?? this.id,
    channelId: channelId ?? this.channelId,
    watchedAt: watchedAt ?? this.watchedAt,
  );
  WatchHistoryEntry copyWithCompanion(WatchHistoryEntriesCompanion data) {
    return WatchHistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryEntry(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('watchedAt: $watchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, channelId, watchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchHistoryEntry &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.watchedAt == this.watchedAt);
}

class WatchHistoryEntriesCompanion extends UpdateCompanion<WatchHistoryEntry> {
  final Value<int> id;
  final Value<String> channelId;
  final Value<DateTime> watchedAt;
  const WatchHistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.watchedAt = const Value.absent(),
  });
  WatchHistoryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String channelId,
    required DateTime watchedAt,
  }) : channelId = Value(channelId),
       watchedAt = Value(watchedAt);
  static Insertable<WatchHistoryEntry> custom({
    Expression<int>? id,
    Expression<String>? channelId,
    Expression<DateTime>? watchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (watchedAt != null) 'watched_at': watchedAt,
    });
  }

  WatchHistoryEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? channelId,
    Value<DateTime>? watchedAt,
  }) {
    return WatchHistoryEntriesCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      watchedAt: watchedAt ?? this.watchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('watchedAt: $watchedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EpgCacheEntriesTable epgCacheEntries = $EpgCacheEntriesTable(
    this,
  );
  late final $WatchHistoryEntriesTable watchHistoryEntries =
      $WatchHistoryEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    epgCacheEntries,
    watchHistoryEntries,
  ];
}

typedef $$EpgCacheEntriesTableCreateCompanionBuilder =
    EpgCacheEntriesCompanion Function({
      required String channelId,
      required DateTime startTime,
      required DateTime endTime,
      required String title,
      Value<String?> description,
      Value<String?> category,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$EpgCacheEntriesTableUpdateCompanionBuilder =
    EpgCacheEntriesCompanion Function({
      Value<String> channelId,
      Value<DateTime> startTime,
      Value<DateTime> endTime,
      Value<String> title,
      Value<String?> description,
      Value<String?> category,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$EpgCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EpgCacheEntriesTable> {
  $$EpgCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpgCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EpgCacheEntriesTable> {
  $$EpgCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpgCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpgCacheEntriesTable> {
  $$EpgCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$EpgCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpgCacheEntriesTable,
          EpgCacheEntry,
          $$EpgCacheEntriesTableFilterComposer,
          $$EpgCacheEntriesTableOrderingComposer,
          $$EpgCacheEntriesTableAnnotationComposer,
          $$EpgCacheEntriesTableCreateCompanionBuilder,
          $$EpgCacheEntriesTableUpdateCompanionBuilder,
          (
            EpgCacheEntry,
            BaseReferences<_$AppDatabase, $EpgCacheEntriesTable, EpgCacheEntry>,
          ),
          EpgCacheEntry,
          PrefetchHooks Function()
        > {
  $$EpgCacheEntriesTableTableManager(
    _$AppDatabase db,
    $EpgCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpgCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpgCacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpgCacheEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> channelId = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime> endTime = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpgCacheEntriesCompanion(
                channelId: channelId,
                startTime: startTime,
                endTime: endTime,
                title: title,
                description: description,
                category: category,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String channelId,
                required DateTime startTime,
                required DateTime endTime,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => EpgCacheEntriesCompanion.insert(
                channelId: channelId,
                startTime: startTime,
                endTime: endTime,
                title: title,
                description: description,
                category: category,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpgCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpgCacheEntriesTable,
      EpgCacheEntry,
      $$EpgCacheEntriesTableFilterComposer,
      $$EpgCacheEntriesTableOrderingComposer,
      $$EpgCacheEntriesTableAnnotationComposer,
      $$EpgCacheEntriesTableCreateCompanionBuilder,
      $$EpgCacheEntriesTableUpdateCompanionBuilder,
      (
        EpgCacheEntry,
        BaseReferences<_$AppDatabase, $EpgCacheEntriesTable, EpgCacheEntry>,
      ),
      EpgCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$WatchHistoryEntriesTableCreateCompanionBuilder =
    WatchHistoryEntriesCompanion Function({
      Value<int> id,
      required String channelId,
      required DateTime watchedAt,
    });
typedef $$WatchHistoryEntriesTableUpdateCompanionBuilder =
    WatchHistoryEntriesCompanion Function({
      Value<int> id,
      Value<String> channelId,
      Value<DateTime> watchedAt,
    });

class $$WatchHistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WatchHistoryEntriesTable> {
  $$WatchHistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WatchHistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchHistoryEntriesTable> {
  $$WatchHistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WatchHistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchHistoryEntriesTable> {
  $$WatchHistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);
}

class $$WatchHistoryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchHistoryEntriesTable,
          WatchHistoryEntry,
          $$WatchHistoryEntriesTableFilterComposer,
          $$WatchHistoryEntriesTableOrderingComposer,
          $$WatchHistoryEntriesTableAnnotationComposer,
          $$WatchHistoryEntriesTableCreateCompanionBuilder,
          $$WatchHistoryEntriesTableUpdateCompanionBuilder,
          (
            WatchHistoryEntry,
            BaseReferences<
              _$AppDatabase,
              $WatchHistoryEntriesTable,
              WatchHistoryEntry
            >,
          ),
          WatchHistoryEntry,
          PrefetchHooks Function()
        > {
  $$WatchHistoryEntriesTableTableManager(
    _$AppDatabase db,
    $WatchHistoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchHistoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchHistoryEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WatchHistoryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
              }) => WatchHistoryEntriesCompanion(
                id: id,
                channelId: channelId,
                watchedAt: watchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String channelId,
                required DateTime watchedAt,
              }) => WatchHistoryEntriesCompanion.insert(
                id: id,
                channelId: channelId,
                watchedAt: watchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WatchHistoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchHistoryEntriesTable,
      WatchHistoryEntry,
      $$WatchHistoryEntriesTableFilterComposer,
      $$WatchHistoryEntriesTableOrderingComposer,
      $$WatchHistoryEntriesTableAnnotationComposer,
      $$WatchHistoryEntriesTableCreateCompanionBuilder,
      $$WatchHistoryEntriesTableUpdateCompanionBuilder,
      (
        WatchHistoryEntry,
        BaseReferences<
          _$AppDatabase,
          $WatchHistoryEntriesTable,
          WatchHistoryEntry
        >,
      ),
      WatchHistoryEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EpgCacheEntriesTableTableManager get epgCacheEntries =>
      $$EpgCacheEntriesTableTableManager(_db, _db.epgCacheEntries);
  $$WatchHistoryEntriesTableTableManager get watchHistoryEntries =>
      $$WatchHistoryEntriesTableTableManager(_db, _db.watchHistoryEntries);
}
