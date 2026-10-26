// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CalendarsTable extends Calendars
    with TableInfo<$CalendarsTable, CalendarRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorValue,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendars';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CalendarsTable createAlias(String alias) {
    return $CalendarsTable(attachedDatabase, alias);
  }
}

class CalendarRow extends DataClass implements Insertable<CalendarRow> {
  final String id;
  final String name;
  final int colorValue;
  final int sortOrder;
  final bool archived;
  final int createdAt;
  final int updatedAt;
  const CalendarRow({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.sortOrder,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color_value'] = Variable<int>(colorValue);
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CalendarsCompanion toCompanion(bool nullToAbsent) {
    return CalendarsCompanion(
      id: Value(id),
      name: Value(name),
      colorValue: Value(colorValue),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CalendarRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorValue': serializer.toJson<int>(colorValue),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CalendarRow copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? sortOrder,
    bool? archived,
    int? createdAt,
    int? updatedAt,
  }) => CalendarRow(
    id: id ?? this.id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CalendarRow copyWithCompanion(CalendarsCompanion data) {
    return CalendarRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    colorValue,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorValue == this.colorValue &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CalendarsCompanion extends UpdateCompanion<CalendarRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> colorValue;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CalendarsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarsCompanion.insert({
    required String id,
    required String name,
    required int colorValue,
    required int sortOrder,
    this.archived = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       colorValue = Value(colorValue),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CalendarRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? colorValue,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorValue != null) 'color_value': colorValue,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? colorValue,
    Value<int>? sortOrder,
    Value<bool>? archived,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return CalendarsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShiftTypesTable extends ShiftTypes
    with TableInfo<$ShiftTypesTable, ShiftTypeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ShiftCategory, String> category =
      GeneratedColumn<String>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ShiftCategory>($ShiftTypesTable.$convertercategory);
  static const VerificationMeta _startMinuteMeta = const VerificationMeta(
    'startMinute',
  );
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
    'start_minute',
    aliasedName,
    true,
    check: () => ComparableExpr(startMinute).isBetweenValues(0, 1439),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endMinuteMeta = const VerificationMeta(
    'endMinute',
  );
  @override
  late final GeneratedColumn<int> endMinute = GeneratedColumn<int>(
    'end_minute',
    aliasedName,
    true,
    check: () => ComparableExpr(endMinute).isBetweenValues(0, 1439),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidMinutesMeta = const VerificationMeta(
    'paidMinutes',
  );
  @override
  late final GeneratedColumn<int> paidMinutes = GeneratedColumn<int>(
    'paid_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nightOverrideMeta = const VerificationMeta(
    'nightOverride',
  );
  @override
  late final GeneratedColumn<bool> nightOverride = GeneratedColumn<bool>(
    'night_override',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("night_override" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hourlyRateCentsMeta = const VerificationMeta(
    'hourlyRateCents',
  );
  @override
  late final GeneratedColumn<int> hourlyRateCents = GeneratedColumn<int>(
    'hourly_rate_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedPlusCentsMeta = const VerificationMeta(
    'fixedPlusCents',
  );
  @override
  late final GeneratedColumn<int> fixedPlusCents = GeneratedColumn<int>(
    'fixed_plus_cents',
    aliasedName,
    true,
    check: () =>
        ComparableExpr(fixedPlusCents).isBetweenValues(0, maxFixedPlusCents),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alarmSoundMeta = const VerificationMeta(
    'alarmSound',
  );
  @override
  late final GeneratedColumn<String> alarmSound = GeneratedColumn<String>(
    'alarm_sound',
    aliasedName,
    true,
    check: () =>
        alarmSound.isNull() |
        BooleanExpressionOperators(alarmSound.equals('')).not(),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _segment2StartMinuteMeta =
      const VerificationMeta('segment2StartMinute');
  @override
  late final GeneratedColumn<int> segment2StartMinute = GeneratedColumn<int>(
    'segment2_start_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _segment2DurationMinutesMeta =
      const VerificationMeta('segment2DurationMinutes');
  @override
  late final GeneratedColumn<int> segment2DurationMinutes =
      GeneratedColumn<int>(
        'segment2_duration_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    colorValue,
    category,
    startMinute,
    endMinute,
    paidMinutes,
    nightOverride,
    hourlyRateCents,
    fixedPlusCents,
    icon,
    alarmSound,
    segment2StartMinute,
    segment2DurationMinutes,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shift_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShiftTypeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('start_minute')) {
      context.handle(
        _startMinuteMeta,
        startMinute.isAcceptableOrUnknown(
          data['start_minute']!,
          _startMinuteMeta,
        ),
      );
    }
    if (data.containsKey('end_minute')) {
      context.handle(
        _endMinuteMeta,
        endMinute.isAcceptableOrUnknown(data['end_minute']!, _endMinuteMeta),
      );
    }
    if (data.containsKey('paid_minutes')) {
      context.handle(
        _paidMinutesMeta,
        paidMinutes.isAcceptableOrUnknown(
          data['paid_minutes']!,
          _paidMinutesMeta,
        ),
      );
    }
    if (data.containsKey('night_override')) {
      context.handle(
        _nightOverrideMeta,
        nightOverride.isAcceptableOrUnknown(
          data['night_override']!,
          _nightOverrideMeta,
        ),
      );
    }
    if (data.containsKey('hourly_rate_cents')) {
      context.handle(
        _hourlyRateCentsMeta,
        hourlyRateCents.isAcceptableOrUnknown(
          data['hourly_rate_cents']!,
          _hourlyRateCentsMeta,
        ),
      );
    }
    if (data.containsKey('fixed_plus_cents')) {
      context.handle(
        _fixedPlusCentsMeta,
        fixedPlusCents.isAcceptableOrUnknown(
          data['fixed_plus_cents']!,
          _fixedPlusCentsMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('alarm_sound')) {
      context.handle(
        _alarmSoundMeta,
        alarmSound.isAcceptableOrUnknown(data['alarm_sound']!, _alarmSoundMeta),
      );
    }
    if (data.containsKey('segment2_start_minute')) {
      context.handle(
        _segment2StartMinuteMeta,
        segment2StartMinute.isAcceptableOrUnknown(
          data['segment2_start_minute']!,
          _segment2StartMinuteMeta,
        ),
      );
    }
    if (data.containsKey('segment2_duration_minutes')) {
      context.handle(
        _segment2DurationMinutesMeta,
        segment2DurationMinutes.isAcceptableOrUnknown(
          data['segment2_duration_minutes']!,
          _segment2DurationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftTypeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftTypeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      category: $ShiftTypesTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      startMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minute'],
      ),
      endMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minute'],
      ),
      paidMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_minutes'],
      ),
      nightOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}night_override'],
      ),
      hourlyRateCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hourly_rate_cents'],
      ),
      fixedPlusCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_plus_cents'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      alarmSound: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_sound'],
      ),
      segment2StartMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment2_start_minute'],
      ),
      segment2DurationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment2_duration_minutes'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ShiftTypesTable createAlias(String alias) {
    return $ShiftTypesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ShiftCategory, String, String> $convertercategory =
      const EnumNameConverter<ShiftCategory>(ShiftCategory.values);
}

class ShiftTypeRow extends DataClass implements Insertable<ShiftTypeRow> {
  final String id;
  final String code;
  final String name;
  final int colorValue;
  final ShiftCategory category;
  final int? startMinute;
  final int? endMinute;
  final int? paidMinutes;
  final bool? nightOverride;

  /// Hourly rate in cents (no floating point). Added in schema v2.
  final int? hourlyRateCents;

  /// Fixed payment per worked shift, in cents. Added in schema v4.
  final int? fixedPlusCents;

  /// Key of the icon (`ShiftIcon.key`), or NULL. Plain text on purpose: a key
  /// this build does not know reads as no icon instead of failing. Added in
  /// schema v3.
  final String? icon;

  /// Opaque id of the system sound the alarm of this type uses; NULL = the
  /// default of the channel. Added in schema v3.
  final String? alarmSound;

  /// Second segment of a split shift: clock minute where it starts and how
  /// long it lasts. Both or none, and only on a shift with times (CHECKs
  /// below). That it fits after the first segment within 24 h is checked by
  /// the domain (`checkSegment2`). Added in schema v3.
  final int? segment2StartMinute;
  final int? segment2DurationMinutes;
  final int sortOrder;
  final bool archived;
  final int createdAt;
  final int updatedAt;
  const ShiftTypeRow({
    required this.id,
    required this.code,
    required this.name,
    required this.colorValue,
    required this.category,
    this.startMinute,
    this.endMinute,
    this.paidMinutes,
    this.nightOverride,
    this.hourlyRateCents,
    this.fixedPlusCents,
    this.icon,
    this.alarmSound,
    this.segment2StartMinute,
    this.segment2DurationMinutes,
    required this.sortOrder,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['color_value'] = Variable<int>(colorValue);
    {
      map['category'] = Variable<String>(
        $ShiftTypesTable.$convertercategory.toSql(category),
      );
    }
    if (!nullToAbsent || startMinute != null) {
      map['start_minute'] = Variable<int>(startMinute);
    }
    if (!nullToAbsent || endMinute != null) {
      map['end_minute'] = Variable<int>(endMinute);
    }
    if (!nullToAbsent || paidMinutes != null) {
      map['paid_minutes'] = Variable<int>(paidMinutes);
    }
    if (!nullToAbsent || nightOverride != null) {
      map['night_override'] = Variable<bool>(nightOverride);
    }
    if (!nullToAbsent || hourlyRateCents != null) {
      map['hourly_rate_cents'] = Variable<int>(hourlyRateCents);
    }
    if (!nullToAbsent || fixedPlusCents != null) {
      map['fixed_plus_cents'] = Variable<int>(fixedPlusCents);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || alarmSound != null) {
      map['alarm_sound'] = Variable<String>(alarmSound);
    }
    if (!nullToAbsent || segment2StartMinute != null) {
      map['segment2_start_minute'] = Variable<int>(segment2StartMinute);
    }
    if (!nullToAbsent || segment2DurationMinutes != null) {
      map['segment2_duration_minutes'] = Variable<int>(segment2DurationMinutes);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ShiftTypesCompanion toCompanion(bool nullToAbsent) {
    return ShiftTypesCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      colorValue: Value(colorValue),
      category: Value(category),
      startMinute: startMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(startMinute),
      endMinute: endMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(endMinute),
      paidMinutes: paidMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(paidMinutes),
      nightOverride: nightOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(nightOverride),
      hourlyRateCents: hourlyRateCents == null && nullToAbsent
          ? const Value.absent()
          : Value(hourlyRateCents),
      fixedPlusCents: fixedPlusCents == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedPlusCents),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      alarmSound: alarmSound == null && nullToAbsent
          ? const Value.absent()
          : Value(alarmSound),
      segment2StartMinute: segment2StartMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(segment2StartMinute),
      segment2DurationMinutes: segment2DurationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(segment2DurationMinutes),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ShiftTypeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftTypeRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      category: $ShiftTypesTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      startMinute: serializer.fromJson<int?>(json['startMinute']),
      endMinute: serializer.fromJson<int?>(json['endMinute']),
      paidMinutes: serializer.fromJson<int?>(json['paidMinutes']),
      nightOverride: serializer.fromJson<bool?>(json['nightOverride']),
      hourlyRateCents: serializer.fromJson<int?>(json['hourlyRateCents']),
      fixedPlusCents: serializer.fromJson<int?>(json['fixedPlusCents']),
      icon: serializer.fromJson<String?>(json['icon']),
      alarmSound: serializer.fromJson<String?>(json['alarmSound']),
      segment2StartMinute: serializer.fromJson<int?>(
        json['segment2StartMinute'],
      ),
      segment2DurationMinutes: serializer.fromJson<int?>(
        json['segment2DurationMinutes'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'colorValue': serializer.toJson<int>(colorValue),
      'category': serializer.toJson<String>(
        $ShiftTypesTable.$convertercategory.toJson(category),
      ),
      'startMinute': serializer.toJson<int?>(startMinute),
      'endMinute': serializer.toJson<int?>(endMinute),
      'paidMinutes': serializer.toJson<int?>(paidMinutes),
      'nightOverride': serializer.toJson<bool?>(nightOverride),
      'hourlyRateCents': serializer.toJson<int?>(hourlyRateCents),
      'fixedPlusCents': serializer.toJson<int?>(fixedPlusCents),
      'icon': serializer.toJson<String?>(icon),
      'alarmSound': serializer.toJson<String?>(alarmSound),
      'segment2StartMinute': serializer.toJson<int?>(segment2StartMinute),
      'segment2DurationMinutes': serializer.toJson<int?>(
        segment2DurationMinutes,
      ),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ShiftTypeRow copyWith({
    String? id,
    String? code,
    String? name,
    int? colorValue,
    ShiftCategory? category,
    Value<int?> startMinute = const Value.absent(),
    Value<int?> endMinute = const Value.absent(),
    Value<int?> paidMinutes = const Value.absent(),
    Value<bool?> nightOverride = const Value.absent(),
    Value<int?> hourlyRateCents = const Value.absent(),
    Value<int?> fixedPlusCents = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<String?> alarmSound = const Value.absent(),
    Value<int?> segment2StartMinute = const Value.absent(),
    Value<int?> segment2DurationMinutes = const Value.absent(),
    int? sortOrder,
    bool? archived,
    int? createdAt,
    int? updatedAt,
  }) => ShiftTypeRow(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    category: category ?? this.category,
    startMinute: startMinute.present ? startMinute.value : this.startMinute,
    endMinute: endMinute.present ? endMinute.value : this.endMinute,
    paidMinutes: paidMinutes.present ? paidMinutes.value : this.paidMinutes,
    nightOverride: nightOverride.present
        ? nightOverride.value
        : this.nightOverride,
    hourlyRateCents: hourlyRateCents.present
        ? hourlyRateCents.value
        : this.hourlyRateCents,
    fixedPlusCents: fixedPlusCents.present
        ? fixedPlusCents.value
        : this.fixedPlusCents,
    icon: icon.present ? icon.value : this.icon,
    alarmSound: alarmSound.present ? alarmSound.value : this.alarmSound,
    segment2StartMinute: segment2StartMinute.present
        ? segment2StartMinute.value
        : this.segment2StartMinute,
    segment2DurationMinutes: segment2DurationMinutes.present
        ? segment2DurationMinutes.value
        : this.segment2DurationMinutes,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ShiftTypeRow copyWithCompanion(ShiftTypesCompanion data) {
    return ShiftTypeRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      category: data.category.present ? data.category.value : this.category,
      startMinute: data.startMinute.present
          ? data.startMinute.value
          : this.startMinute,
      endMinute: data.endMinute.present ? data.endMinute.value : this.endMinute,
      paidMinutes: data.paidMinutes.present
          ? data.paidMinutes.value
          : this.paidMinutes,
      nightOverride: data.nightOverride.present
          ? data.nightOverride.value
          : this.nightOverride,
      hourlyRateCents: data.hourlyRateCents.present
          ? data.hourlyRateCents.value
          : this.hourlyRateCents,
      fixedPlusCents: data.fixedPlusCents.present
          ? data.fixedPlusCents.value
          : this.fixedPlusCents,
      icon: data.icon.present ? data.icon.value : this.icon,
      alarmSound: data.alarmSound.present
          ? data.alarmSound.value
          : this.alarmSound,
      segment2StartMinute: data.segment2StartMinute.present
          ? data.segment2StartMinute.value
          : this.segment2StartMinute,
      segment2DurationMinutes: data.segment2DurationMinutes.present
          ? data.segment2DurationMinutes.value
          : this.segment2DurationMinutes,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftTypeRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('category: $category, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('paidMinutes: $paidMinutes, ')
          ..write('nightOverride: $nightOverride, ')
          ..write('hourlyRateCents: $hourlyRateCents, ')
          ..write('fixedPlusCents: $fixedPlusCents, ')
          ..write('icon: $icon, ')
          ..write('alarmSound: $alarmSound, ')
          ..write('segment2StartMinute: $segment2StartMinute, ')
          ..write('segment2DurationMinutes: $segment2DurationMinutes, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    name,
    colorValue,
    category,
    startMinute,
    endMinute,
    paidMinutes,
    nightOverride,
    hourlyRateCents,
    fixedPlusCents,
    icon,
    alarmSound,
    segment2StartMinute,
    segment2DurationMinutes,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftTypeRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.colorValue == this.colorValue &&
          other.category == this.category &&
          other.startMinute == this.startMinute &&
          other.endMinute == this.endMinute &&
          other.paidMinutes == this.paidMinutes &&
          other.nightOverride == this.nightOverride &&
          other.hourlyRateCents == this.hourlyRateCents &&
          other.fixedPlusCents == this.fixedPlusCents &&
          other.icon == this.icon &&
          other.alarmSound == this.alarmSound &&
          other.segment2StartMinute == this.segment2StartMinute &&
          other.segment2DurationMinutes == this.segment2DurationMinutes &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ShiftTypesCompanion extends UpdateCompanion<ShiftTypeRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<int> colorValue;
  final Value<ShiftCategory> category;
  final Value<int?> startMinute;
  final Value<int?> endMinute;
  final Value<int?> paidMinutes;
  final Value<bool?> nightOverride;
  final Value<int?> hourlyRateCents;
  final Value<int?> fixedPlusCents;
  final Value<String?> icon;
  final Value<String?> alarmSound;
  final Value<int?> segment2StartMinute;
  final Value<int?> segment2DurationMinutes;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ShiftTypesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.category = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.paidMinutes = const Value.absent(),
    this.nightOverride = const Value.absent(),
    this.hourlyRateCents = const Value.absent(),
    this.fixedPlusCents = const Value.absent(),
    this.icon = const Value.absent(),
    this.alarmSound = const Value.absent(),
    this.segment2StartMinute = const Value.absent(),
    this.segment2DurationMinutes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShiftTypesCompanion.insert({
    required String id,
    required String code,
    required String name,
    required int colorValue,
    required ShiftCategory category,
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.paidMinutes = const Value.absent(),
    this.nightOverride = const Value.absent(),
    this.hourlyRateCents = const Value.absent(),
    this.fixedPlusCents = const Value.absent(),
    this.icon = const Value.absent(),
    this.alarmSound = const Value.absent(),
    this.segment2StartMinute = const Value.absent(),
    this.segment2DurationMinutes = const Value.absent(),
    required int sortOrder,
    this.archived = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       name = Value(name),
       colorValue = Value(colorValue),
       category = Value(category),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ShiftTypeRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<int>? colorValue,
    Expression<String>? category,
    Expression<int>? startMinute,
    Expression<int>? endMinute,
    Expression<int>? paidMinutes,
    Expression<bool>? nightOverride,
    Expression<int>? hourlyRateCents,
    Expression<int>? fixedPlusCents,
    Expression<String>? icon,
    Expression<String>? alarmSound,
    Expression<int>? segment2StartMinute,
    Expression<int>? segment2DurationMinutes,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (colorValue != null) 'color_value': colorValue,
      if (category != null) 'category': category,
      if (startMinute != null) 'start_minute': startMinute,
      if (endMinute != null) 'end_minute': endMinute,
      if (paidMinutes != null) 'paid_minutes': paidMinutes,
      if (nightOverride != null) 'night_override': nightOverride,
      if (hourlyRateCents != null) 'hourly_rate_cents': hourlyRateCents,
      if (fixedPlusCents != null) 'fixed_plus_cents': fixedPlusCents,
      if (icon != null) 'icon': icon,
      if (alarmSound != null) 'alarm_sound': alarmSound,
      if (segment2StartMinute != null)
        'segment2_start_minute': segment2StartMinute,
      if (segment2DurationMinutes != null)
        'segment2_duration_minutes': segment2DurationMinutes,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShiftTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<int>? colorValue,
    Value<ShiftCategory>? category,
    Value<int?>? startMinute,
    Value<int?>? endMinute,
    Value<int?>? paidMinutes,
    Value<bool?>? nightOverride,
    Value<int?>? hourlyRateCents,
    Value<int?>? fixedPlusCents,
    Value<String?>? icon,
    Value<String?>? alarmSound,
    Value<int?>? segment2StartMinute,
    Value<int?>? segment2DurationMinutes,
    Value<int>? sortOrder,
    Value<bool>? archived,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ShiftTypesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      category: category ?? this.category,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      paidMinutes: paidMinutes ?? this.paidMinutes,
      nightOverride: nightOverride ?? this.nightOverride,
      hourlyRateCents: hourlyRateCents ?? this.hourlyRateCents,
      fixedPlusCents: fixedPlusCents ?? this.fixedPlusCents,
      icon: icon ?? this.icon,
      alarmSound: alarmSound ?? this.alarmSound,
      segment2StartMinute: segment2StartMinute ?? this.segment2StartMinute,
      segment2DurationMinutes:
          segment2DurationMinutes ?? this.segment2DurationMinutes,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $ShiftTypesTable.$convertercategory.toSql(category.value),
      );
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (endMinute.present) {
      map['end_minute'] = Variable<int>(endMinute.value);
    }
    if (paidMinutes.present) {
      map['paid_minutes'] = Variable<int>(paidMinutes.value);
    }
    if (nightOverride.present) {
      map['night_override'] = Variable<bool>(nightOverride.value);
    }
    if (hourlyRateCents.present) {
      map['hourly_rate_cents'] = Variable<int>(hourlyRateCents.value);
    }
    if (fixedPlusCents.present) {
      map['fixed_plus_cents'] = Variable<int>(fixedPlusCents.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (alarmSound.present) {
      map['alarm_sound'] = Variable<String>(alarmSound.value);
    }
    if (segment2StartMinute.present) {
      map['segment2_start_minute'] = Variable<int>(segment2StartMinute.value);
    }
    if (segment2DurationMinutes.present) {
      map['segment2_duration_minutes'] = Variable<int>(
        segment2DurationMinutes.value,
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftTypesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('category: $category, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('paidMinutes: $paidMinutes, ')
          ..write('nightOverride: $nightOverride, ')
          ..write('hourlyRateCents: $hourlyRateCents, ')
          ..write('fixedPlusCents: $fixedPlusCents, ')
          ..write('icon: $icon, ')
          ..write('alarmSound: $alarmSound, ')
          ..write('segment2StartMinute: $segment2StartMinute, ')
          ..write('segment2DurationMinutes: $segment2DurationMinutes, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatternsTable extends Patterns
    with TableInfo<$PatternsTable, PatternRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatternsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<List<String>>, String>
  steps = GeneratedColumn<String>(
    'steps',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<List<String>>>($PatternsTable.$convertersteps);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, steps, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patterns';
  @override
  VerificationContext validateIntegrity(
    Insertable<PatternRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PatternRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatternRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      steps: $PatternsTable.$convertersteps.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}steps'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PatternsTable createAlias(String alias) {
    return $PatternsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<List<String>>, String> $convertersteps =
      const StepsConverter();
}

class PatternRow extends DataClass implements Insertable<PatternRow> {
  final String id;
  final String name;

  /// JSON `[[id, ...], ...]`, at least one step.
  final List<List<String>> steps;
  final int createdAt;
  final int updatedAt;
  const PatternRow({
    required this.id,
    required this.name,
    required this.steps,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['steps'] = Variable<String>(
        $PatternsTable.$convertersteps.toSql(steps),
      );
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PatternsCompanion toCompanion(bool nullToAbsent) {
    return PatternsCompanion(
      id: Value(id),
      name: Value(name),
      steps: Value(steps),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PatternRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatternRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      steps: serializer.fromJson<List<List<String>>>(json['steps']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'steps': serializer.toJson<List<List<String>>>(steps),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  PatternRow copyWith({
    String? id,
    String? name,
    List<List<String>>? steps,
    int? createdAt,
    int? updatedAt,
  }) => PatternRow(
    id: id ?? this.id,
    name: name ?? this.name,
    steps: steps ?? this.steps,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PatternRow copyWithCompanion(PatternsCompanion data) {
    return PatternRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      steps: data.steps.present ? data.steps.value : this.steps,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatternRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('steps: $steps, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, steps, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatternRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.steps == this.steps &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PatternsCompanion extends UpdateCompanion<PatternRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<List<List<String>>> steps;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const PatternsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.steps = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatternsCompanion.insert({
    required String id,
    required String name,
    required List<List<String>> steps,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       steps = Value(steps),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PatternRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? steps,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (steps != null) 'steps': steps,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatternsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<List<List<String>>>? steps,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return PatternsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (steps.present) {
      map['steps'] = Variable<String>(
        $PatternsTable.$convertersteps.toSql(steps.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatternsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('steps: $steps, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatternRunsTable extends PatternRuns
    with TableInfo<$PatternRunsTable, PatternRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatternRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calendarIdMeta = const VerificationMeta(
    'calendarId',
  );
  @override
  late final GeneratedColumn<String> calendarId = GeneratedColumn<String>(
    'calendar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES calendars (id)',
    ),
  );
  static const VerificationMeta _patternIdMeta = const VerificationMeta(
    'patternId',
  );
  @override
  late final GeneratedColumn<String> patternId = GeneratedColumn<String>(
    'pattern_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patterns (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CivilDate, String> startDate =
      GeneratedColumn<String>(
        'start_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CivilDate>($PatternRunsTable.$converterstartDate);
  @override
  late final GeneratedColumnWithTypeConverter<CivilDate?, String> endDate =
      GeneratedColumn<String>(
        'end_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<CivilDate?>($PatternRunsTable.$converterendDaten);
  static const VerificationMeta _stepOffsetMeta = const VerificationMeta(
    'stepOffset',
  );
  @override
  late final GeneratedColumn<int> stepOffset = GeneratedColumn<int>(
    'step_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    calendarId,
    patternId,
    startDate,
    endDate,
    stepOffset,
    seq,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pattern_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PatternRunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('calendar_id')) {
      context.handle(
        _calendarIdMeta,
        calendarId.isAcceptableOrUnknown(data['calendar_id']!, _calendarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_calendarIdMeta);
    }
    if (data.containsKey('pattern_id')) {
      context.handle(
        _patternIdMeta,
        patternId.isAcceptableOrUnknown(data['pattern_id']!, _patternIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patternIdMeta);
    }
    if (data.containsKey('step_offset')) {
      context.handle(
        _stepOffsetMeta,
        stepOffset.isAcceptableOrUnknown(data['step_offset']!, _stepOffsetMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PatternRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatternRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      calendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_id'],
      )!,
      patternId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern_id'],
      )!,
      startDate: $PatternRunsTable.$converterstartDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}start_date'],
        )!,
      ),
      endDate: $PatternRunsTable.$converterendDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}end_date'],
        ),
      ),
      stepOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_offset'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PatternRunsTable createAlias(String alias) {
    return $PatternRunsTable(attachedDatabase, alias);
  }

  static TypeConverter<CivilDate, String> $converterstartDate =
      const CivilDateConverter();
  static TypeConverter<CivilDate, String> $converterendDate =
      const CivilDateConverter();
  static TypeConverter<CivilDate?, String?> $converterendDaten =
      NullAwareTypeConverter.wrap($converterendDate);
}

class PatternRunRow extends DataClass implements Insertable<PatternRunRow> {
  final String id;

  /// Calendar the run belongs to (schema v2).
  final String calendarId;
  final String patternId;
  final CivilDate startDate;
  final CivilDate? endDate;
  final int stepOffset;
  final int seq;
  final int createdAt;
  const PatternRunRow({
    required this.id,
    required this.calendarId,
    required this.patternId,
    required this.startDate,
    this.endDate,
    required this.stepOffset,
    required this.seq,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['calendar_id'] = Variable<String>(calendarId);
    map['pattern_id'] = Variable<String>(patternId);
    {
      map['start_date'] = Variable<String>(
        $PatternRunsTable.$converterstartDate.toSql(startDate),
      );
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(
        $PatternRunsTable.$converterendDaten.toSql(endDate),
      );
    }
    map['step_offset'] = Variable<int>(stepOffset);
    map['seq'] = Variable<int>(seq);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PatternRunsCompanion toCompanion(bool nullToAbsent) {
    return PatternRunsCompanion(
      id: Value(id),
      calendarId: Value(calendarId),
      patternId: Value(patternId),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      stepOffset: Value(stepOffset),
      seq: Value(seq),
      createdAt: Value(createdAt),
    );
  }

  factory PatternRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatternRunRow(
      id: serializer.fromJson<String>(json['id']),
      calendarId: serializer.fromJson<String>(json['calendarId']),
      patternId: serializer.fromJson<String>(json['patternId']),
      startDate: serializer.fromJson<CivilDate>(json['startDate']),
      endDate: serializer.fromJson<CivilDate?>(json['endDate']),
      stepOffset: serializer.fromJson<int>(json['stepOffset']),
      seq: serializer.fromJson<int>(json['seq']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'calendarId': serializer.toJson<String>(calendarId),
      'patternId': serializer.toJson<String>(patternId),
      'startDate': serializer.toJson<CivilDate>(startDate),
      'endDate': serializer.toJson<CivilDate?>(endDate),
      'stepOffset': serializer.toJson<int>(stepOffset),
      'seq': serializer.toJson<int>(seq),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PatternRunRow copyWith({
    String? id,
    String? calendarId,
    String? patternId,
    CivilDate? startDate,
    Value<CivilDate?> endDate = const Value.absent(),
    int? stepOffset,
    int? seq,
    int? createdAt,
  }) => PatternRunRow(
    id: id ?? this.id,
    calendarId: calendarId ?? this.calendarId,
    patternId: patternId ?? this.patternId,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    stepOffset: stepOffset ?? this.stepOffset,
    seq: seq ?? this.seq,
    createdAt: createdAt ?? this.createdAt,
  );
  PatternRunRow copyWithCompanion(PatternRunsCompanion data) {
    return PatternRunRow(
      id: data.id.present ? data.id.value : this.id,
      calendarId: data.calendarId.present
          ? data.calendarId.value
          : this.calendarId,
      patternId: data.patternId.present ? data.patternId.value : this.patternId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      stepOffset: data.stepOffset.present
          ? data.stepOffset.value
          : this.stepOffset,
      seq: data.seq.present ? data.seq.value : this.seq,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatternRunRow(')
          ..write('id: $id, ')
          ..write('calendarId: $calendarId, ')
          ..write('patternId: $patternId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('stepOffset: $stepOffset, ')
          ..write('seq: $seq, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    calendarId,
    patternId,
    startDate,
    endDate,
    stepOffset,
    seq,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatternRunRow &&
          other.id == this.id &&
          other.calendarId == this.calendarId &&
          other.patternId == this.patternId &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.stepOffset == this.stepOffset &&
          other.seq == this.seq &&
          other.createdAt == this.createdAt);
}

class PatternRunsCompanion extends UpdateCompanion<PatternRunRow> {
  final Value<String> id;
  final Value<String> calendarId;
  final Value<String> patternId;
  final Value<CivilDate> startDate;
  final Value<CivilDate?> endDate;
  final Value<int> stepOffset;
  final Value<int> seq;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PatternRunsCompanion({
    this.id = const Value.absent(),
    this.calendarId = const Value.absent(),
    this.patternId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.stepOffset = const Value.absent(),
    this.seq = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatternRunsCompanion.insert({
    required String id,
    required String calendarId,
    required String patternId,
    required CivilDate startDate,
    this.endDate = const Value.absent(),
    this.stepOffset = const Value.absent(),
    required int seq,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       calendarId = Value(calendarId),
       patternId = Value(patternId),
       startDate = Value(startDate),
       seq = Value(seq),
       createdAt = Value(createdAt);
  static Insertable<PatternRunRow> custom({
    Expression<String>? id,
    Expression<String>? calendarId,
    Expression<String>? patternId,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? stepOffset,
    Expression<int>? seq,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (calendarId != null) 'calendar_id': calendarId,
      if (patternId != null) 'pattern_id': patternId,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (stepOffset != null) 'step_offset': stepOffset,
      if (seq != null) 'seq': seq,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatternRunsCompanion copyWith({
    Value<String>? id,
    Value<String>? calendarId,
    Value<String>? patternId,
    Value<CivilDate>? startDate,
    Value<CivilDate?>? endDate,
    Value<int>? stepOffset,
    Value<int>? seq,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return PatternRunsCompanion(
      id: id ?? this.id,
      calendarId: calendarId ?? this.calendarId,
      patternId: patternId ?? this.patternId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      stepOffset: stepOffset ?? this.stepOffset,
      seq: seq ?? this.seq,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (calendarId.present) {
      map['calendar_id'] = Variable<String>(calendarId.value);
    }
    if (patternId.present) {
      map['pattern_id'] = Variable<String>(patternId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(
        $PatternRunsTable.$converterstartDate.toSql(startDate.value),
      );
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(
        $PatternRunsTable.$converterendDaten.toSql(endDate.value),
      );
    }
    if (stepOffset.present) {
      map['step_offset'] = Variable<int>(stepOffset.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatternRunsCompanion(')
          ..write('id: $id, ')
          ..write('calendarId: $calendarId, ')
          ..write('patternId: $patternId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('stepOffset: $stepOffset, ')
          ..write('seq: $seq, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayEntriesTable extends DayEntries
    with TableInfo<$DayEntriesTable, DayEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _calendarIdMeta = const VerificationMeta(
    'calendarId',
  );
  @override
  late final GeneratedColumn<String> calendarId = GeneratedColumn<String>(
    'calendar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES calendars (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CivilDate, String> date =
      GeneratedColumn<String>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CivilDate>($DayEntriesTable.$converterdate);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
  shiftTypeIds = GeneratedColumn<String>(
    'shift_type_ids',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<List<String>?>($DayEntriesTable.$convertershiftTypeIdsn);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteReminderMinuteMeta =
      const VerificationMeta('noteReminderMinute');
  @override
  late final GeneratedColumn<int> noteReminderMinute = GeneratedColumn<int>(
    'note_reminder_minute',
    aliasedName,
    true,
    check: () => ComparableExpr(noteReminderMinute).isBetweenValues(0, 1439),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overtimeMinutesMeta = const VerificationMeta(
    'overtimeMinutes',
  );
  @override
  late final GeneratedColumn<int> overtimeMinutes = GeneratedColumn<int>(
    'overtime_minutes',
    aliasedName,
    true,
    check: () => ComparableExpr(overtimeMinutes).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _earlyLeaveMinutesMeta = const VerificationMeta(
    'earlyLeaveMinutes',
  );
  @override
  late final GeneratedColumn<int> earlyLeaveMinutes = GeneratedColumn<int>(
    'early_leave_minutes',
    aliasedName,
    true,
    check: () => ComparableExpr(earlyLeaveMinutes).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    calendarId,
    date,
    shiftTypeIds,
    note,
    updatedAt,
    noteReminderMinute,
    overtimeMinutes,
    earlyLeaveMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('calendar_id')) {
      context.handle(
        _calendarIdMeta,
        calendarId.isAcceptableOrUnknown(data['calendar_id']!, _calendarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_calendarIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('note_reminder_minute')) {
      context.handle(
        _noteReminderMinuteMeta,
        noteReminderMinute.isAcceptableOrUnknown(
          data['note_reminder_minute']!,
          _noteReminderMinuteMeta,
        ),
      );
    }
    if (data.containsKey('overtime_minutes')) {
      context.handle(
        _overtimeMinutesMeta,
        overtimeMinutes.isAcceptableOrUnknown(
          data['overtime_minutes']!,
          _overtimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('early_leave_minutes')) {
      context.handle(
        _earlyLeaveMinutesMeta,
        earlyLeaveMinutes.isAcceptableOrUnknown(
          data['early_leave_minutes']!,
          _earlyLeaveMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {calendarId, date};
  @override
  DayEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayEntryRow(
      calendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_id'],
      )!,
      date: $DayEntriesTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      shiftTypeIds: $DayEntriesTable.$convertershiftTypeIdsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}shift_type_ids'],
        ),
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      noteReminderMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}note_reminder_minute'],
      ),
      overtimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overtime_minutes'],
      ),
      earlyLeaveMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}early_leave_minutes'],
      ),
    );
  }

  @override
  $DayEntriesTable createAlias(String alias) {
    return $DayEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<CivilDate, String> $converterdate =
      const CivilDateConverter();
  static TypeConverter<List<String>, String> $convertershiftTypeIds =
      const StringListConverter();
  static TypeConverter<List<String>?, String?> $convertershiftTypeIdsn =
      NullAwareTypeConverter.wrap($convertershiftTypeIds);
}

class DayEntryRow extends DataClass implements Insertable<DayEntryRow> {
  /// Calendar the day belongs to (schema v2: the key is calendar + date).
  final String calendarId;
  final CivilDate date;

  /// JSON list. NULL = does not replace the pattern; `[]` = empty day. A row
  /// exists only if the day holds something (override, note, reminder,
  /// overtime or early leave).
  final List<String>? shiftTypeIds;
  final String? note;
  final int updatedAt;

  /// Minute of this civil day (0-1439) at which the note rings. Added in
  /// schema v3.
  final int? noteReminderMinute;

  /// Extra minutes worked this day (>= 0). Added in schema v3.
  final int? overtimeMinutes;

  /// Minutes left before the end of the shift (>= 0). Added in schema v3.
  final int? earlyLeaveMinutes;
  const DayEntryRow({
    required this.calendarId,
    required this.date,
    this.shiftTypeIds,
    this.note,
    required this.updatedAt,
    this.noteReminderMinute,
    this.overtimeMinutes,
    this.earlyLeaveMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['calendar_id'] = Variable<String>(calendarId);
    {
      map['date'] = Variable<String>(
        $DayEntriesTable.$converterdate.toSql(date),
      );
    }
    if (!nullToAbsent || shiftTypeIds != null) {
      map['shift_type_ids'] = Variable<String>(
        $DayEntriesTable.$convertershiftTypeIdsn.toSql(shiftTypeIds),
      );
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || noteReminderMinute != null) {
      map['note_reminder_minute'] = Variable<int>(noteReminderMinute);
    }
    if (!nullToAbsent || overtimeMinutes != null) {
      map['overtime_minutes'] = Variable<int>(overtimeMinutes);
    }
    if (!nullToAbsent || earlyLeaveMinutes != null) {
      map['early_leave_minutes'] = Variable<int>(earlyLeaveMinutes);
    }
    return map;
  }

  DayEntriesCompanion toCompanion(bool nullToAbsent) {
    return DayEntriesCompanion(
      calendarId: Value(calendarId),
      date: Value(date),
      shiftTypeIds: shiftTypeIds == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftTypeIds),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      updatedAt: Value(updatedAt),
      noteReminderMinute: noteReminderMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(noteReminderMinute),
      overtimeMinutes: overtimeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(overtimeMinutes),
      earlyLeaveMinutes: earlyLeaveMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(earlyLeaveMinutes),
    );
  }

  factory DayEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayEntryRow(
      calendarId: serializer.fromJson<String>(json['calendarId']),
      date: serializer.fromJson<CivilDate>(json['date']),
      shiftTypeIds: serializer.fromJson<List<String>?>(json['shiftTypeIds']),
      note: serializer.fromJson<String?>(json['note']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      noteReminderMinute: serializer.fromJson<int?>(json['noteReminderMinute']),
      overtimeMinutes: serializer.fromJson<int?>(json['overtimeMinutes']),
      earlyLeaveMinutes: serializer.fromJson<int?>(json['earlyLeaveMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'calendarId': serializer.toJson<String>(calendarId),
      'date': serializer.toJson<CivilDate>(date),
      'shiftTypeIds': serializer.toJson<List<String>?>(shiftTypeIds),
      'note': serializer.toJson<String?>(note),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'noteReminderMinute': serializer.toJson<int?>(noteReminderMinute),
      'overtimeMinutes': serializer.toJson<int?>(overtimeMinutes),
      'earlyLeaveMinutes': serializer.toJson<int?>(earlyLeaveMinutes),
    };
  }

  DayEntryRow copyWith({
    String? calendarId,
    CivilDate? date,
    Value<List<String>?> shiftTypeIds = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? updatedAt,
    Value<int?> noteReminderMinute = const Value.absent(),
    Value<int?> overtimeMinutes = const Value.absent(),
    Value<int?> earlyLeaveMinutes = const Value.absent(),
  }) => DayEntryRow(
    calendarId: calendarId ?? this.calendarId,
    date: date ?? this.date,
    shiftTypeIds: shiftTypeIds.present ? shiftTypeIds.value : this.shiftTypeIds,
    note: note.present ? note.value : this.note,
    updatedAt: updatedAt ?? this.updatedAt,
    noteReminderMinute: noteReminderMinute.present
        ? noteReminderMinute.value
        : this.noteReminderMinute,
    overtimeMinutes: overtimeMinutes.present
        ? overtimeMinutes.value
        : this.overtimeMinutes,
    earlyLeaveMinutes: earlyLeaveMinutes.present
        ? earlyLeaveMinutes.value
        : this.earlyLeaveMinutes,
  );
  DayEntryRow copyWithCompanion(DayEntriesCompanion data) {
    return DayEntryRow(
      calendarId: data.calendarId.present
          ? data.calendarId.value
          : this.calendarId,
      date: data.date.present ? data.date.value : this.date,
      shiftTypeIds: data.shiftTypeIds.present
          ? data.shiftTypeIds.value
          : this.shiftTypeIds,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      noteReminderMinute: data.noteReminderMinute.present
          ? data.noteReminderMinute.value
          : this.noteReminderMinute,
      overtimeMinutes: data.overtimeMinutes.present
          ? data.overtimeMinutes.value
          : this.overtimeMinutes,
      earlyLeaveMinutes: data.earlyLeaveMinutes.present
          ? data.earlyLeaveMinutes.value
          : this.earlyLeaveMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayEntryRow(')
          ..write('calendarId: $calendarId, ')
          ..write('date: $date, ')
          ..write('shiftTypeIds: $shiftTypeIds, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('noteReminderMinute: $noteReminderMinute, ')
          ..write('overtimeMinutes: $overtimeMinutes, ')
          ..write('earlyLeaveMinutes: $earlyLeaveMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    calendarId,
    date,
    shiftTypeIds,
    note,
    updatedAt,
    noteReminderMinute,
    overtimeMinutes,
    earlyLeaveMinutes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayEntryRow &&
          other.calendarId == this.calendarId &&
          other.date == this.date &&
          other.shiftTypeIds == this.shiftTypeIds &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt &&
          other.noteReminderMinute == this.noteReminderMinute &&
          other.overtimeMinutes == this.overtimeMinutes &&
          other.earlyLeaveMinutes == this.earlyLeaveMinutes);
}

class DayEntriesCompanion extends UpdateCompanion<DayEntryRow> {
  final Value<String> calendarId;
  final Value<CivilDate> date;
  final Value<List<String>?> shiftTypeIds;
  final Value<String?> note;
  final Value<int> updatedAt;
  final Value<int?> noteReminderMinute;
  final Value<int?> overtimeMinutes;
  final Value<int?> earlyLeaveMinutes;
  final Value<int> rowid;
  const DayEntriesCompanion({
    this.calendarId = const Value.absent(),
    this.date = const Value.absent(),
    this.shiftTypeIds = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.noteReminderMinute = const Value.absent(),
    this.overtimeMinutes = const Value.absent(),
    this.earlyLeaveMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayEntriesCompanion.insert({
    required String calendarId,
    required CivilDate date,
    this.shiftTypeIds = const Value.absent(),
    this.note = const Value.absent(),
    required int updatedAt,
    this.noteReminderMinute = const Value.absent(),
    this.overtimeMinutes = const Value.absent(),
    this.earlyLeaveMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : calendarId = Value(calendarId),
       date = Value(date),
       updatedAt = Value(updatedAt);
  static Insertable<DayEntryRow> custom({
    Expression<String>? calendarId,
    Expression<String>? date,
    Expression<String>? shiftTypeIds,
    Expression<String>? note,
    Expression<int>? updatedAt,
    Expression<int>? noteReminderMinute,
    Expression<int>? overtimeMinutes,
    Expression<int>? earlyLeaveMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (calendarId != null) 'calendar_id': calendarId,
      if (date != null) 'date': date,
      if (shiftTypeIds != null) 'shift_type_ids': shiftTypeIds,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (noteReminderMinute != null)
        'note_reminder_minute': noteReminderMinute,
      if (overtimeMinutes != null) 'overtime_minutes': overtimeMinutes,
      if (earlyLeaveMinutes != null) 'early_leave_minutes': earlyLeaveMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayEntriesCompanion copyWith({
    Value<String>? calendarId,
    Value<CivilDate>? date,
    Value<List<String>?>? shiftTypeIds,
    Value<String?>? note,
    Value<int>? updatedAt,
    Value<int?>? noteReminderMinute,
    Value<int?>? overtimeMinutes,
    Value<int?>? earlyLeaveMinutes,
    Value<int>? rowid,
  }) {
    return DayEntriesCompanion(
      calendarId: calendarId ?? this.calendarId,
      date: date ?? this.date,
      shiftTypeIds: shiftTypeIds ?? this.shiftTypeIds,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      noteReminderMinute: noteReminderMinute ?? this.noteReminderMinute,
      overtimeMinutes: overtimeMinutes ?? this.overtimeMinutes,
      earlyLeaveMinutes: earlyLeaveMinutes ?? this.earlyLeaveMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (calendarId.present) {
      map['calendar_id'] = Variable<String>(calendarId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(
        $DayEntriesTable.$converterdate.toSql(date.value),
      );
    }
    if (shiftTypeIds.present) {
      map['shift_type_ids'] = Variable<String>(
        $DayEntriesTable.$convertershiftTypeIdsn.toSql(shiftTypeIds.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (noteReminderMinute.present) {
      map['note_reminder_minute'] = Variable<int>(noteReminderMinute.value);
    }
    if (overtimeMinutes.present) {
      map['overtime_minutes'] = Variable<int>(overtimeMinutes.value);
    }
    if (earlyLeaveMinutes.present) {
      map['early_leave_minutes'] = Variable<int>(earlyLeaveMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayEntriesCompanion(')
          ..write('calendarId: $calendarId, ')
          ..write('date: $date, ')
          ..write('shiftTypeIds: $shiftTypeIds, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('noteReminderMinute: $noteReminderMinute, ')
          ..write('overtimeMinutes: $overtimeMinutes, ')
          ..write('earlyLeaveMinutes: $earlyLeaveMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HolidaysTable extends Holidays
    with TableInfo<$HolidaysTable, HolidayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HolidaysTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionCodeMeta = const VerificationMeta(
    'regionCode',
  );
  @override
  late final GeneratedColumn<String> regionCode = GeneratedColumn<String>(
    'region_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _municipalityCodeMeta = const VerificationMeta(
    'municipalityCode',
  );
  @override
  late final GeneratedColumn<String> municipalityCode = GeneratedColumn<String>(
    'municipality_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    scope,
    name,
    regionCode,
    municipalityCode,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'holidays';
  @override
  VerificationContext validateIntegrity(
    Insertable<HolidayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('region_code')) {
      context.handle(
        _regionCodeMeta,
        regionCode.isAcceptableOrUnknown(data['region_code']!, _regionCodeMeta),
      );
    }
    if (data.containsKey('municipality_code')) {
      context.handle(
        _municipalityCodeMeta,
        municipalityCode.isAcceptableOrUnknown(
          data['municipality_code']!,
          _municipalityCodeMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HolidayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HolidayRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      regionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region_code'],
      ),
      municipalityCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality_code'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $HolidaysTable createAlias(String alias) {
    return $HolidaysTable(attachedDatabase, alias);
  }
}

class HolidayRow extends DataClass implements Insertable<HolidayRow> {
  final int id;

  /// ISO `YYYY-MM-DD`.
  final String date;

  /// `national` / `regional` / `local`.
  final String scope;
  final String name;
  final String? regionCode;
  final String? municipalityCode;

  /// `bundled` / `remote` / `user`.
  final String source;
  const HolidayRow({
    required this.id,
    required this.date,
    required this.scope,
    required this.name,
    this.regionCode,
    this.municipalityCode,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['scope'] = Variable<String>(scope);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || regionCode != null) {
      map['region_code'] = Variable<String>(regionCode);
    }
    if (!nullToAbsent || municipalityCode != null) {
      map['municipality_code'] = Variable<String>(municipalityCode);
    }
    map['source'] = Variable<String>(source);
    return map;
  }

  HolidaysCompanion toCompanion(bool nullToAbsent) {
    return HolidaysCompanion(
      id: Value(id),
      date: Value(date),
      scope: Value(scope),
      name: Value(name),
      regionCode: regionCode == null && nullToAbsent
          ? const Value.absent()
          : Value(regionCode),
      municipalityCode: municipalityCode == null && nullToAbsent
          ? const Value.absent()
          : Value(municipalityCode),
      source: Value(source),
    );
  }

  factory HolidayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HolidayRow(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      scope: serializer.fromJson<String>(json['scope']),
      name: serializer.fromJson<String>(json['name']),
      regionCode: serializer.fromJson<String?>(json['regionCode']),
      municipalityCode: serializer.fromJson<String?>(json['municipalityCode']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'scope': serializer.toJson<String>(scope),
      'name': serializer.toJson<String>(name),
      'regionCode': serializer.toJson<String?>(regionCode),
      'municipalityCode': serializer.toJson<String?>(municipalityCode),
      'source': serializer.toJson<String>(source),
    };
  }

  HolidayRow copyWith({
    int? id,
    String? date,
    String? scope,
    String? name,
    Value<String?> regionCode = const Value.absent(),
    Value<String?> municipalityCode = const Value.absent(),
    String? source,
  }) => HolidayRow(
    id: id ?? this.id,
    date: date ?? this.date,
    scope: scope ?? this.scope,
    name: name ?? this.name,
    regionCode: regionCode.present ? regionCode.value : this.regionCode,
    municipalityCode: municipalityCode.present
        ? municipalityCode.value
        : this.municipalityCode,
    source: source ?? this.source,
  );
  HolidayRow copyWithCompanion(HolidaysCompanion data) {
    return HolidayRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      scope: data.scope.present ? data.scope.value : this.scope,
      name: data.name.present ? data.name.value : this.name,
      regionCode: data.regionCode.present
          ? data.regionCode.value
          : this.regionCode,
      municipalityCode: data.municipalityCode.present
          ? data.municipalityCode.value
          : this.municipalityCode,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HolidayRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('scope: $scope, ')
          ..write('name: $name, ')
          ..write('regionCode: $regionCode, ')
          ..write('municipalityCode: $municipalityCode, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, scope, name, regionCode, municipalityCode, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HolidayRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.scope == this.scope &&
          other.name == this.name &&
          other.regionCode == this.regionCode &&
          other.municipalityCode == this.municipalityCode &&
          other.source == this.source);
}

class HolidaysCompanion extends UpdateCompanion<HolidayRow> {
  final Value<int> id;
  final Value<String> date;
  final Value<String> scope;
  final Value<String> name;
  final Value<String?> regionCode;
  final Value<String?> municipalityCode;
  final Value<String> source;
  const HolidaysCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.scope = const Value.absent(),
    this.name = const Value.absent(),
    this.regionCode = const Value.absent(),
    this.municipalityCode = const Value.absent(),
    this.source = const Value.absent(),
  });
  HolidaysCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required String scope,
    required String name,
    this.regionCode = const Value.absent(),
    this.municipalityCode = const Value.absent(),
    required String source,
  }) : date = Value(date),
       scope = Value(scope),
       name = Value(name),
       source = Value(source);
  static Insertable<HolidayRow> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? scope,
    Expression<String>? name,
    Expression<String>? regionCode,
    Expression<String>? municipalityCode,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (scope != null) 'scope': scope,
      if (name != null) 'name': name,
      if (regionCode != null) 'region_code': regionCode,
      if (municipalityCode != null) 'municipality_code': municipalityCode,
      if (source != null) 'source': source,
    });
  }

  HolidaysCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String>? scope,
    Value<String>? name,
    Value<String?>? regionCode,
    Value<String?>? municipalityCode,
    Value<String>? source,
  }) {
    return HolidaysCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      scope: scope ?? this.scope,
      name: name ?? this.name,
      regionCode: regionCode ?? this.regionCode,
      municipalityCode: municipalityCode ?? this.municipalityCode,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (regionCode.present) {
      map['region_code'] = Variable<String>(regionCode.value);
    }
    if (municipalityCode.present) {
      map['municipality_code'] = Variable<String>(municipalityCode.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HolidaysCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('scope: $scope, ')
          ..write('name: $name, ')
          ..write('regionCode: $regionCode, ')
          ..write('municipalityCode: $municipalityCode, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $AbsenceBalancesTable extends AbsenceBalances
    with TableInfo<$AbsenceBalancesTable, AbsenceBalanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AbsenceBalancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allowedDaysMeta = const VerificationMeta(
    'allowedDays',
  );
  @override
  late final GeneratedColumn<double> allowedDays = GeneratedColumn<double>(
    'allowed_days',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [year, type, allowedDays];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'absence_balances';
  @override
  VerificationContext validateIntegrity(
    Insertable<AbsenceBalanceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('allowed_days')) {
      context.handle(
        _allowedDaysMeta,
        allowedDays.isAcceptableOrUnknown(
          data['allowed_days']!,
          _allowedDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allowedDaysMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {year, type};
  @override
  AbsenceBalanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AbsenceBalanceRow(
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      allowedDays: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}allowed_days'],
      )!,
    );
  }

  @override
  $AbsenceBalancesTable createAlias(String alias) {
    return $AbsenceBalancesTable(attachedDatabase, alias);
  }
}

class AbsenceBalanceRow extends DataClass
    implements Insertable<AbsenceBalanceRow> {
  final int year;
  final String type;
  final double allowedDays;
  const AbsenceBalanceRow({
    required this.year,
    required this.type,
    required this.allowedDays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['year'] = Variable<int>(year);
    map['type'] = Variable<String>(type);
    map['allowed_days'] = Variable<double>(allowedDays);
    return map;
  }

  AbsenceBalancesCompanion toCompanion(bool nullToAbsent) {
    return AbsenceBalancesCompanion(
      year: Value(year),
      type: Value(type),
      allowedDays: Value(allowedDays),
    );
  }

  factory AbsenceBalanceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AbsenceBalanceRow(
      year: serializer.fromJson<int>(json['year']),
      type: serializer.fromJson<String>(json['type']),
      allowedDays: serializer.fromJson<double>(json['allowedDays']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'year': serializer.toJson<int>(year),
      'type': serializer.toJson<String>(type),
      'allowedDays': serializer.toJson<double>(allowedDays),
    };
  }

  AbsenceBalanceRow copyWith({int? year, String? type, double? allowedDays}) =>
      AbsenceBalanceRow(
        year: year ?? this.year,
        type: type ?? this.type,
        allowedDays: allowedDays ?? this.allowedDays,
      );
  AbsenceBalanceRow copyWithCompanion(AbsenceBalancesCompanion data) {
    return AbsenceBalanceRow(
      year: data.year.present ? data.year.value : this.year,
      type: data.type.present ? data.type.value : this.type,
      allowedDays: data.allowedDays.present
          ? data.allowedDays.value
          : this.allowedDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AbsenceBalanceRow(')
          ..write('year: $year, ')
          ..write('type: $type, ')
          ..write('allowedDays: $allowedDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(year, type, allowedDays);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AbsenceBalanceRow &&
          other.year == this.year &&
          other.type == this.type &&
          other.allowedDays == this.allowedDays);
}

class AbsenceBalancesCompanion extends UpdateCompanion<AbsenceBalanceRow> {
  final Value<int> year;
  final Value<String> type;
  final Value<double> allowedDays;
  final Value<int> rowid;
  const AbsenceBalancesCompanion({
    this.year = const Value.absent(),
    this.type = const Value.absent(),
    this.allowedDays = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AbsenceBalancesCompanion.insert({
    required int year,
    required String type,
    required double allowedDays,
    this.rowid = const Value.absent(),
  }) : year = Value(year),
       type = Value(type),
       allowedDays = Value(allowedDays);
  static Insertable<AbsenceBalanceRow> custom({
    Expression<int>? year,
    Expression<String>? type,
    Expression<double>? allowedDays,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (year != null) 'year': year,
      if (type != null) 'type': type,
      if (allowedDays != null) 'allowed_days': allowedDays,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AbsenceBalancesCompanion copyWith({
    Value<int>? year,
    Value<String>? type,
    Value<double>? allowedDays,
    Value<int>? rowid,
  }) {
    return AbsenceBalancesCompanion(
      year: year ?? this.year,
      type: type ?? this.type,
      allowedDays: allowedDays ?? this.allowedDays,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (allowedDays.present) {
      map['allowed_days'] = Variable<double>(allowedDays.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AbsenceBalancesCompanion(')
          ..write('year: $year, ')
          ..write('type: $type, ')
          ..write('allowedDays: $allowedDays, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;

  /// JSON.
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CalendarsTable calendars = $CalendarsTable(this);
  late final $ShiftTypesTable shiftTypes = $ShiftTypesTable(this);
  late final $PatternsTable patterns = $PatternsTable(this);
  late final $PatternRunsTable patternRuns = $PatternRunsTable(this);
  late final $DayEntriesTable dayEntries = $DayEntriesTable(this);
  late final $HolidaysTable holidays = $HolidaysTable(this);
  late final $AbsenceBalancesTable absenceBalances = $AbsenceBalancesTable(
    this,
  );
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index idxHolidaysDate = Index(
    'idx_holidays_date',
    'CREATE INDEX idx_holidays_date ON holidays (date)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    calendars,
    shiftTypes,
    patterns,
    patternRuns,
    dayEntries,
    holidays,
    absenceBalances,
    settings,
    idxHolidaysDate,
  ];
}

typedef $$CalendarsTableCreateCompanionBuilder = CalendarsCompanion Function({
  required String id,
  required String name,
  required int colorValue,
  required int sortOrder,
  Value<bool> archived,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$CalendarsTableUpdateCompanionBuilder = CalendarsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> colorValue,
  Value<int> sortOrder,
  Value<bool> archived,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$CalendarsTableReferences
    extends BaseReferences<_$AppDatabase, $CalendarsTable, CalendarRow> {
  $$CalendarsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PatternRunsTable, List<PatternRunRow>>
  _patternRunsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.patternRuns,
    aliasName: 'calendars__id__pattern_runs__calendar_id',
  );

  $$PatternRunsTableProcessedTableManager get patternRunsRefs {
    final manager = $$PatternRunsTableTableManager(
      $_db,
      $_db.patternRuns,
    ).filter((f) => f.calendarId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_patternRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DayEntriesTable, List<DayEntryRow>>
  _dayEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dayEntries,
    aliasName: 'calendars__id__day_entries__calendar_id',
  );

  $$DayEntriesTableProcessedTableManager get dayEntriesRefs {
    final manager = $$DayEntriesTableTableManager(
      $_db,
      $_db.dayEntries,
    ).filter((f) => f.calendarId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_dayEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CalendarsTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarsTable> {
  $$CalendarsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> patternRunsRefs(
    Expression<bool> Function($$PatternRunsTableFilterComposer f) f,
  ) {
    final $$PatternRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.patternRuns,
      getReferencedColumn: (t) => t.calendarId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternRunsTableFilterComposer(
            $db: $db,
            $table: $db.patternRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dayEntriesRefs(
    Expression<bool> Function($$DayEntriesTableFilterComposer f) f,
  ) {
    final $$DayEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dayEntries,
      getReferencedColumn: (t) => t.calendarId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayEntriesTableFilterComposer(
            $db: $db,
            $table: $db.dayEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CalendarsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarsTable> {
  $$CalendarsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarsTable> {
  $$CalendarsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> patternRunsRefs<T extends Object>(
    Expression<T> Function($$PatternRunsTableAnnotationComposer a) f,
  ) {
    final $$PatternRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.patternRuns,
      getReferencedColumn: (t) => t.calendarId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.patternRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> dayEntriesRefs<T extends Object>(
    Expression<T> Function($$DayEntriesTableAnnotationComposer a) f,
  ) {
    final $$DayEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dayEntries,
      getReferencedColumn: (t) => t.calendarId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.dayEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CalendarsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarsTable,
          CalendarRow,
          $$CalendarsTableFilterComposer,
          $$CalendarsTableOrderingComposer,
          $$CalendarsTableAnnotationComposer,
          $$CalendarsTableCreateCompanionBuilder,
          $$CalendarsTableUpdateCompanionBuilder,
          (CalendarRow, $$CalendarsTableReferences),
          CalendarRow,
          PrefetchHooks Function({bool patternRunsRefs, bool dayEntriesRefs})
        > {
  $$CalendarsTableTableManager(_$AppDatabase db, $CalendarsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarsCompanion(
                id: id,
                name: name,
                colorValue: colorValue,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int colorValue,
                required int sortOrder,
                Value<bool> archived = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CalendarsCompanion.insert(
                id: id,
                name: name,
                colorValue: colorValue,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CalendarsTable, CalendarRow>(table),
                  $$CalendarsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({patternRunsRefs = false, dayEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (patternRunsRefs) db.patternRuns,
                    if (dayEntriesRefs) db.dayEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (patternRunsRefs)
                        await $_getPrefetchedData<
                          CalendarRow,
                          $CalendarsTable,
                          PatternRunRow
                        >(
                          currentTable: table,
                          referencedTable: $$CalendarsTableReferences
                              ._patternRunsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CalendarsTableReferences(
                                db,
                                table,
                                p0,
                              ).patternRunsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.calendarId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (dayEntriesRefs)
                        await $_getPrefetchedData<
                          CalendarRow,
                          $CalendarsTable,
                          DayEntryRow
                        >(
                          currentTable: table,
                          referencedTable: $$CalendarsTableReferences
                              ._dayEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CalendarsTableReferences(
                                db,
                                table,
                                p0,
                              ).dayEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.calendarId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CalendarsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarsTable,
      CalendarRow,
      $$CalendarsTableFilterComposer,
      $$CalendarsTableOrderingComposer,
      $$CalendarsTableAnnotationComposer,
      $$CalendarsTableCreateCompanionBuilder,
      $$CalendarsTableUpdateCompanionBuilder,
      (CalendarRow, $$CalendarsTableReferences),
      CalendarRow,
      PrefetchHooks Function({bool patternRunsRefs, bool dayEntriesRefs})
    >;
typedef $$ShiftTypesTableCreateCompanionBuilder = ShiftTypesCompanion Function({
  required String id,
  required String code,
  required String name,
  required int colorValue,
  required ShiftCategory category,
  Value<int?> startMinute,
  Value<int?> endMinute,
  Value<int?> paidMinutes,
  Value<bool?> nightOverride,
  Value<int?> hourlyRateCents,
  Value<int?> fixedPlusCents,
  Value<String?> icon,
  Value<String?> alarmSound,
  Value<int?> segment2StartMinute,
  Value<int?> segment2DurationMinutes,
  required int sortOrder,
  Value<bool> archived,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$ShiftTypesTableUpdateCompanionBuilder = ShiftTypesCompanion Function({
  Value<String> id,
  Value<String> code,
  Value<String> name,
  Value<int> colorValue,
  Value<ShiftCategory> category,
  Value<int?> startMinute,
  Value<int?> endMinute,
  Value<int?> paidMinutes,
  Value<bool?> nightOverride,
  Value<int?> hourlyRateCents,
  Value<int?> fixedPlusCents,
  Value<String?> icon,
  Value<String?> alarmSound,
  Value<int?> segment2StartMinute,
  Value<int?> segment2DurationMinutes,
  Value<int> sortOrder,
  Value<bool> archived,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$ShiftTypesTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftTypesTable> {
  $$ShiftTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ShiftCategory, ShiftCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidMinutes => $composableBuilder(
    column: $table.paidMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get nightOverride => $composableBuilder(
    column: $table.nightOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hourlyRateCents => $composableBuilder(
    column: $table.hourlyRateCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedPlusCents => $composableBuilder(
    column: $table.fixedPlusCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alarmSound => $composableBuilder(
    column: $table.alarmSound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segment2StartMinute => $composableBuilder(
    column: $table.segment2StartMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segment2DurationMinutes => $composableBuilder(
    column: $table.segment2DurationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShiftTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftTypesTable> {
  $$ShiftTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidMinutes => $composableBuilder(
    column: $table.paidMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get nightOverride => $composableBuilder(
    column: $table.nightOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hourlyRateCents => $composableBuilder(
    column: $table.hourlyRateCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedPlusCents => $composableBuilder(
    column: $table.fixedPlusCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alarmSound => $composableBuilder(
    column: $table.alarmSound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segment2StartMinute => $composableBuilder(
    column: $table.segment2StartMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segment2DurationMinutes => $composableBuilder(
    column: $table.segment2DurationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShiftTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftTypesTable> {
  $$ShiftTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ShiftCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinute =>
      $composableBuilder(column: $table.endMinute, builder: (column) => column);

  GeneratedColumn<int> get paidMinutes => $composableBuilder(
    column: $table.paidMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get nightOverride => $composableBuilder(
    column: $table.nightOverride,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hourlyRateCents => $composableBuilder(
    column: $table.hourlyRateCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedPlusCents => $composableBuilder(
    column: $table.fixedPlusCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get alarmSound => $composableBuilder(
    column: $table.alarmSound,
    builder: (column) => column,
  );

  GeneratedColumn<int> get segment2StartMinute => $composableBuilder(
    column: $table.segment2StartMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get segment2DurationMinutes => $composableBuilder(
    column: $table.segment2DurationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ShiftTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShiftTypesTable,
          ShiftTypeRow,
          $$ShiftTypesTableFilterComposer,
          $$ShiftTypesTableOrderingComposer,
          $$ShiftTypesTableAnnotationComposer,
          $$ShiftTypesTableCreateCompanionBuilder,
          $$ShiftTypesTableUpdateCompanionBuilder,
          (
            ShiftTypeRow,
            BaseReferences<_$AppDatabase, $ShiftTypesTable, ShiftTypeRow>,
          ),
          ShiftTypeRow,
          PrefetchHooks Function()
        > {
  $$ShiftTypesTableTableManager(_$AppDatabase db, $ShiftTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<ShiftCategory> category = const Value.absent(),
                Value<int?> startMinute = const Value.absent(),
                Value<int?> endMinute = const Value.absent(),
                Value<int?> paidMinutes = const Value.absent(),
                Value<bool?> nightOverride = const Value.absent(),
                Value<int?> hourlyRateCents = const Value.absent(),
                Value<int?> fixedPlusCents = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> alarmSound = const Value.absent(),
                Value<int?> segment2StartMinute = const Value.absent(),
                Value<int?> segment2DurationMinutes = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShiftTypesCompanion(
                id: id,
                code: code,
                name: name,
                colorValue: colorValue,
                category: category,
                startMinute: startMinute,
                endMinute: endMinute,
                paidMinutes: paidMinutes,
                nightOverride: nightOverride,
                hourlyRateCents: hourlyRateCents,
                fixedPlusCents: fixedPlusCents,
                icon: icon,
                alarmSound: alarmSound,
                segment2StartMinute: segment2StartMinute,
                segment2DurationMinutes: segment2DurationMinutes,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String name,
                required int colorValue,
                required ShiftCategory category,
                Value<int?> startMinute = const Value.absent(),
                Value<int?> endMinute = const Value.absent(),
                Value<int?> paidMinutes = const Value.absent(),
                Value<bool?> nightOverride = const Value.absent(),
                Value<int?> hourlyRateCents = const Value.absent(),
                Value<int?> fixedPlusCents = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> alarmSound = const Value.absent(),
                Value<int?> segment2StartMinute = const Value.absent(),
                Value<int?> segment2DurationMinutes = const Value.absent(),
                required int sortOrder,
                Value<bool> archived = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ShiftTypesCompanion.insert(
                id: id,
                code: code,
                name: name,
                colorValue: colorValue,
                category: category,
                startMinute: startMinute,
                endMinute: endMinute,
                paidMinutes: paidMinutes,
                nightOverride: nightOverride,
                hourlyRateCents: hourlyRateCents,
                fixedPlusCents: fixedPlusCents,
                icon: icon,
                alarmSound: alarmSound,
                segment2StartMinute: segment2StartMinute,
                segment2DurationMinutes: segment2DurationMinutes,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShiftTypesTable, ShiftTypeRow>(table),
                  BaseReferences<_$AppDatabase, $ShiftTypesTable, ShiftTypeRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShiftTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShiftTypesTable,
      ShiftTypeRow,
      $$ShiftTypesTableFilterComposer,
      $$ShiftTypesTableOrderingComposer,
      $$ShiftTypesTableAnnotationComposer,
      $$ShiftTypesTableCreateCompanionBuilder,
      $$ShiftTypesTableUpdateCompanionBuilder,
      (
        ShiftTypeRow,
        BaseReferences<_$AppDatabase, $ShiftTypesTable, ShiftTypeRow>,
      ),
      ShiftTypeRow,
      PrefetchHooks Function()
    >;
typedef $$PatternsTableCreateCompanionBuilder = PatternsCompanion Function({
  required String id,
  required String name,
  required List<List<String>> steps,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$PatternsTableUpdateCompanionBuilder = PatternsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<List<List<String>>> steps,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$PatternsTableReferences
    extends BaseReferences<_$AppDatabase, $PatternsTable, PatternRow> {
  $$PatternsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PatternRunsTable, List<PatternRunRow>>
  _patternRunsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.patternRuns,
    aliasName: 'patterns__id__pattern_runs__pattern_id',
  );

  $$PatternRunsTableProcessedTableManager get patternRunsRefs {
    final manager = $$PatternRunsTableTableManager(
      $_db,
      $_db.patternRuns,
    ).filter((f) => f.patternId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_patternRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PatternsTableFilterComposer
    extends Composer<_$AppDatabase, $PatternsTable> {
  $$PatternsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<List<String>>, List<List<String>>, String>
  get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> patternRunsRefs(
    Expression<bool> Function($$PatternRunsTableFilterComposer f) f,
  ) {
    final $$PatternRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.patternRuns,
      getReferencedColumn: (t) => t.patternId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternRunsTableFilterComposer(
            $db: $db,
            $table: $db.patternRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PatternsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatternsTable> {
  $$PatternsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PatternsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatternsTable> {
  $$PatternsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<List<String>>, String> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> patternRunsRefs<T extends Object>(
    Expression<T> Function($$PatternRunsTableAnnotationComposer a) f,
  ) {
    final $$PatternRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.patternRuns,
      getReferencedColumn: (t) => t.patternId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.patternRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PatternsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PatternsTable,
          PatternRow,
          $$PatternsTableFilterComposer,
          $$PatternsTableOrderingComposer,
          $$PatternsTableAnnotationComposer,
          $$PatternsTableCreateCompanionBuilder,
          $$PatternsTableUpdateCompanionBuilder,
          (PatternRow, $$PatternsTableReferences),
          PatternRow,
          PrefetchHooks Function({bool patternRunsRefs})
        > {
  $$PatternsTableTableManager(_$AppDatabase db, $PatternsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatternsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatternsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatternsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<List<List<String>>> steps = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatternsCompanion(
                id: id,
                name: name,
                steps: steps,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required List<List<String>> steps,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PatternsCompanion.insert(
                id: id,
                name: name,
                steps: steps,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PatternsTable, PatternRow>(table),
                  $$PatternsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({patternRunsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (patternRunsRefs) db.patternRuns],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (patternRunsRefs)
                    await $_getPrefetchedData<
                      PatternRow,
                      $PatternsTable,
                      PatternRunRow
                    >(
                      currentTable: table,
                      referencedTable: $$PatternsTableReferences
                          ._patternRunsRefsTable(db),
                      managerFromTypedResult: (p0) => $$PatternsTableReferences(
                        db,
                        table,
                        p0,
                      ).patternRunsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.patternId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PatternsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PatternsTable,
      PatternRow,
      $$PatternsTableFilterComposer,
      $$PatternsTableOrderingComposer,
      $$PatternsTableAnnotationComposer,
      $$PatternsTableCreateCompanionBuilder,
      $$PatternsTableUpdateCompanionBuilder,
      (PatternRow, $$PatternsTableReferences),
      PatternRow,
      PrefetchHooks Function({bool patternRunsRefs})
    >;
typedef $$PatternRunsTableCreateCompanionBuilder =
    PatternRunsCompanion Function({
      required String id,
      required String calendarId,
      required String patternId,
      required CivilDate startDate,
      Value<CivilDate?> endDate,
      Value<int> stepOffset,
      required int seq,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$PatternRunsTableUpdateCompanionBuilder =
    PatternRunsCompanion Function({
      Value<String> id,
      Value<String> calendarId,
      Value<String> patternId,
      Value<CivilDate> startDate,
      Value<CivilDate?> endDate,
      Value<int> stepOffset,
      Value<int> seq,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$PatternRunsTableReferences
    extends BaseReferences<_$AppDatabase, $PatternRunsTable, PatternRunRow> {
  $$PatternRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CalendarsTable _calendarIdTable(_$AppDatabase db) =>
      db.calendars.createAlias('pattern_runs__calendar_id__calendars__id');

  $$CalendarsTableProcessedTableManager get calendarId {
    final $_column = $_itemColumn<String>('calendar_id')!;

    final manager = $$CalendarsTableTableManager(
      $_db,
      $_db.calendars,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_calendarIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PatternsTable _patternIdTable(_$AppDatabase db) =>
      db.patterns.createAlias('pattern_runs__pattern_id__patterns__id');

  $$PatternsTableProcessedTableManager get patternId {
    final $_column = $_itemColumn<String>('pattern_id')!;

    final manager = $$PatternsTableTableManager(
      $_db,
      $_db.patterns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patternIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PatternRunsTableFilterComposer
    extends Composer<_$AppDatabase, $PatternRunsTable> {
  $$PatternRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CivilDate, CivilDate, String> get startDate =>
      $composableBuilder(
        column: $table.startDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<CivilDate?, CivilDate, String> get endDate =>
      $composableBuilder(
        column: $table.endDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get stepOffset => $composableBuilder(
    column: $table.stepOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CalendarsTableFilterComposer get calendarId {
    final $$CalendarsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableFilterComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatternsTableFilterComposer get patternId {
    final $$PatternsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patternId,
      referencedTable: $db.patterns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternsTableFilterComposer(
            $db: $db,
            $table: $db.patterns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PatternRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatternRunsTable> {
  $$PatternRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepOffset => $composableBuilder(
    column: $table.stepOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CalendarsTableOrderingComposer get calendarId {
    final $$CalendarsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableOrderingComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatternsTableOrderingComposer get patternId {
    final $$PatternsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patternId,
      referencedTable: $db.patterns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternsTableOrderingComposer(
            $db: $db,
            $table: $db.patterns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PatternRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatternRunsTable> {
  $$PatternRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CivilDate, String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CivilDate?, String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get stepOffset => $composableBuilder(
    column: $table.stepOffset,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CalendarsTableAnnotationComposer get calendarId {
    final $$CalendarsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableAnnotationComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatternsTableAnnotationComposer get patternId {
    final $$PatternsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patternId,
      referencedTable: $db.patterns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternsTableAnnotationComposer(
            $db: $db,
            $table: $db.patterns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PatternRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PatternRunsTable,
          PatternRunRow,
          $$PatternRunsTableFilterComposer,
          $$PatternRunsTableOrderingComposer,
          $$PatternRunsTableAnnotationComposer,
          $$PatternRunsTableCreateCompanionBuilder,
          $$PatternRunsTableUpdateCompanionBuilder,
          (PatternRunRow, $$PatternRunsTableReferences),
          PatternRunRow,
          PrefetchHooks Function({bool calendarId, bool patternId})
        > {
  $$PatternRunsTableTableManager(_$AppDatabase db, $PatternRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatternRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatternRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatternRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> calendarId = const Value.absent(),
                Value<String> patternId = const Value.absent(),
                Value<CivilDate> startDate = const Value.absent(),
                Value<CivilDate?> endDate = const Value.absent(),
                Value<int> stepOffset = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatternRunsCompanion(
                id: id,
                calendarId: calendarId,
                patternId: patternId,
                startDate: startDate,
                endDate: endDate,
                stepOffset: stepOffset,
                seq: seq,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String calendarId,
                required String patternId,
                required CivilDate startDate,
                Value<CivilDate?> endDate = const Value.absent(),
                Value<int> stepOffset = const Value.absent(),
                required int seq,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PatternRunsCompanion.insert(
                id: id,
                calendarId: calendarId,
                patternId: patternId,
                startDate: startDate,
                endDate: endDate,
                stepOffset: stepOffset,
                seq: seq,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PatternRunsTable, PatternRunRow>(table),
                  $$PatternRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({calendarId = false, patternId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (calendarId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.calendarId,
                        referencedTable: $$PatternRunsTableReferences
                            ._calendarIdTable(db),
                        referencedColumn: $$PatternRunsTableReferences
                            ._calendarIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (patternId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.patternId,
                        referencedTable: $$PatternRunsTableReferences
                            ._patternIdTable(db),
                        referencedColumn: $$PatternRunsTableReferences
                            ._patternIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PatternRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PatternRunsTable,
      PatternRunRow,
      $$PatternRunsTableFilterComposer,
      $$PatternRunsTableOrderingComposer,
      $$PatternRunsTableAnnotationComposer,
      $$PatternRunsTableCreateCompanionBuilder,
      $$PatternRunsTableUpdateCompanionBuilder,
      (PatternRunRow, $$PatternRunsTableReferences),
      PatternRunRow,
      PrefetchHooks Function({bool calendarId, bool patternId})
    >;
typedef $$DayEntriesTableCreateCompanionBuilder = DayEntriesCompanion Function({
  required String calendarId,
  required CivilDate date,
  Value<List<String>?> shiftTypeIds,
  Value<String?> note,
  required int updatedAt,
  Value<int?> noteReminderMinute,
  Value<int?> overtimeMinutes,
  Value<int?> earlyLeaveMinutes,
  Value<int> rowid,
});
typedef $$DayEntriesTableUpdateCompanionBuilder = DayEntriesCompanion Function({
  Value<String> calendarId,
  Value<CivilDate> date,
  Value<List<String>?> shiftTypeIds,
  Value<String?> note,
  Value<int> updatedAt,
  Value<int?> noteReminderMinute,
  Value<int?> overtimeMinutes,
  Value<int?> earlyLeaveMinutes,
  Value<int> rowid,
});

final class $$DayEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $DayEntriesTable, DayEntryRow> {
  $$DayEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CalendarsTable _calendarIdTable(_$AppDatabase db) =>
      db.calendars.createAlias('day_entries__calendar_id__calendars__id');

  $$CalendarsTableProcessedTableManager get calendarId {
    final $_column = $_itemColumn<String>('calendar_id')!;

    final manager = $$CalendarsTableTableManager(
      $_db,
      $_db.calendars,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_calendarIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DayEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DayEntriesTable> {
  $$DayEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<CivilDate, CivilDate, String> get date =>
      $composableBuilder(
        column: $table.date,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
  get shiftTypeIds => $composableBuilder(
    column: $table.shiftTypeIds,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noteReminderMinute => $composableBuilder(
    column: $table.noteReminderMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overtimeMinutes => $composableBuilder(
    column: $table.overtimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get earlyLeaveMinutes => $composableBuilder(
    column: $table.earlyLeaveMinutes,
    builder: (column) => ColumnFilters(column),
  );

  $$CalendarsTableFilterComposer get calendarId {
    final $$CalendarsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableFilterComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DayEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DayEntriesTable> {
  $$DayEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftTypeIds => $composableBuilder(
    column: $table.shiftTypeIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noteReminderMinute => $composableBuilder(
    column: $table.noteReminderMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overtimeMinutes => $composableBuilder(
    column: $table.overtimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get earlyLeaveMinutes => $composableBuilder(
    column: $table.earlyLeaveMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  $$CalendarsTableOrderingComposer get calendarId {
    final $$CalendarsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableOrderingComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DayEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayEntriesTable> {
  $$DayEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<CivilDate, String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>?, String> get shiftTypeIds =>
      $composableBuilder(
        column: $table.shiftTypeIds,
        builder: (column) => column,
      );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get noteReminderMinute => $composableBuilder(
    column: $table.noteReminderMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overtimeMinutes => $composableBuilder(
    column: $table.overtimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get earlyLeaveMinutes => $composableBuilder(
    column: $table.earlyLeaveMinutes,
    builder: (column) => column,
  );

  $$CalendarsTableAnnotationComposer get calendarId {
    final $$CalendarsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableAnnotationComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DayEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayEntriesTable,
          DayEntryRow,
          $$DayEntriesTableFilterComposer,
          $$DayEntriesTableOrderingComposer,
          $$DayEntriesTableAnnotationComposer,
          $$DayEntriesTableCreateCompanionBuilder,
          $$DayEntriesTableUpdateCompanionBuilder,
          (DayEntryRow, $$DayEntriesTableReferences),
          DayEntryRow,
          PrefetchHooks Function({bool calendarId})
        > {
  $$DayEntriesTableTableManager(_$AppDatabase db, $DayEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> calendarId = const Value.absent(),
                Value<CivilDate> date = const Value.absent(),
                Value<List<String>?> shiftTypeIds = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> noteReminderMinute = const Value.absent(),
                Value<int?> overtimeMinutes = const Value.absent(),
                Value<int?> earlyLeaveMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayEntriesCompanion(
                calendarId: calendarId,
                date: date,
                shiftTypeIds: shiftTypeIds,
                note: note,
                updatedAt: updatedAt,
                noteReminderMinute: noteReminderMinute,
                overtimeMinutes: overtimeMinutes,
                earlyLeaveMinutes: earlyLeaveMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String calendarId,
                required CivilDate date,
                Value<List<String>?> shiftTypeIds = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int updatedAt,
                Value<int?> noteReminderMinute = const Value.absent(),
                Value<int?> overtimeMinutes = const Value.absent(),
                Value<int?> earlyLeaveMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayEntriesCompanion.insert(
                calendarId: calendarId,
                date: date,
                shiftTypeIds: shiftTypeIds,
                note: note,
                updatedAt: updatedAt,
                noteReminderMinute: noteReminderMinute,
                overtimeMinutes: overtimeMinutes,
                earlyLeaveMinutes: earlyLeaveMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DayEntriesTable, DayEntryRow>(table),
                  $$DayEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({calendarId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (calendarId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.calendarId,
                        referencedTable: $$DayEntriesTableReferences
                            ._calendarIdTable(db),
                        referencedColumn: $$DayEntriesTableReferences
                            ._calendarIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DayEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayEntriesTable,
      DayEntryRow,
      $$DayEntriesTableFilterComposer,
      $$DayEntriesTableOrderingComposer,
      $$DayEntriesTableAnnotationComposer,
      $$DayEntriesTableCreateCompanionBuilder,
      $$DayEntriesTableUpdateCompanionBuilder,
      (DayEntryRow, $$DayEntriesTableReferences),
      DayEntryRow,
      PrefetchHooks Function({bool calendarId})
    >;
typedef $$HolidaysTableCreateCompanionBuilder = HolidaysCompanion Function({
  Value<int> id,
  required String date,
  required String scope,
  required String name,
  Value<String?> regionCode,
  Value<String?> municipalityCode,
  required String source,
});
typedef $$HolidaysTableUpdateCompanionBuilder = HolidaysCompanion Function({
  Value<int> id,
  Value<String> date,
  Value<String> scope,
  Value<String> name,
  Value<String?> regionCode,
  Value<String?> municipalityCode,
  Value<String> source,
});

class $$HolidaysTableFilterComposer
    extends Composer<_$AppDatabase, $HolidaysTable> {
  $$HolidaysTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipalityCode => $composableBuilder(
    column: $table.municipalityCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HolidaysTableOrderingComposer
    extends Composer<_$AppDatabase, $HolidaysTable> {
  $$HolidaysTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipalityCode => $composableBuilder(
    column: $table.municipalityCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HolidaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $HolidaysTable> {
  $$HolidaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get municipalityCode => $composableBuilder(
    column: $table.municipalityCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$HolidaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HolidaysTable,
          HolidayRow,
          $$HolidaysTableFilterComposer,
          $$HolidaysTableOrderingComposer,
          $$HolidaysTableAnnotationComposer,
          $$HolidaysTableCreateCompanionBuilder,
          $$HolidaysTableUpdateCompanionBuilder,
          (
            HolidayRow,
            BaseReferences<_$AppDatabase, $HolidaysTable, HolidayRow>,
          ),
          HolidayRow,
          PrefetchHooks Function()
        > {
  $$HolidaysTableTableManager(_$AppDatabase db, $HolidaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HolidaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HolidaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HolidaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> regionCode = const Value.absent(),
                Value<String?> municipalityCode = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => HolidaysCompanion(
                id: id,
                date: date,
                scope: scope,
                name: name,
                regionCode: regionCode,
                municipalityCode: municipalityCode,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required String scope,
                required String name,
                Value<String?> regionCode = const Value.absent(),
                Value<String?> municipalityCode = const Value.absent(),
                required String source,
              }) => HolidaysCompanion.insert(
                id: id,
                date: date,
                scope: scope,
                name: name,
                regionCode: regionCode,
                municipalityCode: municipalityCode,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HolidaysTable, HolidayRow>(table),
                  BaseReferences<_$AppDatabase, $HolidaysTable, HolidayRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HolidaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HolidaysTable,
      HolidayRow,
      $$HolidaysTableFilterComposer,
      $$HolidaysTableOrderingComposer,
      $$HolidaysTableAnnotationComposer,
      $$HolidaysTableCreateCompanionBuilder,
      $$HolidaysTableUpdateCompanionBuilder,
      (HolidayRow, BaseReferences<_$AppDatabase, $HolidaysTable, HolidayRow>),
      HolidayRow,
      PrefetchHooks Function()
    >;
typedef $$AbsenceBalancesTableCreateCompanionBuilder =
    AbsenceBalancesCompanion Function({
      required int year,
      required String type,
      required double allowedDays,
      Value<int> rowid,
    });
typedef $$AbsenceBalancesTableUpdateCompanionBuilder =
    AbsenceBalancesCompanion Function({
      Value<int> year,
      Value<String> type,
      Value<double> allowedDays,
      Value<int> rowid,
    });

class $$AbsenceBalancesTableFilterComposer
    extends Composer<_$AppDatabase, $AbsenceBalancesTable> {
  $$AbsenceBalancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get allowedDays => $composableBuilder(
    column: $table.allowedDays,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AbsenceBalancesTableOrderingComposer
    extends Composer<_$AppDatabase, $AbsenceBalancesTable> {
  $$AbsenceBalancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get allowedDays => $composableBuilder(
    column: $table.allowedDays,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AbsenceBalancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AbsenceBalancesTable> {
  $$AbsenceBalancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get allowedDays => $composableBuilder(
    column: $table.allowedDays,
    builder: (column) => column,
  );
}

class $$AbsenceBalancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AbsenceBalancesTable,
          AbsenceBalanceRow,
          $$AbsenceBalancesTableFilterComposer,
          $$AbsenceBalancesTableOrderingComposer,
          $$AbsenceBalancesTableAnnotationComposer,
          $$AbsenceBalancesTableCreateCompanionBuilder,
          $$AbsenceBalancesTableUpdateCompanionBuilder,
          (
            AbsenceBalanceRow,
            BaseReferences<
              _$AppDatabase,
              $AbsenceBalancesTable,
              AbsenceBalanceRow
            >,
          ),
          AbsenceBalanceRow,
          PrefetchHooks Function()
        > {
  $$AbsenceBalancesTableTableManager(
    _$AppDatabase db,
    $AbsenceBalancesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AbsenceBalancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AbsenceBalancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AbsenceBalancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> year = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> allowedDays = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AbsenceBalancesCompanion(
                year: year,
                type: type,
                allowedDays: allowedDays,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int year,
                required String type,
                required double allowedDays,
                Value<int> rowid = const Value.absent(),
              }) => AbsenceBalancesCompanion.insert(
                year: year,
                type: type,
                allowedDays: allowedDays,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AbsenceBalancesTable, AbsenceBalanceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AbsenceBalancesTable,
                    AbsenceBalanceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AbsenceBalancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AbsenceBalancesTable,
      AbsenceBalanceRow,
      $$AbsenceBalancesTableFilterComposer,
      $$AbsenceBalancesTableOrderingComposer,
      $$AbsenceBalancesTableAnnotationComposer,
      $$AbsenceBalancesTableCreateCompanionBuilder,
      $$AbsenceBalancesTableUpdateCompanionBuilder,
      (
        AbsenceBalanceRow,
        BaseReferences<_$AppDatabase, $AbsenceBalancesTable, AbsenceBalanceRow>,
      ),
      AbsenceBalanceRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CalendarsTableTableManager get calendars =>
      $$CalendarsTableTableManager(_db, _db.calendars);
  $$ShiftTypesTableTableManager get shiftTypes =>
      $$ShiftTypesTableTableManager(_db, _db.shiftTypes);
  $$PatternsTableTableManager get patterns =>
      $$PatternsTableTableManager(_db, _db.patterns);
  $$PatternRunsTableTableManager get patternRuns =>
      $$PatternRunsTableTableManager(_db, _db.patternRuns);
  $$DayEntriesTableTableManager get dayEntries =>
      $$DayEntriesTableTableManager(_db, _db.dayEntries);
  $$HolidaysTableTableManager get holidays =>
      $$HolidaysTableTableManager(_db, _db.holidays);
  $$AbsenceBalancesTableTableManager get absenceBalances =>
      $$AbsenceBalancesTableTableManager(_db, _db.absenceBalances);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
