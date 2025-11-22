// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $KanjiTableTable extends KanjiTable
    with TableInfo<$KanjiTableTable, KanjiTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KanjiTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _characterMeta = const VerificationMeta(
    'character',
  );
  @override
  late final GeneratedColumn<String> character = GeneratedColumn<String>(
    'character',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> meanings =
      GeneratedColumn<String>(
        'meanings',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($KanjiTableTable.$convertermeanings);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> readingsOn =
      GeneratedColumn<String>(
        'readings_on',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($KanjiTableTable.$converterreadingsOn);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  readingsKun = GeneratedColumn<String>(
    'readings_kun',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($KanjiTableTable.$converterreadingsKun);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  koreanOnReadings = GeneratedColumn<String>(
    'korean_on_readings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($KanjiTableTable.$converterkoreanOnReadings);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  koreanKunReadings = GeneratedColumn<String>(
    'korean_kun_readings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($KanjiTableTable.$converterkoreanKunReadings);
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<int> grade = GeneratedColumn<int>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jlptMeta = const VerificationMeta('jlpt');
  @override
  late final GeneratedColumn<int> jlpt = GeneratedColumn<int>(
    'jlpt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strokeCountMeta = const VerificationMeta(
    'strokeCount',
  );
  @override
  late final GeneratedColumn<int> strokeCount = GeneratedColumn<int>(
    'stroke_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> examples =
      GeneratedColumn<String>(
        'examples',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($KanjiTableTable.$converterexamples);
  static const VerificationMeta _radicalMeta = const VerificationMeta(
    'radical',
  );
  @override
  late final GeneratedColumn<String> radical = GeneratedColumn<String>(
    'radical',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commentaryMeta = const VerificationMeta(
    'commentary',
  );
  @override
  late final GeneratedColumn<String> commentary = GeneratedColumn<String>(
    'commentary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    character,
    meanings,
    readingsOn,
    readingsKun,
    koreanOnReadings,
    koreanKunReadings,
    grade,
    jlpt,
    strokeCount,
    examples,
    radical,
    commentary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kanji_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<KanjiTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('character')) {
      context.handle(
        _characterMeta,
        character.isAcceptableOrUnknown(data['character']!, _characterMeta),
      );
    } else if (isInserting) {
      context.missing(_characterMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('jlpt')) {
      context.handle(
        _jlptMeta,
        jlpt.isAcceptableOrUnknown(data['jlpt']!, _jlptMeta),
      );
    } else if (isInserting) {
      context.missing(_jlptMeta);
    }
    if (data.containsKey('stroke_count')) {
      context.handle(
        _strokeCountMeta,
        strokeCount.isAcceptableOrUnknown(
          data['stroke_count']!,
          _strokeCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strokeCountMeta);
    }
    if (data.containsKey('radical')) {
      context.handle(
        _radicalMeta,
        radical.isAcceptableOrUnknown(data['radical']!, _radicalMeta),
      );
    }
    if (data.containsKey('commentary')) {
      context.handle(
        _commentaryMeta,
        commentary.isAcceptableOrUnknown(data['commentary']!, _commentaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KanjiTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KanjiTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      character: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character'],
      )!,
      meanings: $KanjiTableTable.$convertermeanings.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meanings'],
        )!,
      ),
      readingsOn: $KanjiTableTable.$converterreadingsOn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}readings_on'],
        )!,
      ),
      readingsKun: $KanjiTableTable.$converterreadingsKun.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}readings_kun'],
        )!,
      ),
      koreanOnReadings: $KanjiTableTable.$converterkoreanOnReadings.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}korean_on_readings'],
        )!,
      ),
      koreanKunReadings: $KanjiTableTable.$converterkoreanKunReadings.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}korean_kun_readings'],
        )!,
      ),
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade'],
      )!,
      jlpt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jlpt'],
      )!,
      strokeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stroke_count'],
      )!,
      examples: $KanjiTableTable.$converterexamples.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}examples'],
        )!,
      ),
      radical: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}radical'],
      ),
      commentary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commentary'],
      ),
    );
  }

  @override
  $KanjiTableTable createAlias(String alias) {
    return $KanjiTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertermeanings =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterreadingsOn =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterreadingsKun =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterkoreanOnReadings =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterkoreanKunReadings =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterexamples =
      const StringListConverter();
}

