import 'dart:io';

import '../../fileUtils.dart';
import 'generatorUtils.dart';
import 'schema.dart';

class ProviderGenerator {
  static String _getClassName(Schema schema) {
    return '${schema.metaData[CLASS_NAME]}Provider';
  }

  static Future<void> createProviderFile(Schema schema) async {
    var classContent = _getImport(schema);
    classContent += END_OF_LINE;
    classContent += END_OF_LINE;

    classContent +=
        'class ${_getClassName(schema)} extends ChangeNotifier {$END_OF_LINE';
    classContent += _getMembers(schema);
    classContent += END_OF_LINE;

    classContent += _getAllStaticMethod(schema);
    classContent += END_OF_LINE;

    classContent += _getAllMethod(schema);
    classContent += END_OF_LINE;

    classContent += _getDownloadAll(schema);
    classContent += END_OF_LINE;

    classContent += _getReloadAll(schema);
    classContent += END_OF_LINE;

    classContent += _getPreloadedAllData(schema);
    classContent += END_OF_LINE;

    classContent += _getQueryPreloadedDataById(schema);
    classContent += END_OF_LINE;

    if (schema.metaData[IS_USER_TABLE]) {
      classContent += _getOwnedStaticMethod(schema);
      classContent += END_OF_LINE;

      classContent += _getDownloadOwned(schema);
      classContent += END_OF_LINE;

      classContent += _getOwnedMethod(schema);
      classContent += END_OF_LINE;

      classContent += _getReloadOwned(schema);
      classContent += END_OF_LINE;

      classContent += _getPreloadedOwnedData(schema);
      classContent += END_OF_LINE;
    }

    classContent += _getNotifyMethod();
    classContent += END_OF_LINE;

    classContent += _getReplace(schema);
    classContent += END_OF_LINE;

    classContent += _getUpdateMethod(schema);
    classContent += END_OF_LINE;

    classContent += '}$END_OF_LINE';

    final targetPath = '${Directory.current.path}/lib/autoGenerated' +
        (schema.metaData[PACKAGE_PATH] ?? '');
    await FileUtils.writeToFile(targetPath,
        '${schema.metaData[DART_FILE_PREFIX]!}Provider.dart', classContent);
  }

