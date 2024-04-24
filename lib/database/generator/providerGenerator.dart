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
      classContent += _getDownloadOwned(schema);
      classContent += END_OF_LINE;

      classContent += _getOwnedMethod(schema);
      classContent += END_OF_LINE;

      classContent += _getReloadOwned(schema);
      classContent += END_OF_LINE;

      classContent += _getPreloadedOwnedData(schema);
      classContent += END_OF_LINE;

      classContent += _getSubscribeOwnedChanges(schema);
      classContent += END_OF_LINE;
    }

    classContent += _getNotifyMethod();
    classContent += END_OF_LINE;

    classContent += _getReplace(schema);
    classContent += END_OF_LINE;

    classContent += _getUpdateMethod(schema);
    classContent += END_OF_LINE;

    classContent += _getInsertMethod(schema);
    classContent += END_OF_LINE;

    classContent += _getDeltaMethods(schema);
    classContent += END_OF_LINE;

    classContent += _getIdExist(schema);
    classContent += END_OF_LINE;

    classContent += '}$END_OF_LINE';

    final targetPath = '${Directory.current.path}/lib/autoGenerated' +
        (schema.metaData[PACKAGE_PATH] ?? '');
    await FileUtils.writeToFile(targetPath,
        '${schema.metaData[DART_FILE_PREFIX]!}Provider.dart', classContent);
  }

  static String _getIdExist(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    return '''
	static bool _idExist(List<$className>? list, int id) {
		if (list == null || list.isEmpty) {
			return false;
		}

		return list.where((element) => element.id == id).isNotEmpty;
	}
	
    ''';
  }

  static String _getSubscribeOwnedChanges(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret = '''
  Future<void> subscribeDatabaseChanges() async {
    final supabase = Supabase.instance.client;
    _stream ??= await supabase
        .from($className.TABLE_NAME)
        .stream(primaryKey: ['id'])
        .eq('_userid', supabase.auth.currentUser!.id)
        .order('_createdat')
        .listen((event) {
          print('Received event: \$event');
          final newData =
              event.map((json) => $className.fromJson(json)).toList();
          _ownedData = newData;
          notify();
        }, onError: (error) {
          print('Error: \$error');
          _stream = null;
        }, onDone: () {
          print('Stream closed');
          _stream = null;
        });
  }
    ''';

    return ret;

  }

  static String _getDeltaMethods(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret = '';

    // subscribeUpdates
    ret += '''
  Future<void> subscribeDelta({bool force = false}) async {
    if (force) {
      await unsubscribeUpdates();
    }
    if (channel == null) {
      final supabase = Supabase.instance.client;
      channel = supabase
          .channel('public:\${$className.TABLE_NAME}')
          .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: $className.TABLE_NAME,
              callback: (payload) {
                print('Change received: \${payload.toString()}');
                _handleUpdate(payload);
              })
          .subscribe();
    }
  }
  
    ''';

    // unsubscribeUpdates
    ret += '''
Future<void> unsubscribeDelta() async {
    if (channel != null) {
      final supabase = Supabase.instance.client;
      await supabase.removeChannel(channel!);
      channel = null;
    }
  }
  
  ''';


    // _handleUpdate
    ret += '''
  void _handleUpdate(PostgresChangePayload payload) async {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
			case PostgresChangeEvent.update:
				final newId = payload.newRecord[$className.c_id] as int;
				final res = await $className.queryById(newId);
				if (res.first){
					final newObj = res.middle!;
					if (!_idExist(_allData, payload.newRecord[$className.c_id])) {
						_allData ??= <$className>[];
						_allData!.add(newObj);
					} else {
						_replace(_allData, newObj);
					}
''';
    if(schema.metaData[IS_USER_TABLE]) {
      ret += '''
					if (!_idExist(_ownedData, payload.newRecord[$className.c_id])) {
						_ownedData ??= <$className>[];
						_ownedData!.add(newObj);
					} else {
						_replace(_ownedData, newObj);
					}
      ''';
    }
    ret += '''
      notify();
				} else {
					throw Exception(res.last);
				}
        break;
      case PostgresChangeEvent.delete:
				final removedId = payload.oldRecord[$className.c_id] as int;
				_allData?.removeWhere((element) => element.id == removedId);
				''';
    if(schema.metaData[IS_USER_TABLE]) {
      ret += '''
				_ownedData?.removeWhere((element) => element.id == removedId);
      ''';
    }
    ret += '''
        notify();
        break;
      default:
				print('Unknown PostgresChangeEvent \$payload');
        break;
    }
  }
    ''';

    return ret;

  }

  static String _getQueryPreloadedDataById(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret = '';
    ret +=
        '${TAB}${className}? queryPreloadedDataById(int id) {$END_OF_LINE';
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
    return '''
	Future<Triple<bool, List<$className>?, String>> getAll$className() async {
		if (_allData != null) {
			return Triple(true, _allData, '');
		}
		final res = await _downloadAll();
		if (res.first) {
			_allData = res.middle;
		}
		return res;
	}
    ''';
  }

  static String _getOwnedMethod(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    return '''
	Future<Triple<bool, List<$className>?, String>> getUser$className() async {
		if (_ownedData != null) {
			return Triple(true, _ownedData, '');
		}
		final res = await _downloadOwned();
		if (res.first) {
			_ownedData = res.middle;
		}
		return res;
	}
	''';
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

  static String _getInsertMethod(Schema schema) {
    final className = schema.metaData[CLASS_NAME];
    var ret = '';
    ret +=
    '${TAB}Future<Triple<bool, $className?, String>> insert($className obj) async {$END_OF_LINE';
    ret += '${TAB}${TAB}final res = await $className.insert(obj);$END_OF_LINE';
    ret += '''${TAB}${TAB}if (res.first) {
			final newObj = res.middle!;
			_allData ??= <$className>[];
			_allData!.add(newObj);
''';
    if (schema.metaData[IS_USER_TABLE]) {
      ret += '${TAB}${TAB}${TAB}_ownedData ??= <$className>[];$END_OF_LINE';
      ret += '${TAB}${TAB}${TAB}_ownedData!.add(newObj);$END_OF_LINE';
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
    ret += '$TAB${TAB}${TAB}return Triple(true, result, "");$END_OF_LINE';
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
    ret += '$TAB${TAB}${TAB}return Triple(true, result, "");$END_OF_LINE';
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
        '${TAB}List<${schema.metaData[CLASS_NAME]}>? getPreloadedUserData() {$END_OF_LINE';
    ret +=
        '${TAB}${TAB}return _ownedData == null ? null : List.of(_ownedData!);$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _getPreloadedAllData(Schema schema) {
    var ret = '';
    ret +=
        '${TAB}List<${schema.metaData[CLASS_NAME]}>? getPreloadedAllData() {$END_OF_LINE';
    ret +=
        '${TAB}${TAB}return _allData == null ? null : List.of(_allData!);$END_OF_LINE';
    ret += '${TAB}}$END_OF_LINE';
    return ret;
  }

  static String _getMembers(Schema schema) {
    var ret = '';
    ret +=
        '${TAB}static const bool _IS_USER_TABLE = ${schema.metaData[IS_USER_TABLE]};$END_OF_LINE${END_OF_LINE}';
    ret += '${TAB}RealtimeChannel? channel;$END_OF_LINE';
    ret +=
        '${TAB}List<${schema.metaData[CLASS_NAME]}>? _allData;$END_OF_LINE';

    if (schema.metaData[IS_USER_TABLE]) {
      ret +=
          '${TAB}List<${schema.metaData[CLASS_NAME]}>? _ownedData;$END_OF_LINE';
      ret +=
          '${TAB}StreamSubscription<SupabaseStreamEvent>? _stream;$END_OF_LINE';
    }

    return ret;
  }

  static String _getImport(Schema schema) {
    var ret = '';
    ret += "import 'dart:async';$END_OF_LINE";
    ret += "import 'package:flutter/material.dart';$END_OF_LINE";
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
