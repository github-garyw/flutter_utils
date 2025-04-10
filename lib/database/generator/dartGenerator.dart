import 'dart:io';

import 'package:flutter_utils/database/generator/providerGenerator.dart';
import 'package:flutter_utils/fileUtils.dart';

import './generatorUtils.dart';
import 'schema.dart';

const String GEOGRAPHY_POINT = 'GEOGRAPHY(POINT)';

const Map<String, String> typeMap = {
  'SERIAL': 'int',
  'BIGSERIAL': 'int',
  'INTEGER': 'int?',
  'TEXT': 'String?',
  'JSONB': 'Map<String, dynamic>?',
  'UUID': 'String',
  'BOOLEAN': 'bool',
  'NUMERIC': 'double?',
  'TIMESTAMPTZ': 'DateTime?',
  'INTEGER[]': 'List<int>?',
  'TEXT[]': 'List<String>?',
  'UUID[]': 'List<String>?',
  GEOGRAPHY_POINT: 'SupabaseGeolocation?',
};

class DartGenerator {
  static String _mapColumnTypeToDart(String columnType) {
    final ret = typeMap[columnType.toUpperCase()];
    if (ret == null) {
      print('Cannot map column type $columnType to dart data type');
      exit(1);
    }
    return ret;
  }

  static Future<void> createDartFile(Schema schema) async {
    var classContent = _getImport(schema);
    classContent += END_OF_LINE;
    classContent += END_OF_LINE;

    classContent += 'class ${schema.metaData[CLASS_NAME]} {$END_OF_LINE';
    classContent += END_OF_LINE;
    classContent += "${TAB}static const String TABLE_NAME = '${schema.metaData[TABLE_NAME]}';$END_OF_LINE";
    classContent += END_OF_LINE;

    classContent += _getMemberVariables(schema.fields);
    classContent += END_OF_LINE;

    classContent += _getConstructor(schema);
    classContent += END_OF_LINE;

    classContent += _getCopyConstructor(schema);
    classContent += END_OF_LINE;

    classContent += _getReset(schema);
    classContent += END_OF_LINE;

    classContent += _getToMap(schema);
    classContent += END_OF_LINE;

    classContent += _getFactoryFromJson(schema);
    classContent += END_OF_LINE;

    classContent += _getToString(schema);
    classContent += END_OF_LINE;

    classContent += _getQueryById(schema);
    classContent += END_OF_LINE;

    classContent += _getRange(schema);
    classContent += END_OF_LINE;

    classContent += _getInsert(schema);
    classContent += END_OF_LINE;

    classContent += _getUpdate(schema);
    classContent += END_OF_LINE;

    classContent += _getDelete(schema);
    classContent += END_OF_LINE;

    classContent += _getEqualAndHashCodeFunctions(schema);
    classContent += END_OF_LINE;

    classContent += END_OF_LINE;
    classContent += '}$END_OF_LINE';

    final targetPath = '${Directory.current.path}/lib/autoGenerated' +
        (schema.metaData[PACKAGE_PATH] ?? '');
    await FileUtils.writeToFile(
        targetPath, schema.metaData[DART_FILE_NAME]!, classContent);
    // print(classContent);

    ProviderGenerator.createProviderFile(schema);

  }

  static String _getEqualAndHashCodeFunctions(Schema schema) {
    return '''
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ${schema.metaData[CLASS_NAME]} && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
    ''';
  }

  static String _getImport(Schema schema) {
    var ret = '';
    ret = "import 'package:flutter/material.dart';$END_OF_LINE";
    ret =
        "import 'package:supabase_flutter/supabase_flutter.dart';$END_OF_LINE";
    ret += "import 'package:flutter_utils/triple.dart';$END_OF_LINE";
    ret += "import 'package:flutter_utils/appUtils.dart';$END_OF_LINE";

    final typeSet = schema.fields.map((e) => e[TYPE]).cast<String>().toSet();
    if (typeSet.contains(GEOGRAPHY_POINT)) {
      ret += "import 'package:flutter_utils/database/supabase/models/supabaseGeolocation.dart';$END_OF_LINE";
    }

    return ret;
  }

