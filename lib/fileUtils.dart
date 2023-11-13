

import 'dart:io';

class FileUtils{


  static Future<bool> writeToFile(String dirPath, String fileName, String content) async {
    await mkdir(dirPath);

    String filePath = '$dirPath/$fileName';
    // Open the file in write mode (creates the file if it doesn't exist)
    File file = File(filePath);

    // Write the content to the file
    file.writeAsString(content).then((_) {
      print('File written successfully to $dirPath/$fileName');
    }).catchError((error) {
      print('Error writing to file $dirPath/$fileName: $error');
      return false;
    });

    return true;
  }

  static Future<void> mkdir(String dirPath) async {
    if (await Directory(dirPath).exists()) {
      return;
    }

    print('mkdir $dirPath');

    // Create directory if it doesn't exist
    await Directory(dirPath).create(recursive: true).then((Directory directory) {
      print('Directory created: ${directory.path}');
    }).catchError((error) {
      print('Error creating directory: $error');
    });
  }

}