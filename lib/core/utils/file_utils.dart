import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Future<String> saveFilePermanently(String path) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = p.basename(path); // Extrae el nombre del archivo
    final permanentPath = '${directory.path}/$name';

    final file = File(path);
    final permanentFile = await file.copy(permanentPath);

    return permanentFile.path; // Retornamos la nueva ruta segura
  }
}