  static String _getRange(Schema schema) {
    final className = schema.metaData[CLASS_NAME]!;
    var ret = '';

    ret += '${TAB}static Future<Triple<bool, List<$className>?, String>> range({int start = 0, int numberOfRecords = 10}) async {$END_OF_LINE';
    ret += '$TAB${TAB}final supabase = Supabase.instance.client;$END_OF_LINE';

    ret += '$TAB${TAB}try {$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}List<dynamic>? data;$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}if (numberOfRecords > 0) {$END_OF_LINE';
    ret +=
    '$TAB${TAB}${TAB}${TAB}data = await supabase.from(\'${schema.metaData[TABLE_NAME]}\')$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}${TAB}.select()$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}${TAB}.range(start, numberOfRecords);$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}} else {$END_OF_LINE';
    ret +=
    '$TAB${TAB}${TAB}${TAB}data = await supabase.from(\'${schema.metaData[TABLE_NAME]}\').select();$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}${TAB}$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}}$END_OF_LINE';

    ret += '$TAB${TAB}${TAB}final result = data$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}?.map((j) => $className.fromJson(j))$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}.toList();$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}return Triple(true, result, "");$END_OF_LINE';

    ret += '$TAB${TAB}} catch (e, s) {$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(e);$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(s);$END_OF_LINE';
    ret +=
    '$TAB${TAB}${TAB}return Triple(false, null, e.toString());$END_OF_LINE';
    ret += '$TAB${TAB}}$END_OF_LINE';
    ret += '$TAB}$END_OF_LINE';

    return ret;
  }

  static String _getQueryById(Schema schema) {
    final className = schema.metaData[CLASS_NAME]!;
    var ret = '';

    ret +=
    '${TAB}static Future<Triple<bool, $className?, String>> queryById(int id) async {$END_OF_LINE';
    ret += '$TAB${TAB}final supabase = Supabase.instance.client;$END_OF_LINE';
    ret += '$TAB${TAB}try {$END_OF_LINE';
    ret +=
    '$TAB${TAB}${TAB}final result = await supabase.from(\'${schema.metaData[TABLE_NAME]}\')$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}.select()$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}.eq("_id", id);$END_OF_LINE$END_OF_LINE';

    ret +=
    '$TAB${TAB}${TAB}final row = $className.fromJson(result[0]);$END_OF_LINE';
    ret += "$TAB${TAB}${TAB}return Triple(true, row, '');$END_OF_LINE";
    ret += '$TAB${TAB}} catch (e, s) {$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(e);$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(s);$END_OF_LINE';
    ret +=
    '$TAB${TAB}${TAB}return Triple(false, null, e.toString());$END_OF_LINE';
    ret += '$TAB${TAB}}$END_OF_LINE';
    ret += '$TAB}$END_OF_LINE';

    return ret;
  }

  static String _getDelete(Schema schema) {
    final className = schema.metaData[CLASS_NAME]!;
    var ret = '';

    // static method
    ret +=
        '${TAB}static Future<Triple<bool, $className?, String>> delete(int id) async {$END_OF_LINE';
    ret += '$TAB${TAB}final supabase = Supabase.instance.client;$END_OF_LINE';
    ret += '$TAB${TAB}try {$END_OF_LINE';
    ret +=
        '$TAB${TAB}${TAB}final result = await supabase.from(\'${schema.metaData[TABLE_NAME]}\')$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}.delete()$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}.match({"_id": id})$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}.select();$END_OF_LINE$END_OF_LINE';

    ret +=
        '$TAB${TAB}${TAB}final deletedRow = $className.fromJson(result[0]);$END_OF_LINE';
    ret += "$TAB${TAB}${TAB}return Triple(true, deletedRow, '');$END_OF_LINE";
    ret += '$TAB${TAB}} catch (e, s) {$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(e);$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(s);$END_OF_LINE';
    ret +=
        '$TAB${TAB}${TAB}return Triple(false, null, e.toString());$END_OF_LINE';
    ret += '$TAB${TAB}}$END_OF_LINE';
    ret += '$TAB}$END_OF_LINE';

    return ret;
  }