  static String _getQueryPreloadedDataById(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret = '';
    ret +=
        '${TAB}static ${className}? queryPreloadedDataById(int id) {$END_OF_LINE';
    ret +=
        '${TAB}${TAB}return _allData?.where((element) => element.id == id).firstOrNull;$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _getReloadAll(Schema schema) {
    var ret = '';
    ret += '${TAB}Future<void> reloadAll() async {$END_OF_LINE';
    ret += '${TAB}${TAB}await _downloadAll();$END_OF_LINE';
    ret += '${TAB}${TAB}notify();$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _getReloadOwned(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret = '';
    ret += '${TAB}Future<void> reloadOwned() async {$END_OF_LINE';
    ret += '${TAB}${TAB}await _downloadOwned();$END_OF_LINE';
    ret += '${TAB}${TAB}notify();$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _getAllMethod(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret = '';
    ret +=
        '${TAB}Future<Triple<bool, List<$className>?, String>> getAll$className() async {$END_OF_LINE';
    ret += '${TAB}${TAB}return await sGetAll${className}();$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _getOwnedMethod(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret = '';
    ret +=
        '${TAB}Future<Triple<bool, List<$className>?, String>> getUser$className() async {$END_OF_LINE';
    ret += '${TAB}${TAB}return await sGetUser${className}();$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _getUpdateMethod(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret = '';
    ret +=
        '${TAB}Future<Triple<bool, $className?, String>> update($className obj) async {$END_OF_LINE';
    ret += '${TAB}${TAB}final res = await $className.update(obj);$END_OF_LINE';
    ret += '''${TAB}${TAB}if (res.first) {
			final newObj = res.middle!;
			_replace(_allData, newObj);
''';
    if (schema.metaData[IS_USER_TABLE]) {
      ret += '${TAB}${TAB}${TAB}_replace(_ownedData, newObj);$END_OF_LINE';
    }
    ret += '${TAB}${TAB}${TAB}notify();$END_OF_LINE';
		ret += '${TAB}${TAB}}$END_OF_LINE';
    ret += '${TAB}${TAB}return res;$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _getNotifyMethod() {
    var ret = '';
    ret += '${TAB}void notify(){$END_OF_LINE';
    ret += '${TAB}${TAB}notifyListeners();$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _getAllStaticMethod(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret = '';
    ret +=
        '${TAB}static Future<Triple<bool, List<$className>?, String>> sGetAll$className() async {$END_OF_LINE';
    ret += '${TAB}${TAB}if(_allData != null){$END_OF_LINE';
    ret += '${TAB}${TAB}${TAB}return Triple(true, _allData, "");$END_OF_LINE';
    ret += '${TAB}${TAB}}$END_OF_LINE';
    ret += END_OF_LINE;
    ret += '${TAB}${TAB}return await _downloadAll();$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _getOwnedStaticMethod(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret = '';
    ret +=
        '${TAB}static Future<Triple<bool, List<$className>?, String>> sGetUser$className() async {$END_OF_LINE';
    ret += '${TAB}${TAB}if(_ownedData != null){$END_OF_LINE';
    ret += '${TAB}${TAB}${TAB}return Triple(true, _ownedData, "");$END_OF_LINE';
    ret += '${TAB}${TAB}}$END_OF_LINE';
    ret += END_OF_LINE;
    ret += '${TAB}${TAB}return await _downloadOwned();$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _getDownloadAll(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret = '';
    ret +=
        '${TAB}static Future<Triple<bool, List<$className>?, String>> _downloadAll() async {$END_OF_LINE';
    ret += END_OF_LINE;
    ret += '${TAB}${TAB}final supabase = Supabase.instance.client;$END_OF_LINE';
    ret += END_OF_LINE;
    ret += '${TAB}${TAB}try {$END_OF_LINE';
    ret += '${TAB}${TAB}${TAB}final data = await supabase$END_OF_LINE';
    ret += '${TAB}${TAB}${TAB}${TAB}.from(${className}.TABLE_NAME)$END_OF_LINE';
    ret += '${TAB}${TAB}${TAB}${TAB}.select() as List<dynamic>;$END_OF_LINE';
    ret += END_OF_LINE;
    ret +=
        '${TAB}${TAB}${TAB}final result = data?.map((json) => ${className}.fromJson(json)).toList();$END_OF_LINE';
    ret += '${TAB}${TAB}${TAB}_allData = result;$END_OF_LINE';
    ret +=
        '${TAB}${TAB}${TAB}_allData?.sort((a, b) => a.createdAt!.compareTo(b.createdAt!));$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}return Triple(true, _allData, "");$END_OF_LINE';
    ret += '${TAB}${TAB}} catch (e, s) {$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(e);$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(s);$END_OF_LINE';
    ret +=
        '$TAB${TAB}${TAB}return Triple(false, null, e.toString());$END_OF_LINE';
    ret += '${TAB}${TAB}}$END_OF_LINE';
    ret += END_OF_LINE;
    ret += '${TAB}}$END_OF_LINE';

    return ret;
  }

