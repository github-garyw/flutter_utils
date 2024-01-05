import 'dart:io';

import 'package:flutter_utils/fileUtils.dart';
import 'package:flutter_utils/pair.dart';

import './generatorUtils.dart';
import 'schema.dart';

class SQLGenerator {
  static String _getVariables(List<Map<String, dynamic>> fields) {
    final ret = fields.map((variable) {
      var ret = '\t';
      ret +=
          '${variable[NAME].toString().toLowerCase()}'; // name is converted to lower case by supabse anyway
      ret += ' ${(variable[TYPE] as String).toUpperCase()} ';
      if (variable[NAME] == "_id") {
        ret += 'PRIMARY KEY ';
      }

      final defaultValue = variable[TABLE_DEFALT_VALUE];
      if (defaultValue != null && defaultValue.toString().isNotEmpty) {
        ret += 'DEFAULT ${defaultValue.toString()} ';
      }
      return ret;
    }).join(', $END_OF_LINE');

    return ret;
  }

  static Pair<String, String> _createTableStoredProcedure(
      String tableName, List<Map<String, dynamic>> schema) {

    final sql = '''CREATE TABLE IF NOT EXISTS $tableName (
${_getVariables(schema)}
)''';

    return Pair(tableName, sql);
  }

  static Future<void> createSqlFile(Schema schema) async {
    final result = _createTableStoredProcedure(
        schema.metaData[TABLE_NAME]!, schema.fields);

    await FileUtils.writeToFile('${Directory.current.path}/autoGenerated/sql/createTable',
        '${result.firstValue}.sql', result.secondValue);
  }

}
