import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
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

    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_filePath!),
      });

      setState(() {
        _uploadStatus = 'Uploading...';
        _uploadProgress = 0.0;
      });

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
      setState(() {
        _uploadStatus = 'Upload failed: $e';
      });
    }
  }

  Widget _buildFilePreview() {
    if (_filePath == null) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No file selected.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    String fileExtension = _filePath!.split('.').last.toLowerCase();

    switch (fileExtension) {
      case 'txt':
        return FutureBuilder<String>(
          future: _readTextFile(_filePath!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error reading file: ${snapshot.error}');
            } else {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  snapshot.data ?? 'No content',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }
          },
        );
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Container(
          margin: EdgeInsets.symmetric(vertical: 20),
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(_filePath!),
              fit: BoxFit.cover,
            ),
          ),
        );
      case 'pdf':
        return Container(
          margin: EdgeInsets.symmetric(vertical: 20),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'PDF file selected. Preview not supported.',
            style: TextStyle(color: Colors.grey),
          ),
        );
      default:
        return Container(
          margin: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Unsupported file type.',
            style: TextStyle(color: Colors.grey),
          ),
        );
    }
  }

  Future<String> _readTextFile(String path) async {
    return await File(path).readAsString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Dio File Uploader',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilePreview(),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: Icon(Icons.attach_file),
                label: Text('Select File'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _uploadFile,
                icon: Icon(Icons.cloud_upload),
                label: Text('Upload File'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              LinearProgressIndicator(value: _uploadProgress),
              SizedBox(height: 20),
              Text(
                _uploadStatus,
                style: TextStyle(
                  color: _uploadStatus.contains('failed') ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}