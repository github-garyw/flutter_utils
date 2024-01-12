import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_utils/pair.dart';
import 'package:path/path.dart';

import 'dartGenerator.dart';
import './generatorUtils.dart';
import 'schema.dart';
import './sqlGenerator.dart';

void main() async {
  final directoryPath = '${Directory.current.path}/schemas/';
  generateFromDirectory(directoryPath);
}

void generateFromDirectory(String directoryPath) async {
  print('Schemas directory : ${directoryPath}');

  // Get a list of files in the directory
  final files = Directory(directoryPath).listSync();
  // Iterate through each file and read its content
  for (var file in files) {
    if (file is File && file.path.endsWith('.csv')) {
      print('CSV data from ${file.path}');

      // Read the CSV file content
      final schema = await readCSV2Schema(file);
      await SQLGenerator.createSqlFile(schema);
      await DartGenerator.createDartFile(schema);
    }
  }
}

String capitalizeFirstLetter(String input) {
  if (input == null || input.isEmpty) {
    return input; // Return the original string if it's null or empty.
  }

  // Capitalize the first letter and concatenate the rest of the string.
  return input[0].toUpperCase() + input.substring(1);
}

void printSchema(List<Map<String, dynamic>> schema) {
  schema.forEach((element) {
    print(element.entries
        .map((entry) => '${entry.key} => ${entry.value}')
        .join(', '));
  });
}

Pair<String, String> lineToPair(String line, String delimiter) {
  final firstDelimiterIndex = line.indexOf(delimiter);
  late Pair<String, String> ret;
  try {
    ret = Pair(line.substring(0, firstDelimiterIndex),
        line.substring(firstDelimiterIndex + 1));
  } catch (e, s) {
    print('Error in parsing "$line" with delimiter:"$delimiter"');
    print(e);
    print(s);
    throw e;
  }
  return ret;
}

Future<Schema> readCSV2Schema(File file) async {
  final ret = Schema();

  var contents = await file.readAsString();

  final lines = await contents.split(END_OF_LINE);
  // remove all comments
  lines.removeWhere((line) => line.startsWith(COMMENT_SYMBOL));

  // read meta data until START_OF_CSV
  do {
    final line = lines.removeAt(0);
    if (line == START_OF_CSV) {
      break;
    } else {
      final pair = lineToPair(line, META_DELMITER);
      if (pair.firstValue == IS_USER_TABLE) {
        ret.metaData[pair.firstValue] = bool.parse(pair.secondValue);
      } else {
        ret.metaData[pair.firstValue] = pair.secondValue;
      }
    }
  } while (lines.isNotEmpty);

  if (ret.metaData[DART_FILE_NAME] == null) {
    final dartFileName = basename(file.path).replaceAll('.csv', '.dart');
    ret.metaData[DART_FILE_NAME] = dartFileName;
  } else {
    ret.metaData[DART_FILE_NAME] += '.dart';
  }

  // Join the csv data back to a String
  contents = lines.join(END_OF_LINE);

  final rows = const CsvToListConverter().convert(contents, eol: END_OF_LINE);

  if (rows.isEmpty) {
    print('Error : empty csv ${file.path}');
  }

  final csvHeader = rows[0];

  // Convert rows to a list of maps
  final data = rows.map((List<dynamic> row) {
    final Map<String, dynamic> rowData = {};
    for (int i = 0; i < csvHeader.length; i++) {
      rowData[csvHeader[i]] = row[i];
    }
    return rowData;
  }).toList();
  data.removeAt(0); // remove header

  // id as primary key
  // must have createdAt and lastModifiedAt
  data.insert(0, _getDefaultRow("_id", "BIGSERIAL"));
  if (ret.metaData[IS_USER_TABLE]) {
    data.insert(1, _getDefaultRow("_userId", "UUID"));
  }
  data.add(_getDefaultRow("_createdAt", "TIMESTAMPTZ"));
  data.add(_getDefaultRow("_lastModifiedAt", "TIMESTAMPTZ"));

  // convert all type to uppercase
  data.forEach((field) {
    field[TYPE] = (field[TYPE] as String).toUpperCase();
  });

  ret.fields.addAll(data);

  return ret;
}

Map<String, dynamic> _getDefaultRow(String name, String type) {
  Map<String, dynamic> row = {};
  row[NAME] = name;
  row[TYPE] = type;
  return row;
}
