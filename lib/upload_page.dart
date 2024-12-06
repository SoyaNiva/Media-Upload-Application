import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> uploadedFiles = [];
  bool isLoading = true;
  bool isUploading = false;
  double uploadProgress = 0;

  final String apiBaseUrl = "http://10.0.2.2:5000";

  @override
  void initState() {
    super.initState();
    fetchUploadedFiles();
  }

  Future<void> fetchUploadedFiles() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/files'));
      if (response.statusCode == 200) {
        setState(() {
          uploadedFiles = jsonDecode(response.body)['files'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load files');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching files: $e");
    }
  }

  Future<void> uploadFile() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.video);

      if (result != null) {
        String filePath = result.files.single.path!;
        File file = File(filePath);

        if (await file.exists()) {
          setState(() {
            isUploading = true;
            uploadProgress = 0;
          });

          var request =
              http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/upload'));
          request.files
              .add(await http.MultipartFile.fromPath('file', file.path));

          request.send().then((response) {
            response.stream.listen((value) {
              setState(() {
                uploadProgress = value.length / file.lengthSync();
              });
            });

            if (response.statusCode == 200) {
              print('File uploaded successfully!');
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("File uploaded successfully!")));
              fetchUploadedFiles(); 
            } else {
              print(
                  'Failed to upload file. Status code: ${response.statusCode}');
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to upload file.")));
            }
            setState(() {
              isUploading = false;
            });
          });
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("File does not exist.")));
        }
      }
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      print("Error uploading file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload file. Please try again.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'UploadEase',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue,
          elevation: 10,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(
                  child: Text(
                    'Welcome to UploadEase!',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Text(
                  textAlign: TextAlign.center,
                  'A simple and efficient platform to upload and manage your video files.',
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                ),
              ),
              SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: uploadFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: isUploading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.upload_file, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Upload Video',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 60),
              if (isUploading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(
                    value: uploadProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : uploadedFiles.isEmpty
                      ? Center(
                          child: Text(
                            "No files uploaded yet. Start uploading now!",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey),
                          ),
                        )
                      : Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  'Uploaded Files',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87),
                                ),
                              ),
                              SizedBox(height: 10),
                              Expanded(
                                child: ListView.builder(
                                  reverse: true,
                                  itemCount: uploadedFiles.length,
                                  itemBuilder: (context, index) {
                                    return Card(
                                      margin: EdgeInsets.symmetric(vertical: 5),
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.all(10),
                                        leading: Icon(Icons.file_present,
                                            color: Colors.blue),
                                        title: Text(
                                          uploadedFiles[index],
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                        trailing: Icon(Icons.more_vert,
                                            color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
            ],
          ),
        ),
        floatingActionButton: isUploading
            ? FloatingActionButton(
                onPressed: uploadFile,
                child: Icon(Icons.upload_file),
                backgroundColor: Colors.red,
              )
            : null);
  }
}