class KanjiTableData extends DataClass implements Insertable<KanjiTableData> {
  final int id;
  final String character;
  final List<String> meanings;
  final List<String> readingsOn;
  final List<String> readingsKun;
  final List<String> koreanOnReadings;
  final List<String> koreanKunReadings;
  final int grade;
  final int jlpt;
  final int strokeCount;
  final List<String> examples;
  final String? radical;
  final String? commentary;
  const KanjiTableData({
    required this.id,
    required this.character,
    required this.meanings,
    required this.readingsOn,
    required this.readingsKun,
    required this.koreanOnReadings,
    required this.koreanKunReadings,
    required this.grade,
    required this.jlpt,
    required this.strokeCount,
    required this.examples,
    this.radical,
    this.commentary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['character'] = Variable<String>(character);
    {
      map['meanings'] = Variable<String>(
        $KanjiTableTable.$convertermeanings.toSql(meanings),
      );
    }
    {
      map['readings_on'] = Variable<String>(
        $KanjiTableTable.$converterreadingsOn.toSql(readingsOn),
      );
    }
    {
      map['readings_kun'] = Variable<String>(
        $KanjiTableTable.$converterreadingsKun.toSql(readingsKun),
      );
    }
    {
      map['korean_on_readings'] = Variable<String>(
        $KanjiTableTable.$converterkoreanOnReadings.toSql(koreanOnReadings),
      );
    }
    {
      map['korean_kun_readings'] = Variable<String>(
        $KanjiTableTable.$converterkoreanKunReadings.toSql(koreanKunReadings),
      );
    }
    map['grade'] = Variable<int>(grade);
    map['jlpt'] = Variable<int>(jlpt);
    map['stroke_count'] = Variable<int>(strokeCount);
    {
      map['examples'] = Variable<String>(
        $KanjiTableTable.$converterexamples.toSql(examples),
      );
    }
    if (!nullToAbsent || radical != null) {
      map['radical'] = Variable<String>(radical);
    }
    if (!nullToAbsent || commentary != null) {
      map['commentary'] = Variable<String>(commentary);
    }
    return map;
  }

  KanjiTableCompanion toCompanion(bool nullToAbsent) {
    return KanjiTableCompanion(
      id: Value(id),
      character: Value(character),
      meanings: Value(meanings),
      readingsOn: Value(readingsOn),
      readingsKun: Value(readingsKun),
      koreanOnReadings: Value(koreanOnReadings),
      koreanKunReadings: Value(koreanKunReadings),
      grade: Value(grade),
      jlpt: Value(jlpt),
      strokeCount: Value(strokeCount),
      examples: Value(examples),
      radical: radical == null && nullToAbsent
          ? const Value.absent()
          : Value(radical),
      commentary: commentary == null && nullToAbsent
          ? const Value.absent()
          : Value(commentary),
    );
  }

  factory KanjiTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KanjiTableData(
      id: serializer.fromJson<int>(json['id']),
      character: serializer.fromJson<String>(json['character']),
      meanings: serializer.fromJson<List<String>>(json['meanings']),
      readingsOn: serializer.fromJson<List<String>>(json['readingsOn']),
      readingsKun: serializer.fromJson<List<String>>(json['readingsKun']),
      koreanOnReadings: serializer.fromJson<List<String>>(
        json['koreanOnReadings'],
      ),
      koreanKunReadings: serializer.fromJson<List<String>>(
        json['koreanKunReadings'],
      ),
      grade: serializer.fromJson<int>(json['grade']),
      jlpt: serializer.fromJson<int>(json['jlpt']),
      strokeCount: serializer.fromJson<int>(json['strokeCount']),
      examples: serializer.fromJson<List<String>>(json['examples']),
      radical: serializer.fromJson<String?>(json['radical']),
      commentary: serializer.fromJson<String?>(json['commentary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'character': serializer.toJson<String>(character),
      'meanings': serializer.toJson<List<String>>(meanings),
      'readingsOn': serializer.toJson<List<String>>(readingsOn),
      'readingsKun': serializer.toJson<List<String>>(readingsKun),
      'koreanOnReadings': serializer.toJson<List<String>>(koreanOnReadings),
      'koreanKunReadings': serializer.toJson<List<String>>(koreanKunReadings),
      'grade': serializer.toJson<int>(grade),
      'jlpt': serializer.toJson<int>(jlpt),
      'strokeCount': serializer.toJson<int>(strokeCount),
      'examples': serializer.toJson<List<String>>(examples),
      'radical': serializer.toJson<String?>(radical),
      'commentary': serializer.toJson<String?>(commentary),
    };
  }

  KanjiTableData copyWith({
    int? id,
    String? character,
    List<String>? meanings,
    List<String>? readingsOn,
    List<String>? readingsKun,
    List<String>? koreanOnReadings,
    List<String>? koreanKunReadings,
    int? grade,
    int? jlpt,
    int? strokeCount,
    List<String>? examples,
    Value<String?> radical = const Value.absent(),
    Value<String?> commentary = const Value.absent(),
  }) => KanjiTableData(
    id: id ?? this.id,
    character: character ?? this.character,
    meanings: meanings ?? this.meanings,
    readingsOn: readingsOn ?? this.readingsOn,
    readingsKun: readingsKun ?? this.readingsKun,
    koreanOnReadings: koreanOnReadings ?? this.koreanOnReadings,
    koreanKunReadings: koreanKunReadings ?? this.koreanKunReadings,
    grade: grade ?? this.grade,
    jlpt: jlpt ?? this.jlpt,
    strokeCount: strokeCount ?? this.strokeCount,
    examples: examples ?? this.examples,
    radical: radical.present ? radical.value : this.radical,
    commentary: commentary.present ? commentary.value : this.commentary,
  );
  KanjiTableData copyWithCompanion(KanjiTableCompanion data) {
    return KanjiTableData(
      id: data.id.present ? data.id.value : this.id,
      character: data.character.present ? data.character.value : this.character,
      meanings: data.meanings.present ? data.meanings.value : this.meanings,
      readingsOn: data.readingsOn.present
          ? data.readingsOn.value
          : this.readingsOn,
      readingsKun: data.readingsKun.present
          ? data.readingsKun.value
          : this.readingsKun,
      koreanOnReadings: data.koreanOnReadings.present
          ? data.koreanOnReadings.value
          : this.koreanOnReadings,
      koreanKunReadings: data.koreanKunReadings.present
          ? data.koreanKunReadings.value
          : this.koreanKunReadings,
      grade: data.grade.present ? data.grade.value : this.grade,
      jlpt: data.jlpt.present ? data.jlpt.value : this.jlpt,
      strokeCount: data.strokeCount.present
          ? data.strokeCount.value
          : this.strokeCount,
      examples: data.examples.present ? data.examples.value : this.examples,
      radical: data.radical.present ? data.radical.value : this.radical,
      commentary: data.commentary.present
          ? data.commentary.value
          : this.commentary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KanjiTableData(')
          ..write('id: $id, ')
          ..write('character: $character, ')
          ..write('meanings: $meanings, ')
          ..write('readingsOn: $readingsOn, ')
          ..write('readingsKun: $readingsKun, ')
          ..write('koreanOnReadings: $koreanOnReadings, ')
          ..write('koreanKunReadings: $koreanKunReadings, ')
          ..write('grade: $grade, ')
          ..write('jlpt: $jlpt, ')
          ..write('strokeCount: $strokeCount, ')
          ..write('examples: $examples, ')
          ..write('radical: $radical, ')
          ..write('commentary: $commentary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    character,
    meanings,
    readingsOn,
    readingsKun,
    koreanOnReadings,
    koreanKunReadings,
    grade,
    jlpt,
    strokeCount,
    examples,
    radical,
    commentary,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KanjiTableData &&
          other.id == this.id &&
          other.character == this.character &&
          other.meanings == this.meanings &&
          other.readingsOn == this.readingsOn &&
          other.readingsKun == this.readingsKun &&
          other.koreanOnReadings == this.koreanOnReadings &&
          other.koreanKunReadings == this.koreanKunReadings &&
          other.grade == this.grade &&
          other.jlpt == this.jlpt &&
          other.strokeCount == this.strokeCount &&
          other.examples == this.examples &&
          other.radical == this.radical &&
          other.commentary == this.commentary);
}

class KanjiTableCompanion extends UpdateCompanion<KanjiTableData> {
  final Value<int> id;
  final Value<String> character;
  final Value<List<String>> meanings;
  final Value<List<String>> readingsOn;
  final Value<List<String>> readingsKun;
  final Value<List<String>> koreanOnReadings;
  final Value<List<String>> koreanKunReadings;
  final Value<int> grade;
  final Value<int> jlpt;
  final Value<int> strokeCount;
  final Value<List<String>> examples;
  final Value<String?> radical;
  final Value<String?> commentary;
  const KanjiTableCompanion({
    this.id = const Value.absent(),
    this.character = const Value.absent(),
    this.meanings = const Value.absent(),
    this.readingsOn = const Value.absent(),
    this.readingsKun = const Value.absent(),
    this.koreanOnReadings = const Value.absent(),
    this.koreanKunReadings = const Value.absent(),
    this.grade = const Value.absent(),
    this.jlpt = const Value.absent(),
    this.strokeCount = const Value.absent(),
    this.examples = const Value.absent(),
    this.radical = const Value.absent(),
    this.commentary = const Value.absent(),
  });
  KanjiTableCompanion.insert({
    this.id = const Value.absent(),
    required String character,
    required List<String> meanings,
    required List<String> readingsOn,
    required List<String> readingsKun,
    required List<String> koreanOnReadings,
    required List<String> koreanKunReadings,
    required int grade,
    required int jlpt,
    required int strokeCount,
    this.examples = const Value.absent(),
    this.radical = const Value.absent(),
    this.commentary = const Value.absent(),
  }) : character = Value(character),
       meanings = Value(meanings),
       readingsOn = Value(readingsOn),
       readingsKun = Value(readingsKun),
       koreanOnReadings = Value(koreanOnReadings),
       koreanKunReadings = Value(koreanKunReadings),
       grade = Value(grade),
       jlpt = Value(jlpt),
       strokeCount = Value(strokeCount);
  static Insertable<KanjiTableData> custom({
    Expression<int>? id,
    Expression<String>? character,
    Expression<String>? meanings,
    Expression<String>? readingsOn,
    Expression<String>? readingsKun,
    Expression<String>? koreanOnReadings,
    Expression<String>? koreanKunReadings,
    Expression<int>? grade,
    Expression<int>? jlpt,
    Expression<int>? strokeCount,
    Expression<String>? examples,
    Expression<String>? radical,
    Expression<String>? commentary,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (character != null) 'character': character,
      if (meanings != null) 'meanings': meanings,
      if (readingsOn != null) 'readings_on': readingsOn,
      if (readingsKun != null) 'readings_kun': readingsKun,
      if (koreanOnReadings != null) 'korean_on_readings': koreanOnReadings,
      if (koreanKunReadings != null) 'korean_kun_readings': koreanKunReadings,
      if (grade != null) 'grade': grade,
      if (jlpt != null) 'jlpt': jlpt,
      if (strokeCount != null) 'stroke_count': strokeCount,
      if (examples != null) 'examples': examples,
      if (radical != null) 'radical': radical,
      if (commentary != null) 'commentary': commentary,
    });
  }

  KanjiTableCompanion copyWith({
    Value<int>? id,
    Value<String>? character,
    Value<List<String>>? meanings,
    Value<List<String>>? readingsOn,
    Value<List<String>>? readingsKun,
    Value<List<String>>? koreanOnReadings,
    Value<List<String>>? koreanKunReadings,
    Value<int>? grade,
    Value<int>? jlpt,
    Value<int>? strokeCount,
    Value<List<String>>? examples,
    Value<String?>? radical,
    Value<String?>? commentary,
  }) {
    return KanjiTableCompanion(
      id: id ?? this.id,
      character: character ?? this.character,
      meanings: meanings ?? this.meanings,
      readingsOn: readingsOn ?? this.readingsOn,
      readingsKun: readingsKun ?? this.readingsKun,
      koreanOnReadings: koreanOnReadings ?? this.koreanOnReadings,
      koreanKunReadings: koreanKunReadings ?? this.koreanKunReadings,
      grade: grade ?? this.grade,
      jlpt: jlpt ?? this.jlpt,
      strokeCount: strokeCount ?? this.strokeCount,
      examples: examples ?? this.examples,
      radical: radical ?? this.radical,
      commentary: commentary ?? this.commentary,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (character.present) {
      map['character'] = Variable<String>(character.value);
    }
    if (meanings.present) {
      map['meanings'] = Variable<String>(
        $KanjiTableTable.$convertermeanings.toSql(meanings.value),
      );
    }
    if (readingsOn.present) {
      map['readings_on'] = Variable<String>(
        $KanjiTableTable.$converterreadingsOn.toSql(readingsOn.value),
      );
    }
    if (readingsKun.present) {
      map['readings_kun'] = Variable<String>(
        $KanjiTableTable.$converterreadingsKun.toSql(readingsKun.value),
      );
    }
    if (koreanOnReadings.present) {
      map['korean_on_readings'] = Variable<String>(
        $KanjiTableTable.$converterkoreanOnReadings.toSql(
          koreanOnReadings.value,
        ),
      );
    }
    if (koreanKunReadings.present) {
      map['korean_kun_readings'] = Variable<String>(
        $KanjiTableTable.$converterkoreanKunReadings.toSql(
          koreanKunReadings.value,
        ),
      );
    }
    if (grade.present) {
      map['grade'] = Variable<int>(grade.value);
    }
    if (jlpt.present) {
      map['jlpt'] = Variable<int>(jlpt.value);
    }
    if (strokeCount.present) {
      map['stroke_count'] = Variable<int>(strokeCount.value);
    }
    if (examples.present) {
      map['examples'] = Variable<String>(
        $KanjiTableTable.$converterexamples.toSql(examples.value),
      );
    }
    if (radical.present) {
      map['radical'] = Variable<String>(radical.value);
    }
    if (commentary.present) {
      map['commentary'] = Variable<String>(commentary.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KanjiTableCompanion(')
          ..write('id: $id, ')
          ..write('character: $character, ')
          ..write('meanings: $meanings, ')
          ..write('readingsOn: $readingsOn, ')
          ..write('readingsKun: $readingsKun, ')
          ..write('koreanOnReadings: $koreanOnReadings, ')
          ..write('koreanKunReadings: $koreanKunReadings, ')
          ..write('grade: $grade, ')
          ..write('jlpt: $jlpt, ')
          ..write('strokeCount: $strokeCount, ')
          ..write('examples: $examples, ')
          ..write('radical: $radical, ')
          ..write('commentary: $commentary')
          ..write(')'))
        .toString();
  }
}

class $WordsTableTable extends WordsTable
    with TableInfo<$WordsTableTable, WordsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<String, String> meanings =
      GeneratedColumn<String>(
        'meanings',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<String>($WordsTableTable.$convertermeanings);
  static const VerificationMeta _jlptLevelMeta = const VerificationMeta(
    'jlptLevel',
  );
  @override
  late final GeneratedColumn<int> jlptLevel = GeneratedColumn<int>(
    'jlpt_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    word,
    reading,
    meanings,
    jlptLevel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('jlpt_level')) {
      context.handle(
        _jlptLevelMeta,
        jlptLevel.isAcceptableOrUnknown(data['jlpt_level']!, _jlptLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_jlptLevelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      meanings: $WordsTableTable.$convertermeanings.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meanings'],
        )!,
      ),
      jlptLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jlpt_level'],
      )!,
    );
  }

  @override
  $WordsTableTable createAlias(String alias) {
    return $WordsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<String, String> $convertermeanings =
      const JsonStringConverter();
}

class WordsTableData extends DataClass implements Insertable<WordsTableData> {
  final int id;
  final String word;
  final String reading;
  final String meanings;
  final int jlptLevel;
  const WordsTableData({
    required this.id,
    required this.word,
    required this.reading,
    required this.meanings,
    required this.jlptLevel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['reading'] = Variable<String>(reading);
    {
      map['meanings'] = Variable<String>(
        $WordsTableTable.$convertermeanings.toSql(meanings),
      );
    }
    map['jlpt_level'] = Variable<int>(jlptLevel);
    return map;
  }

  WordsTableCompanion toCompanion(bool nullToAbsent) {
    return WordsTableCompanion(
      id: Value(id),
      word: Value(word),
      reading: Value(reading),
      meanings: Value(meanings),
      jlptLevel: Value(jlptLevel),
    );
  }

  factory WordsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordsTableData(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      reading: serializer.fromJson<String>(json['reading']),
      meanings: serializer.fromJson<String>(json['meanings']),
      jlptLevel: serializer.fromJson<int>(json['jlptLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'reading': serializer.toJson<String>(reading),
      'meanings': serializer.toJson<String>(meanings),
      'jlptLevel': serializer.toJson<int>(jlptLevel),
    };
  }

  WordsTableData copyWith({
    int? id,
    String? word,
    String? reading,
    String? meanings,
    int? jlptLevel,
  }) => WordsTableData(
    id: id ?? this.id,
    word: word ?? this.word,
    reading: reading ?? this.reading,
    meanings: meanings ?? this.meanings,
    jlptLevel: jlptLevel ?? this.jlptLevel,
  );
  WordsTableData copyWithCompanion(WordsTableCompanion data) {
    return WordsTableData(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      reading: data.reading.present ? data.reading.value : this.reading,
      meanings: data.meanings.present ? data.meanings.value : this.meanings,
      jlptLevel: data.jlptLevel.present ? data.jlptLevel.value : this.jlptLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordsTableData(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('reading: $reading, ')
          ..write('meanings: $meanings, ')
          ..write('jlptLevel: $jlptLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, word, reading, meanings, jlptLevel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordsTableData &&
          other.id == this.id &&
          other.word == this.word &&
          other.reading == this.reading &&
          other.meanings == this.meanings &&
          other.jlptLevel == this.jlptLevel);
}

class WordsTableCompanion extends UpdateCompanion<WordsTableData> {
  final Value<int> id;
  final Value<String> word;
  final Value<String> reading;
  final Value<String> meanings;
  final Value<int> jlptLevel;
  const WordsTableCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.reading = const Value.absent(),
    this.meanings = const Value.absent(),
    this.jlptLevel = const Value.absent(),
  });
  WordsTableCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    required String reading,
    required String meanings,
    required int jlptLevel,
  }) : word = Value(word),
       reading = Value(reading),
       meanings = Value(meanings),
       jlptLevel = Value(jlptLevel);
  static Insertable<WordsTableData> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? reading,
    Expression<String>? meanings,
    Expression<int>? jlptLevel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (reading != null) 'reading': reading,
      if (meanings != null) 'meanings': meanings,
      if (jlptLevel != null) 'jlpt_level': jlptLevel,
    });
  }

  WordsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? word,
    Value<String>? reading,
    Value<String>? meanings,
    Value<int>? jlptLevel,
  }) {
    return WordsTableCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      reading: reading ?? this.reading,
      meanings: meanings ?? this.meanings,
      jlptLevel: jlptLevel ?? this.jlptLevel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (meanings.present) {
      map['meanings'] = Variable<String>(
        $WordsTableTable.$convertermeanings.toSql(meanings.value),
      );
    }
    if (jlptLevel.present) {
      map['jlpt_level'] = Variable<int>(jlptLevel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsTableCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('reading: $reading, ')
          ..write('meanings: $meanings, ')
          ..write('jlptLevel: $jlptLevel')
          ..write(')'))
        .toString();
  }
}

class $StudyRecordsTableTable extends StudyRecordsTable
    with TableInfo<$StudyRecordsTableTable, StudyRecordsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyRecordsTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studyTypeMeta = const VerificationMeta(
    'studyType',
  );
  @override
  late final GeneratedColumn<String> studyType = GeneratedColumn<String>(
    'study_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<int> targetId = GeneratedColumn<int>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studyDateMeta = const VerificationMeta(
    'studyDate',
  );
  @override
  late final GeneratedColumn<DateTime> studyDate = GeneratedColumn<DateTime>(
    'study_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    studyType,
    targetId,
    status,
    studyDate,
    notes,
    isSynced,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_records_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyRecordsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('study_type')) {
      context.handle(
        _studyTypeMeta,
        studyType.isAcceptableOrUnknown(data['study_type']!, _studyTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_studyTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('study_date')) {
      context.handle(
        _studyDateMeta,
        studyDate.isAcceptableOrUnknown(data['study_date']!, _studyDateMeta),
      );
    } else if (isInserting) {
      context.missing(_studyDateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudyRecordsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyRecordsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      studyType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}study_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      studyDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}study_date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StudyRecordsTableTable createAlias(String alias) {
    return $StudyRecordsTableTable(attachedDatabase, alias);
  }
}

class StudyRecordsTableData extends DataClass
    implements Insertable<StudyRecordsTableData> {
  final int id;
  final String userId;
  final String studyType;
  final int targetId;
  final String status;
  final DateTime studyDate;
  final String? notes;
  final bool isSynced;
  final DateTime createdAt;
  const StudyRecordsTableData({
    required this.id,
    required this.userId,
    required this.studyType,
    required this.targetId,
    required this.status,
    required this.studyDate,
    this.notes,
    required this.isSynced,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['study_type'] = Variable<String>(studyType);
    map['target_id'] = Variable<int>(targetId);
    map['status'] = Variable<String>(status);
    map['study_date'] = Variable<DateTime>(studyDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StudyRecordsTableCompanion toCompanion(bool nullToAbsent) {
    return StudyRecordsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      studyType: Value(studyType),
      targetId: Value(targetId),
      status: Value(status),
      studyDate: Value(studyDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
    );
  }

  factory StudyRecordsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyRecordsTableData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      studyType: serializer.fromJson<String>(json['studyType']),
      targetId: serializer.fromJson<int>(json['targetId']),
      status: serializer.fromJson<String>(json['status']),
      studyDate: serializer.fromJson<DateTime>(json['studyDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'studyType': serializer.toJson<String>(studyType),
      'targetId': serializer.toJson<int>(targetId),
      'status': serializer.toJson<String>(status),
      'studyDate': serializer.toJson<DateTime>(studyDate),
      'notes': serializer.toJson<String?>(notes),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StudyRecordsTableData copyWith({
    int? id,
    String? userId,
    String? studyType,
    int? targetId,
    String? status,
    DateTime? studyDate,
    Value<String?> notes = const Value.absent(),
    bool? isSynced,
    DateTime? createdAt,
  }) => StudyRecordsTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    studyType: studyType ?? this.studyType,
    targetId: targetId ?? this.targetId,
    status: status ?? this.status,
    studyDate: studyDate ?? this.studyDate,
    notes: notes.present ? notes.value : this.notes,
    isSynced: isSynced ?? this.isSynced,
    createdAt: createdAt ?? this.createdAt,
  );
  StudyRecordsTableData copyWithCompanion(StudyRecordsTableCompanion data) {
    return StudyRecordsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      studyType: data.studyType.present ? data.studyType.value : this.studyType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      status: data.status.present ? data.status.value : this.status,
      studyDate: data.studyDate.present ? data.studyDate.value : this.studyDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyRecordsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('studyType: $studyType, ')
          ..write('targetId: $targetId, ')
          ..write('status: $status, ')
          ..write('studyDate: $studyDate, ')
          ..write('notes: $notes, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    studyType,
    targetId,
    status,
    studyDate,
    notes,
    isSynced,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyRecordsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.studyType == this.studyType &&
          other.targetId == this.targetId &&
          other.status == this.status &&
          other.studyDate == this.studyDate &&
          other.notes == this.notes &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt);
}

class StudyRecordsTableCompanion
    extends UpdateCompanion<StudyRecordsTableData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> studyType;
  final Value<int> targetId;
  final Value<String> status;
  final Value<DateTime> studyDate;
  final Value<String?> notes;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  const StudyRecordsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.studyType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.status = const Value.absent(),
    this.studyDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StudyRecordsTableCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String studyType,
    required int targetId,
    required String status,
    required DateTime studyDate,
    this.notes = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : userId = Value(userId),
       studyType = Value(studyType),
       targetId = Value(targetId),
       status = Value(status),
       studyDate = Value(studyDate);
  static Insertable<StudyRecordsTableData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? studyType,
    Expression<int>? targetId,
    Expression<String>? status,
    Expression<DateTime>? studyDate,
    Expression<String>? notes,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (studyType != null) 'study_type': studyType,
      if (targetId != null) 'target_id': targetId,
      if (status != null) 'status': status,
      if (studyDate != null) 'study_date': studyDate,
      if (notes != null) 'notes': notes,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StudyRecordsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? studyType,
    Value<int>? targetId,
    Value<String>? status,
    Value<DateTime>? studyDate,
    Value<String?>? notes,
    Value<bool>? isSynced,
    Value<DateTime>? createdAt,
  }) {
    return StudyRecordsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      studyType: studyType ?? this.studyType,
      targetId: targetId ?? this.targetId,
      status: status ?? this.status,
      studyDate: studyDate ?? this.studyDate,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (studyType.present) {
      map['study_type'] = Variable<String>(studyType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<int>(targetId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (studyDate.present) {
      map['study_date'] = Variable<DateTime>(studyDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyRecordsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('studyType: $studyType, ')
          ..write('targetId: $targetId, ')
          ..write('status: $status, ')
          ..write('studyDate: $studyDate, ')
          ..write('notes: $notes, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operation,
    targetTable,
    data,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final int id;
  final String operation;
  final String targetTable;
  final String data;
  final DateTime createdAt;
  const SyncQueueTableData({
    required this.id,
    required this.operation,
    required this.targetTable,
    required this.data,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation'] = Variable<String>(operation);
    map['target_table'] = Variable<String>(targetTable);
    map['data'] = Variable<String>(data);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      operation: Value(operation),
      targetTable: Value(targetTable),
      data: Value(data),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      operation: serializer.fromJson<String>(json['operation']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      data: serializer.fromJson<String>(json['data']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operation': serializer.toJson<String>(operation),
      'targetTable': serializer.toJson<String>(targetTable),
      'data': serializer.toJson<String>(data),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueTableData copyWith({
    int? id,
    String? operation,
    String? targetTable,
    String? data,
    DateTime? createdAt,
  }) => SyncQueueTableData(
    id: id ?? this.id,
    operation: operation ?? this.operation,
    targetTable: targetTable ?? this.targetTable,
    data: data ?? this.data,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      operation: data.operation.present ? data.operation.value : this.operation,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      data: data.data.present ? data.data.value : this.data,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('targetTable: $targetTable, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, operation, targetTable, data, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.operation == this.operation &&
          other.targetTable == this.targetTable &&
          other.data == this.data &&
          other.createdAt == this.createdAt);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<int> id;
  final Value<String> operation;
  final Value<String> targetTable;
  final Value<String> data;
  final Value<DateTime> createdAt;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.operation = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.data = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String operation,
    required String targetTable,
    required String data,
    this.createdAt = const Value.absent(),
  }) : operation = Value(operation),
       targetTable = Value(targetTable),
       data = Value(data);
  static Insertable<SyncQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? operation,
    Expression<String>? targetTable,
    Expression<String>? data,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operation != null) 'operation': operation,
      if (targetTable != null) 'target_table': targetTable,
      if (data != null) 'data': data,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueTableCompanion copyWith({
    Value<int>? id,
    Value<String>? operation,
    Value<String>? targetTable,
    Value<String>? data,
    Value<DateTime>? createdAt,
  }) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      targetTable: targetTable ?? this.targetTable,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('targetTable: $targetTable, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTableTable extends FavoritesTable
    with TableInfo<$FavoritesTableTable, FavoritesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<int> targetId = GeneratedColumn<int>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    type,
    targetId,
    note,
    isSynced,
    isDeleted,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoritesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FavoritesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoritesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoritesTableTable createAlias(String alias) {
    return $FavoritesTableTable(attachedDatabase, alias);
  }
}

class FavoritesTableData extends DataClass
    implements Insertable<FavoritesTableData> {
  final int id;
  final String userId;
  final String type;
  final int targetId;
  final String? note;
  final bool isSynced;
  final bool isDeleted;
  final DateTime createdAt;
  const FavoritesTableData({
    required this.id,
    required this.userId,
    required this.type,
    required this.targetId,
    this.note,
    required this.isSynced,
    required this.isDeleted,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['type'] = Variable<String>(type);
    map['target_id'] = Variable<int>(targetId);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoritesTableCompanion toCompanion(bool nullToAbsent) {
    return FavoritesTableCompanion(
      id: Value(id),
      userId: Value(userId),
      type: Value(type),
      targetId: Value(targetId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
    );
  }

  factory FavoritesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoritesTableData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      targetId: serializer.fromJson<int>(json['targetId']),
      note: serializer.fromJson<String?>(json['note']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'type': serializer.toJson<String>(type),
      'targetId': serializer.toJson<int>(targetId),
      'note': serializer.toJson<String?>(note),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FavoritesTableData copyWith({
    int? id,
    String? userId,
    String? type,
    int? targetId,
    Value<String?> note = const Value.absent(),
    bool? isSynced,
    bool? isDeleted,
    DateTime? createdAt,
  }) => FavoritesTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    targetId: targetId ?? this.targetId,
    note: note.present ? note.value : this.note,
    isSynced: isSynced ?? this.isSynced,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
  );
  FavoritesTableData copyWithCompanion(FavoritesTableCompanion data) {
    return FavoritesTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      note: data.note.present ? data.note.value : this.note,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('targetId: $targetId, ')
          ..write('note: $note, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    type,
    targetId,
    note,
    isSynced,
    isDeleted,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoritesTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.targetId == this.targetId &&
          other.note == this.note &&
          other.isSynced == this.isSynced &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt);
}

class FavoritesTableCompanion extends UpdateCompanion<FavoritesTableData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> type;
  final Value<int> targetId;
  final Value<String?> note;
  final Value<bool> isSynced;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  const FavoritesTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.targetId = const Value.absent(),
    this.note = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FavoritesTableCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String type,
    required int targetId,
    this.note = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : userId = Value(userId),
       type = Value(type),
       targetId = Value(targetId);
  static Insertable<FavoritesTableData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<int>? targetId,
    Expression<String>? note,
    Expression<bool>? isSynced,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (targetId != null) 'target_id': targetId,
      if (note != null) 'note': note,
      if (isSynced != null) 'is_synced': isSynced,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FavoritesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? type,
    Value<int>? targetId,
    Value<String?>? note,
    Value<bool>? isSynced,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
  }) {
    return FavoritesTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      note: note ?? this.note,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<int>(targetId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('targetId: $targetId, ')
          ..write('note: $note, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KanjiTableTable kanjiTable = $KanjiTableTable(this);
  late final $WordsTableTable wordsTable = $WordsTableTable(this);
  late final $StudyRecordsTableTable studyRecordsTable =
      $StudyRecordsTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  late final $FavoritesTableTable favoritesTable = $FavoritesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    kanjiTable,
    wordsTable,
    studyRecordsTable,
    syncQueueTable,
    favoritesTable,
  ];
}

typedef $$KanjiTableTableCreateCompanionBuilder =
    KanjiTableCompanion Function({
      Value<int> id,
      required String character,
      required List<String> meanings,
      required List<String> readingsOn,
      required List<String> readingsKun,
      required List<String> koreanOnReadings,
      required List<String> koreanKunReadings,
      required int grade,
      required int jlpt,
      required int strokeCount,
      Value<List<String>> examples,
      Value<String?> radical,
      Value<String?> commentary,
    });
typedef $$KanjiTableTableUpdateCompanionBuilder =
    KanjiTableCompanion Function({
      Value<int> id,
      Value<String> character,
      Value<List<String>> meanings,
      Value<List<String>> readingsOn,
      Value<List<String>> readingsKun,
      Value<List<String>> koreanOnReadings,
      Value<List<String>> koreanKunReadings,
      Value<int> grade,
      Value<int> jlpt,
      Value<int> strokeCount,
      Value<List<String>> examples,
      Value<String?> radical,
      Value<String?> commentary,
    });

class $$KanjiTableTableFilterComposer
    extends Composer<_$AppDatabase, $KanjiTableTable> {
  $$KanjiTableTableFilterComposer({
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

  ColumnFilters<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get meanings => $composableBuilder(
    column: $table.meanings,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get readingsOn => $composableBuilder(
    column: $table.readingsOn,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get readingsKun => $composableBuilder(
    column: $table.readingsKun,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get koreanOnReadings => $composableBuilder(
    column: $table.koreanOnReadings,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get koreanKunReadings => $composableBuilder(
    column: $table.koreanKunReadings,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jlpt => $composableBuilder(
    column: $table.jlpt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get examples => $composableBuilder(
    column: $table.examples,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get radical => $composableBuilder(
    column: $table.radical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commentary => $composableBuilder(
    column: $table.commentary,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KanjiTableTableOrderingComposer
    extends Composer<_$AppDatabase, $KanjiTableTable> {
  $$KanjiTableTableOrderingComposer({
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

  ColumnOrderings<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meanings => $composableBuilder(
    column: $table.meanings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readingsOn => $composableBuilder(
    column: $table.readingsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readingsKun => $composableBuilder(
    column: $table.readingsKun,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get koreanOnReadings => $composableBuilder(
    column: $table.koreanOnReadings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get koreanKunReadings => $composableBuilder(
    column: $table.koreanKunReadings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jlpt => $composableBuilder(
    column: $table.jlpt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get examples => $composableBuilder(
    column: $table.examples,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get radical => $composableBuilder(
    column: $table.radical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commentary => $composableBuilder(
    column: $table.commentary,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KanjiTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $KanjiTableTable> {
  $$KanjiTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get character =>
      $composableBuilder(column: $table.character, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get meanings =>
      $composableBuilder(column: $table.meanings, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get readingsOn =>
      $composableBuilder(
        column: $table.readingsOn,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<List<String>, String> get readingsKun =>
      $composableBuilder(
        column: $table.readingsKun,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<List<String>, String> get koreanOnReadings =>
      $composableBuilder(
        column: $table.koreanOnReadings,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<List<String>, String>
  get koreanKunReadings => $composableBuilder(
    column: $table.koreanKunReadings,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<int> get jlpt =>
      $composableBuilder(column: $table.jlpt, builder: (column) => column);

  GeneratedColumn<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get examples =>
      $composableBuilder(column: $table.examples, builder: (column) => column);

  GeneratedColumn<String> get radical =>
      $composableBuilder(column: $table.radical, builder: (column) => column);

  GeneratedColumn<String> get commentary => $composableBuilder(
    column: $table.commentary,
    builder: (column) => column,
  );
}

class $$KanjiTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KanjiTableTable,
          KanjiTableData,
          $$KanjiTableTableFilterComposer,
          $$KanjiTableTableOrderingComposer,
          $$KanjiTableTableAnnotationComposer,
          $$KanjiTableTableCreateCompanionBuilder,
          $$KanjiTableTableUpdateCompanionBuilder,
          (
            KanjiTableData,
            BaseReferences<_$AppDatabase, $KanjiTableTable, KanjiTableData>,
          ),
          KanjiTableData,
          PrefetchHooks Function()
        > {
  $$KanjiTableTableTableManager(_$AppDatabase db, $KanjiTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KanjiTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KanjiTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KanjiTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> character = const Value.absent(),
                Value<List<String>> meanings = const Value.absent(),
                Value<List<String>> readingsOn = const Value.absent(),
                Value<List<String>> readingsKun = const Value.absent(),
                Value<List<String>> koreanOnReadings = const Value.absent(),
                Value<List<String>> koreanKunReadings = const Value.absent(),
                Value<int> grade = const Value.absent(),
                Value<int> jlpt = const Value.absent(),
                Value<int> strokeCount = const Value.absent(),
                Value<List<String>> examples = const Value.absent(),
                Value<String?> radical = const Value.absent(),
                Value<String?> commentary = const Value.absent(),
              }) => KanjiTableCompanion(
                id: id,
                character: character,
                meanings: meanings,
                readingsOn: readingsOn,
                readingsKun: readingsKun,
                koreanOnReadings: koreanOnReadings,
                koreanKunReadings: koreanKunReadings,
                grade: grade,
                jlpt: jlpt,
                strokeCount: strokeCount,
                examples: examples,
                radical: radical,
                commentary: commentary,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String character,
                required List<String> meanings,
                required List<String> readingsOn,
                required List<String> readingsKun,
                required List<String> koreanOnReadings,
                required List<String> koreanKunReadings,
                required int grade,
                required int jlpt,
                required int strokeCount,
                Value<List<String>> examples = const Value.absent(),
                Value<String?> radical = const Value.absent(),
                Value<String?> commentary = const Value.absent(),
              }) => KanjiTableCompanion.insert(
                id: id,
                character: character,
                meanings: meanings,
                readingsOn: readingsOn,
                readingsKun: readingsKun,
                koreanOnReadings: koreanOnReadings,
                koreanKunReadings: koreanKunReadings,
                grade: grade,
                jlpt: jlpt,
                strokeCount: strokeCount,
                examples: examples,
                radical: radical,
                commentary: commentary,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KanjiTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KanjiTableTable,
      KanjiTableData,
      $$KanjiTableTableFilterComposer,
      $$KanjiTableTableOrderingComposer,
      $$KanjiTableTableAnnotationComposer,
      $$KanjiTableTableCreateCompanionBuilder,
      $$KanjiTableTableUpdateCompanionBuilder,
      (
        KanjiTableData,
        BaseReferences<_$AppDatabase, $KanjiTableTable, KanjiTableData>,
      ),
      KanjiTableData,
      PrefetchHooks Function()
    >;
typedef $$WordsTableTableCreateCompanionBuilder =
    WordsTableCompanion Function({
      Value<int> id,
      required String word,
      required String reading,
      required String meanings,
      required int jlptLevel,
    });
typedef $$WordsTableTableUpdateCompanionBuilder =
    WordsTableCompanion Function({
      Value<int> id,
      Value<String> word,
      Value<String> reading,
      Value<String> meanings,
      Value<int> jlptLevel,
    });

class $$WordsTableTableFilterComposer
    extends Composer<_$AppDatabase, $WordsTableTable> {
  $$WordsTableTableFilterComposer({
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

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<String, String, String> get meanings =>
      $composableBuilder(
        column: $table.meanings,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get jlptLevel => $composableBuilder(
    column: $table.jlptLevel,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTableTable> {
  $$WordsTableTableOrderingComposer({
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

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meanings => $composableBuilder(
    column: $table.meanings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jlptLevel => $composableBuilder(
    column: $table.jlptLevel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTableTable> {
  $$WordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumnWithTypeConverter<String, String> get meanings =>
      $composableBuilder(column: $table.meanings, builder: (column) => column);

  GeneratedColumn<int> get jlptLevel =>
      $composableBuilder(column: $table.jlptLevel, builder: (column) => column);
}

class $$WordsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTableTable,
          WordsTableData,
          $$WordsTableTableFilterComposer,
          $$WordsTableTableOrderingComposer,
          $$WordsTableTableAnnotationComposer,
          $$WordsTableTableCreateCompanionBuilder,
          $$WordsTableTableUpdateCompanionBuilder,
          (
            WordsTableData,
            BaseReferences<_$AppDatabase, $WordsTableTable, WordsTableData>,
          ),
          WordsTableData,
          PrefetchHooks Function()
        > {
  $$WordsTableTableTableManager(_$AppDatabase db, $WordsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String> meanings = const Value.absent(),
                Value<int> jlptLevel = const Value.absent(),
              }) => WordsTableCompanion(
                id: id,
                word: word,
                reading: reading,
                meanings: meanings,
                jlptLevel: jlptLevel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String word,
                required String reading,
                required String meanings,
                required int jlptLevel,
              }) => WordsTableCompanion.insert(
                id: id,
                word: word,
                reading: reading,
                meanings: meanings,
                jlptLevel: jlptLevel,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTableTable,
      WordsTableData,
      $$WordsTableTableFilterComposer,
      $$WordsTableTableOrderingComposer,
      $$WordsTableTableAnnotationComposer,
      $$WordsTableTableCreateCompanionBuilder,
      $$WordsTableTableUpdateCompanionBuilder,
      (
        WordsTableData,
        BaseReferences<_$AppDatabase, $WordsTableTable, WordsTableData>,
      ),
      WordsTableData,
      PrefetchHooks Function()
    >;
typedef $$StudyRecordsTableTableCreateCompanionBuilder =
    StudyRecordsTableCompanion Function({
      Value<int> id,
      required String userId,
      required String studyType,
      required int targetId,
      required String status,
      required DateTime studyDate,
      Value<String?> notes,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
    });
typedef $$StudyRecordsTableTableUpdateCompanionBuilder =
    StudyRecordsTableCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> studyType,
      Value<int> targetId,
      Value<String> status,
      Value<DateTime> studyDate,
      Value<String?> notes,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
    });

class $$StudyRecordsTableTableFilterComposer
    extends Composer<_$AppDatabase, $StudyRecordsTableTable> {
  $$StudyRecordsTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studyType => $composableBuilder(
    column: $table.studyType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get studyDate => $composableBuilder(
    column: $table.studyDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudyRecordsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StudyRecordsTableTable> {
  $$StudyRecordsTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studyType => $composableBuilder(
    column: $table.studyType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get studyDate => $composableBuilder(
    column: $table.studyDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudyRecordsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudyRecordsTableTable> {
  $$StudyRecordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get studyType =>
      $composableBuilder(column: $table.studyType, builder: (column) => column);

  GeneratedColumn<int> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get studyDate =>
      $composableBuilder(column: $table.studyDate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StudyRecordsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudyRecordsTableTable,
          StudyRecordsTableData,
          $$StudyRecordsTableTableFilterComposer,
          $$StudyRecordsTableTableOrderingComposer,
          $$StudyRecordsTableTableAnnotationComposer,
          $$StudyRecordsTableTableCreateCompanionBuilder,
          $$StudyRecordsTableTableUpdateCompanionBuilder,
          (
            StudyRecordsTableData,
            BaseReferences<
              _$AppDatabase,
              $StudyRecordsTableTable,
              StudyRecordsTableData
            >,
          ),
          StudyRecordsTableData,
          PrefetchHooks Function()
        > {
  $$StudyRecordsTableTableTableManager(
    _$AppDatabase db,
    $StudyRecordsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudyRecordsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudyRecordsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudyRecordsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> studyType = const Value.absent(),
                Value<int> targetId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> studyDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StudyRecordsTableCompanion(
                id: id,
                userId: userId,
                studyType: studyType,
                targetId: targetId,
                status: status,
                studyDate: studyDate,
                notes: notes,
                isSynced: isSynced,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String studyType,
                required int targetId,
                required String status,
                required DateTime studyDate,
                Value<String?> notes = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StudyRecordsTableCompanion.insert(
                id: id,
                userId: userId,
                studyType: studyType,
                targetId: targetId,
                status: status,
                studyDate: studyDate,
                notes: notes,
                isSynced: isSynced,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudyRecordsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudyRecordsTableTable,
      StudyRecordsTableData,
      $$StudyRecordsTableTableFilterComposer,
      $$StudyRecordsTableTableOrderingComposer,
      $$StudyRecordsTableTableAnnotationComposer,
      $$StudyRecordsTableTableCreateCompanionBuilder,
      $$StudyRecordsTableTableUpdateCompanionBuilder,
      (
        StudyRecordsTableData,
        BaseReferences<
          _$AppDatabase,
          $StudyRecordsTableTable,
          StudyRecordsTableData
        >,
      ),
      StudyRecordsTableData,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableTableCreateCompanionBuilder =
    SyncQueueTableCompanion Function({
      Value<int> id,
      required String operation,
      required String targetTable,
      required String data,
      Value<DateTime> createdAt,
    });
typedef $$SyncQueueTableTableUpdateCompanionBuilder =
    SyncQueueTableCompanion Function({
      Value<int> id,
      Value<String> operation,
      Value<String> targetTable,
      Value<String> data,
      Value<DateTime> createdAt,
    });

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
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

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
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

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTableTable,
          SyncQueueTableData,
          $$SyncQueueTableTableFilterComposer,
          $$SyncQueueTableTableOrderingComposer,
          $$SyncQueueTableTableAnnotationComposer,
          $$SyncQueueTableTableCreateCompanionBuilder,
          $$SyncQueueTableTableUpdateCompanionBuilder,
          (
            SyncQueueTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncQueueTableTable,
              SyncQueueTableData
            >,
          ),
          SyncQueueTableData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableTableManager(
    _$AppDatabase db,
    $SyncQueueTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueTableCompanion(
                id: id,
                operation: operation,
                targetTable: targetTable,
                data: data,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String operation,
                required String targetTable,
                required String data,
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueTableCompanion.insert(
                id: id,
                operation: operation,
                targetTable: targetTable,
                data: data,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTableTable,
      SyncQueueTableData,
      $$SyncQueueTableTableFilterComposer,
      $$SyncQueueTableTableOrderingComposer,
      $$SyncQueueTableTableAnnotationComposer,
      $$SyncQueueTableTableCreateCompanionBuilder,
      $$SyncQueueTableTableUpdateCompanionBuilder,
      (
        SyncQueueTableData,
        BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>,
      ),
      SyncQueueTableData,
      PrefetchHooks Function()
    >;
typedef $$FavoritesTableTableCreateCompanionBuilder =
    FavoritesTableCompanion Function({
      Value<int> id,
      required String userId,
      required String type,
      required int targetId,
      Value<String?> note,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
    });
typedef $$FavoritesTableTableUpdateCompanionBuilder =
    FavoritesTableCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> type,
      Value<int> targetId,
      Value<String?> note,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
    });

class $$FavoritesTableTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTableTable> {
  $$FavoritesTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTableTable> {
  $$FavoritesTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTableTable> {
  $$FavoritesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FavoritesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTableTable,
          FavoritesTableData,
          $$FavoritesTableTableFilterComposer,
          $$FavoritesTableTableOrderingComposer,
          $$FavoritesTableTableAnnotationComposer,
          $$FavoritesTableTableCreateCompanionBuilder,
          $$FavoritesTableTableUpdateCompanionBuilder,
          (
            FavoritesTableData,
            BaseReferences<
              _$AppDatabase,
              $FavoritesTableTable,
              FavoritesTableData
            >,
          ),
          FavoritesTableData,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableTableManager(
    _$AppDatabase db,
    $FavoritesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> targetId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoritesTableCompanion(
                id: id,
                userId: userId,
                type: type,
                targetId: targetId,
                note: note,
                isSynced: isSynced,
                isDeleted: isDeleted,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String type,
                required int targetId,
                Value<String?> note = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoritesTableCompanion.insert(
                id: id,
                userId: userId,
                type: type,
                targetId: targetId,
                note: note,
                isSynced: isSynced,
                isDeleted: isDeleted,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoritesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTableTable,
      FavoritesTableData,
      $$FavoritesTableTableFilterComposer,
      $$FavoritesTableTableOrderingComposer,
      $$FavoritesTableTableAnnotationComposer,
      $$FavoritesTableTableCreateCompanionBuilder,
      $$FavoritesTableTableUpdateCompanionBuilder,
      (
        FavoritesTableData,
        BaseReferences<_$AppDatabase, $FavoritesTableTable, FavoritesTableData>,
      ),
      FavoritesTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KanjiTableTableTableManager get kanjiTable =>
      $$KanjiTableTableTableManager(_db, _db.kanjiTable);
  $$WordsTableTableTableManager get wordsTable =>
      $$WordsTableTableTableManager(_db, _db.wordsTable);
  $$StudyRecordsTableTableTableManager get studyRecordsTable =>
      $$StudyRecordsTableTableTableManager(_db, _db.studyRecordsTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
  $$FavoritesTableTableTableManager get favoritesTable =>
      $$FavoritesTableTableTableManager(_db, _db.favoritesTable);
}