  static String _getUpdate(Schema schema) {
    final className = schema.metaData[CLASS_NAME]!;
    final inputVar = className.toLowerCase();
    var ret = '';

    // static method
    ret +=
        '${TAB}static Future<Triple<bool, $className?, String>> update($className $inputVar) async {$END_OF_LINE';
    ret += '$TAB${TAB}final supabase = Supabase.instance.client;$END_OF_LINE';
    ret += '$TAB${TAB}try {$END_OF_LINE';
    ret +=
        '$TAB${TAB}${TAB}final result = await supabase.from(\"${schema.metaData[TABLE_NAME]}\").update({$END_OF_LINE';
    schema.fields
        .where((field) =>
            field[NAME] != '_id') // as SERIAL and BIGSERIAL are auto incremented
        .forEach((field) {
      final fieldName = field[NAME].toString();
      if (fieldName == '_userId') {
        ret +=
            '$TAB${TAB}${TAB}"_userid": supabase.auth.currentUser?.id,$END_OF_LINE';
      } else if (fieldName == '_createdAt') {
        // do nothing
      } else if (fieldName == '_lastModifiedAt') {
        ret +=
            '$TAB${TAB}${TAB}"${fieldName.toLowerCase()}": DateTime.now().toUtc().toIso8601String(),$END_OF_LINE';
      } else {
        ret +=
            '$TAB${TAB}${TAB}"${fieldName.toLowerCase()}": $inputVar.$fieldName,$END_OF_LINE';
      }
    });
    ret +=
        '$TAB${TAB}${TAB}}).match({"_id": $inputVar.id}).select();$END_OF_LINE';
    ret +=
        '$TAB${TAB}${TAB}final added = $className.fromJson(result[0]);$END_OF_LINE';
    ret += "$TAB${TAB}${TAB}return Triple(true, added, '');$END_OF_LINE";
    ret += '$TAB${TAB}} catch (e, s) {$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(e);$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(s);$END_OF_LINE';
    ret +=
        '$TAB${TAB}${TAB}return Triple(false, null, e.toString());$END_OF_LINE';
    ret += '$TAB${TAB}}$END_OF_LINE';
    ret += '$TAB}$END_OF_LINE';
    // ret += '$END_OF_LINE';

    // non-static method
    // ret += '${TAB}Future<Triple<bool, $className?, String>> update() async {$END_OF_LINE';
    // ret += '$TAB${TAB}return await update(this);$END_OF_LINE';
    // ret += '${TAB}}$END_OF_LINE';
    // ret += '$END_OF_LINE';

    return ret;
  }

