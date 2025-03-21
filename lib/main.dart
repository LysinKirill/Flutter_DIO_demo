import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio_http_cache/dio_http_cache.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dio File Uploader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FileUploadScreen(),
    );
  }
}

class FileUploadScreen extends StatefulWidget {
  @override
  _FileUploadScreenState createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  String? _filePath;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  //String uploadUrl = 'https://run.mocky.io/v3/cb43b209-3eb1-431a-8ed1-e8e1338a0008';
  String uploadUrl = 'https://run.mocky.io/v3/9dc5cd17-28fa-4034-846e-36368eba39d5';

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
        _uploadStatus = 'File selected: ${result.files.single.name}';
      });
    } else {
      setState(() {
        _uploadStatus = 'No file selected.';
      });
    }
  }



  Future<void> _uploadFile() async {
    if (_filePath == null) {
      setState(() {
        _uploadStatus = 'No file selected.';
      });
      return;
    }

    Dio dio = Dio();
    String uploadUrl = 'https://run.mocky.io/v3/6325fac0-e88a-4cad-bc68-9f35707fa8d1';

    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_filePath!),
      });

      setState(() {
        _uploadStatus = 'Uploading...';
        _uploadProgress = 0.0;
      });

      print('Selected file path: $_filePath');

      Response response = await dio.post(
        uploadUrl,
        data: formData,
        options: buildCacheOptions(Duration(hours: 1)),
        onSendProgress: (int sent, int total) {
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );

      print('Response: $response');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');

      // Check the response status code
      if (response.statusCode == 200) {
        setState(() {
          _uploadStatus = 'Upload complete! Response: ${response.data}';
        });
      } else {
        setState(() {
          _uploadStatus = 'Upload failed: Server returned ${response.statusCode}';
        });
      }
    } on DioError catch (e) {
      // Handle Dio-specific errors
      if (e.response != null) {
        setState(() {
          _uploadStatus = 'Upload failed: Server error - ${e.response?.statusCode}';
        });
      } else if (e.type == DioErrorType.connectTimeout) {
        setState(() {
          _uploadStatus = 'Upload failed: Connection timeout';
        });
      } else if (e.type == DioErrorType.other) {
        setState(() {
          _uploadStatus = 'Upload failed: No internet connection';
        });
      } else {
        setState(() {
          _uploadStatus = 'Upload failed: ${e.message}';
        });
      }
    } catch (e) {
      // Handle other errors
      setState(() {
        _uploadStatus = 'Upload failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dio File Uploader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Select File'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadFile,
              child: Text('Upload File'),
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(value: _uploadProgress),
            SizedBox(height: 20),
            Text(_uploadStatus),
          ],
        ),
      ),
    );
  }
}