  static String _getDownloadOwned(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret = '';
    ret +=
        '${TAB}static Future<Triple<bool, List<$className>?, String>> _downloadOwned() async {$END_OF_LINE';
    ret += END_OF_LINE;
    ret += '${TAB}${TAB}final supabase = Supabase.instance.client;$END_OF_LINE';
    ret +=
        '${TAB}${TAB}final userId = supabase.auth.currentUser?.id;$END_OF_LINE';
    ret += END_OF_LINE;
    ret += '${TAB}${TAB}if (userId == null) {$END_OF_LINE';
    ret +=
        '${TAB}${TAB}${TAB}return Triple(false, null, "User ID is null");$END_OF_LINE';
    ret += '${TAB}${TAB}}$END_OF_LINE';
    ret += END_OF_LINE;
    ret += '${TAB}${TAB}try {$END_OF_LINE';
    ret += '${TAB}${TAB}${TAB}final data = await supabase$END_OF_LINE';
    ret += '${TAB}${TAB}${TAB}${TAB}.from(${className}.TABLE_NAME)$END_OF_LINE';
    ret += '${TAB}${TAB}${TAB}${TAB}.select()$END_OF_LINE';
    ret +=
        '${TAB}${TAB}${TAB}${TAB}.eq(${className}.c_userid, userId) as List<dynamic>;$END_OF_LINE';
    ret += END_OF_LINE;
    ret +=
        '${TAB}${TAB}${TAB}final result = data?.map((json) => ${className}.fromJson(json)).toList();$END_OF_LINE';
    ret += '${TAB}${TAB}${TAB}_ownedData = result;$END_OF_LINE';
    ret +=
        '${TAB}${TAB}${TAB}_ownedData?.sort((a, b) => a.createdAt!.compareTo(b.createdAt!));$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}return Triple(true, _ownedData, "");$END_OF_LINE';
    ret += '${TAB}${TAB}} catch (e, s) {$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(e);$END_OF_LINE';
    ret += '$TAB${TAB}${TAB}print(s);$END_OF_LINE';
    ret +=
        '$TAB${TAB}${TAB}return Triple(false, null, e.toString());$END_OF_LINE';
    ret += '${TAB}${TAB}}$END_OF_LINE';
    ret += END_OF_LINE;
    ret += '${TAB}}$END_OF_LINE';

    return ret;
  }

  static String _getPreloadedOwnedData(Schema schema) {
    var ret = '';
    ret +=
        '${TAB}static List<${schema.metaData[CLASS_NAME]}>? getPreloadedUserData() {$END_OF_LINE';
    ret +=
        '${TAB}${TAB}return _ownedData == null ? null : List.of(_ownedData!);$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _getPreloadedAllData(Schema schema) {
    var ret = '';
    ret +=
        '${TAB}static List<${schema.metaData[CLASS_NAME]}>? getPreloadedAllData() {$END_OF_LINE';
    ret +=
        '${TAB}${TAB}return _allData == null ? null : List.of(_allData!);$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _getMembers(Schema schema) {
    var ret = '';
    ret +=
        '${TAB}static const bool _IS_USER_TABLE = ${schema.metaData[IS_USER_TABLE]};$END_OF_LINE${END_OF_LINE}';
    ret +=
        '${TAB}static List<${schema.metaData[CLASS_NAME]}>? _allData;$END_OF_LINE';

    if (schema.metaData[IS_USER_TABLE]) {
      ret +=
          '${TAB}static List<${schema.metaData[CLASS_NAME]}>? _ownedData;$END_OF_LINE';
    }

    return ret;
  }

  static String _getImport(Schema schema) {
    var ret = '';
    ret = "import 'package:flutter/material.dart';$END_OF_LINE";
    ret +=
        "import 'package:supabase_flutter/supabase_flutter.dart';$END_OF_LINE";
    ret += "import 'package:flutter_utils/triple.dart';$END_OF_LINE";
    ret += "import '${schema.metaData[DART_FILE_NAME]}';$END_OF_LINE";

    return ret;
  }

  static String _getReplace(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret =
        '''${TAB}static void _replace(List<$className>? list, $className newObj) {
		if (list == null) {
			return;
		}
		
		final index = list.indexWhere((element) => element.id == newObj.id);
		if (index != -1) {
			list[index] = newObj;
		}
	}
	''';
    return ret;
  }
}