  static String _getInsert(Schema schema) {
    final className = schema.metaData[CLASS_NAME]!;
    final inputVar = className.toLowerCase();
    var ret = '';

    // static method
    ret +=
        '${TAB}static Future<Triple<bool, $className?, String>> insert($className $inputVar) async {$END_OF_LINE';
    ret += '$TAB${TAB}final supabase = Supabase.instance.client;$END_OF_LINE';
    ret += '$TAB${TAB}try {$END_OF_LINE';
    ret +=
        '$TAB${TAB}${TAB}final result = await supabase.from(\"${schema.metaData[TABLE_NAME]}\").insert({$END_OF_LINE';
    schema.fields
        .where((field) =>
            field[NAME].toString().toUpperCase() != 'SERIAL' &&
            field[TYPE].toString().toUpperCase() !=
                'BIGSERIAL') // as serial is auto incremented
        .forEach((field) {
      final fieldName = field[NAME].toString();

      final String skipInInsertStr = field[SKIP_IN_INSERT] ?? 'false';
      final skipInInsert = skipInInsertStr.isNotEmpty ? bool.parse(skipInInsertStr) : false;

      if (!skipInInsert) {
        if (fieldName == '_userId') {
          ret +=
          '$TAB${TAB}${TAB}"_userid": supabase.auth.currentUser?.id,$END_OF_LINE';
        } else if (fieldName == '_createdAt') {
          ret +=
          '$TAB${TAB}${TAB}"${fieldName
              .toLowerCase()}": DateTime.now().toUtc().toIso8601String(),$END_OF_LINE';
        } else if (fieldName == '_lastModifiedAt') {
          // do nothing
        } else {
          if (field[TYPE].toString().toUpperCase() == 'TIMESTAMPTZ') {
            ret += '$TAB${TAB}${TAB}"${fieldName
                .toLowerCase()}": $inputVar.${field[NAME]}?.toUtc().toIso8601String(),$END_OF_LINE';
          } else {
            ret +=
            '$TAB${TAB}${TAB}"${fieldName
                .toLowerCase()}": $inputVar.$fieldName,$END_OF_LINE';
          }
        }
      }
    });
    ret += '$TAB${TAB}${TAB}}).select();$END_OF_LINE';
    ret +=
        '$TAB${TAB}${TAB}final added = $className.fromJson(result[0]);$END_OF_LINE';
    ret += "$TAB${TAB}${TAB}return Triple(true, added, '');$END_OF_LINE";
    ret += '$TAB${TAB}} catch (e, s) {$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(e);$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(s);$END_OF_LINE';
    ret +=
        '$TAB${TAB}${TAB}return Triple(false, null, e.toString());$END_OF_LINE';
    ret += '$TAB${TAB}}$END_OF_LINE';
    ret += '$TAB}$END_OF_LINE';
    // ret += '$END_OF_LINE';

    // non-static method
    // ret += '${TAB}Future<Triple<bool, $className?, String>> insert() async {$END_OF_LINE';
    // ret += '$TAB${TAB}return await insert(this);$END_OF_LINE';
    // ret += '${TAB}}$END_OF_LINE';
    // ret += '$END_OF_LINE';
    return ret;
  }

  static String _getToString(Schema schema) {
    var ret = '';
    ret += '$TAB@override$END_OF_LINE';
    ret += '${TAB}String toString() {$END_OF_LINE';
    ret += "$TAB${TAB}return '${schema.metaData[CLASS_NAME]}{";
    schema.fields.forEach((field) {
      final name = field[NAME];
      ret += '$name: \$$name,';
    });
    ret += "}';$END_OF_LINE";
    ret += '$TAB}$END_OF_LINE';
    return ret;
  }

  static String _getToMap(Schema schema) {
    var ret = '';
    ret += '${TAB}static Map<String, dynamic> convertToMap(${schema.metaData[CLASS_NAME]} obj) {$END_OF_LINE';
    ret += '${TAB}${TAB}return {$END_OF_LINE';
    schema.fields.forEach((field) {
      var mappedName = field[NAME].toString();
      if (mappedName.startsWith('_')) {
        mappedName = mappedName.substring(1);
      }
      ret +=
      '$TAB${TAB}${TAB}\'$mappedName\': obj.${field[NAME]},$END_OF_LINE';
    });
    ret += '${TAB}${TAB}};$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';

    ret += '$END_OF_LINE';

    ret += '${TAB}Map<String, dynamic> toMap() {$END_OF_LINE';
    ret += '${TAB}${TAB}return convertToMap(this);${END_OF_LINE}';
    ret += '${TAB}}$END_OF_LINE';

    return ret;
  }

  static String _getFactoryFromJson(Schema schema) {
    var ret = '';
    ret +=
        '${TAB}factory ${schema.metaData[CLASS_NAME]}.fromJson(Map<String, dynamic> json) {$END_OF_LINE';
    ret += '${TAB}${TAB}return ${schema.metaData[CLASS_NAME]}($END_OF_LINE';
    schema.fields.forEach((field) {
      var mappedName = field[NAME].toString();
      if (mappedName.startsWith('_')) {
        mappedName = mappedName.substring(1);
      }
      ret +=
          '$TAB${TAB}${TAB}$mappedName: ${_mapTypeToJson(field[NAME], _mapColumnTypeToDart(field[TYPE]))}$END_OF_LINE';
    });
    ret += '${TAB}${TAB});$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _mapTypeToJson(String name, String dartType) {
    var ret = '';
    switch (dartType) {
      case 'DateTime?':
        ret +=
            "DateTime.tryParse(json[\'${name.toLowerCase()}\'] ?? '')?.toLocal(),";
        break;
      case 'List<int>?':
        ret +=
            'AppUtils.castDynamicList<int>(json[\'${name.toLowerCase()}\']),';
        break;
      case 'List<String>?':
        ret +=
            'AppUtils.castDynamicList<String>(json[\'${name.toLowerCase()}\']),';
        break;
      default:
        if (name == '_userId') {
          ret += "json['_userid'] ?? '',";
        } else {
          ret += "json[\'${name.toLowerCase()}\'],";
        }
        break;
    }
    return ret;
  }

  static String _getMemberVariables(List<Map<String, dynamic>> fields) {
    var ret = '';
    fields.forEach((field) {
      switch (field[NAME]) {
        case '_id':
          ret += '${TAB}static const String c_id = "_id";$END_OF_LINE';
          ret += '${TAB}int _id = 0;$END_OF_LINE';
          ret += '${TAB}int get id => _id;$END_OF_LINE$END_OF_LINE';
          break;
        case '_userId':
          ret += '${TAB}static const String c_userid = "_userid";$END_OF_LINE';
          ret += "${TAB}String _userId = '';$END_OF_LINE";
          ret += '${TAB}String get userId => _userId;$END_OF_LINE$END_OF_LINE';
          break;
        case '_createdAt':
          ret += '${TAB}static const String c_createdat = "_createdat";$END_OF_LINE';
          ret += '${TAB}DateTime? _createdAt;$END_OF_LINE';
          ret +=
              '${TAB}DateTime? get createdAt => _createdAt;$END_OF_LINE$END_OF_LINE';
          break;
        case '_lastModifiedAt':
          ret += '${TAB}static const String c_lastmodifiedat = "_lastmodifiedat";$END_OF_LINE';
          ret += '${TAB}DateTime? _lastModifiedAt;$END_OF_LINE';
          ret +=
              '${TAB}DateTime? get lastModifiedAt => _lastModifiedAt;$END_OF_LINE$END_OF_LINE';
          break;
        default:
          ret +=
          '${TAB}static const String c_${field[NAME].toString().toLowerCase()} = "${field[NAME].toString().toLowerCase()}";$END_OF_LINE';
          ret +=
              '$TAB${_mapColumnTypeToDart(field[TYPE])} ${field[NAME]};$END_OF_LINE';
      }
    });
    return ret;
  }

  static String _getCopyConstructor(Schema schema) {
    var ret = '';
    final className = schema.metaData[CLASS_NAME];
    ret += '$TAB${className}.copy($className other) :$END_OF_LINE';
    schema.fields.forEach((field) {
      final fieldName = field[NAME];
      ret += '$TAB${TAB}$fieldName = other.$fieldName,$END_OF_LINE';
    });
    ret = ret.replaceFirst(
        ',', ';', ret.length - END_OF_LINE.length - 1); // replace last , to ;
    return ret;
  }

  static String _getReset(Schema schema) {
    var ret = '';
    ret += '$TAB void reset() {$END_OF_LINE';

    schema.fields.forEach((field) {
      final name = field[NAME] as String;
      switch (name) {
        case '_id':
          ret += "$TAB${TAB}_id = 0;$END_OF_LINE";
          break;
        case '_userId':
          ret += "$TAB${TAB}_userId = '';$END_OF_LINE";
          break;
        case '_createdAt':
          ret += "$TAB${TAB}_createdAt = null;$END_OF_LINE";
          break;
        case '_lastModifiedAt':
          ret += "$TAB${TAB}_lastModifiedAt = null;$END_OF_LINE";
          break;
        default:
          ret +=
          "$TAB${TAB}${field[NAME]} = ${_getDartDefaultValue(field)};$END_OF_LINE";
      }
    });

    ret += '$TAB}$END_OF_LINE';
    return ret;
  }

  static String _getConstructor(Schema schema) {
    var ret = '';
    ret += '$TAB ${schema.metaData[CLASS_NAME]}({$END_OF_LINE';

    schema.fields.forEach((field) {
      final name = field[NAME] as String;
      switch (name) {
        case '_id':
          ret += "$TAB${TAB}int id = 0,$END_OF_LINE";
          break;
        case '_userId':
          ret += "$TAB${TAB}String userId = '',$END_OF_LINE";
          break;
        case '_createdAt':
          ret += "$TAB${TAB}DateTime? createdAt,$END_OF_LINE";
          break;
        case '_lastModifiedAt':
          ret += "$TAB${TAB}DateTime? lastModifiedAt,$END_OF_LINE";
          break;
        default:
          ret +=
              "$TAB${TAB}this.${field[NAME]} = ${_getDartDefaultValue(field)},$END_OF_LINE";
      }
    });

    ret += '$TAB}) {$END_OF_LINE';
    ret += '$TAB${TAB}_id = id;$END_OF_LINE';
    if (schema.metaData[IS_USER_TABLE]) {
      ret += '$TAB${TAB}_userId = userId;$END_OF_LINE';
    }
    ret += '$TAB${TAB}_createdAt = createdAt;$END_OF_LINE';
    ret += '$TAB${TAB}_lastModifiedAt = lastModifiedAt;$END_OF_LINE';
    ret += '$TAB}$END_OF_LINE';
    return ret;
  }

  static String? _getDartDefaultValue(Map<String, dynamic> field) {
    final type = _mapColumnTypeToDart(field[TYPE]);
    final classDefaultVar = field[CLASS_DEFALT_VALUE] != null
        ? field[CLASS_DEFALT_VALUE].toString()
        : '';
    if (classDefaultVar.isNotEmpty) {
      if (type == 'bool') {
        return classDefaultVar.toLowerCase();
      }
      return classDefaultVar;
    } else {
      switch (type) {
        case 'int':
        case 'double':
          return '0';
        case 'String':
          return "''";
        case 'bool':
          return 'false';
      }
      return null;
    }
  }
}
