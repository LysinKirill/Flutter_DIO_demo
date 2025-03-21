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

class _FileUploadScreenState extends State<FileUploadScreen> with SingleTickerProviderStateMixin {
  String? _filePath;
  double _uploadProgress = 0.0;
  String uploadUrl = 'https://run.mocky.io/v3/9dc5cd17-28fa-4034-846e-36368eba39d5';
  bool _isUploading = false;
  bool _showSuccess = false;
  bool _showError = false;
  String _errorMessage = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_filePath == null) {
      return;
    }

    Dio dio = Dio();

    setState(() {
      _isUploading = true;
      _showSuccess = false;
      _showError = false;
      _uploadProgress = 0.0;
    });

    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_filePath!),
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
          _isUploading = false;
          _showSuccess = true;
          _showError = false;
        });

        _animationController.forward().then((_) {
          setState(() {
            _showSuccess = false;
            _animationController.reset();
          });
        });
      } else {
        setState(() {
          _isUploading = false;
          _showError = true;
          _errorMessage = 'Upload failed: Server returned ${response.statusCode}';
        });

        _animationController.forward().then((_) {
          setState(() {
            _showError = false;
            _animationController.reset();
          });
        });
      }
    } on DioError catch (e) {
      String? errorMessage;
      if (e.type == DioErrorType.connectTimeout) {
          errorMessage = 'Upload failed: Connection timeout';
      } else if (e.type == DioErrorType.other) {
          errorMessage = 'Upload failed: No internet connection';
      } else {
        errorMessage = 'Upload failed: ${e.message}';
      }
      setState(() {
        _isUploading = false;
        _showError = true;
        _errorMessage = errorMessage ?? 'Upload failed: ${e.message}';
      });

      _animationController.forward().then((_) {
        setState(() {
          _showError = false;
          _uploadProgress = 0.0;
          _animationController.reset();
        });
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _showError = true;
        _errorMessage = 'Upload failed: $e';
      });

      _animationController.forward().then((_) {
        setState(() {
          _showError = false;
          _animationController.reset();
        });
      });
    }
  }

  Widget _buildFilePreview() {
    return Container(
      width: double.infinity,
      height: 200,
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(10),
      ),
      child: _filePath == null
          ? Center(
        child: Text(
          'No file selected.',
          style: TextStyle(color: Colors.grey),
        ),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Selected File: ${_filePath!.split('/').last}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(height: 10),
          _buildFileContentPreview(),
        ],
      ),
    );
  }

  Widget _buildFileContentPreview() {
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
              return Text(
                snapshot.data ?? 'No content',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              );
            }
          },
        );
      case 'png':
      case 'jpg':
      case 'jpeg':
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(_filePath!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 120,
          ),
        );
      case 'pdf':
        return Text(
          'PDF file selected. Preview not supported.',
          style: TextStyle(color: Colors.grey),
        );
      default:
        return Text(
          'Unsupported file type.',
          style: TextStyle(color: Colors.grey),
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
              LinearProgressIndicator(
                value: _uploadProgress,
                minHeight: 10,
              ),
              SizedBox(height: 20),
              if (_isUploading)
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Uploading...',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              if (_showSuccess)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 10),
                        Text(
                          'Upload successful!',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showError)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}