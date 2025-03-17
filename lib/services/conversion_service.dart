import 'dart:convert';
import 'dart:io';
import 'package:easy_scan/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ConversionService {
  Future<String> convertFile({
    required File file,
    required String inputFormat,
    required String outputFormat,
    bool ocrEnabled = false,
    int quality = 90,
    String? password,
    Function(double)? onProgress,
  }) async {
    try {
      // Report initial progress
      onProgress?.call(0.1);

      // Create multipart request
      var uri = Uri.parse("${ApiConfig.baseUrl}/convert");
      var request = http.MultipartRequest("POST", uri);

      // Add headers
      request.headers['X-API-Key'] = ApiConfig.apiKey;

      // Add file and parameters
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['inputFormat'] = inputFormat;
      request.fields['outputFormat'] = outputFormat;
      request.fields['ocr'] = ocrEnabled ? 'true' : 'false';
      request.fields['quality'] = quality.toString();

      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }

      print("Sending conversion request to: ${ApiConfig.baseUrl}/convert");
      print("File: ${file.path}");
      print(
          "Parameters: inputFormat=$inputFormat, outputFormat=$outputFormat, ocr=$ocrEnabled, quality=$quality");

      // Send request
      var streamedResponse = await request.send();
      onProgress?.call(0.4);

      // Check response
      if (streamedResponse.statusCode != 200) {
        var errorBody = await streamedResponse.stream.bytesToString();
        print(
            "API Error: Status ${streamedResponse.statusCode}, Body: $errorBody");
        throw Exception(
            "API error: ${streamedResponse.statusCode} - $errorBody");
      }

      // Parse response
      var response = await http.Response.fromStream(streamedResponse);
      var responseBody = response.body;
      print("API Response: $responseBody");

      Map<String, dynamic>? responseJson;
      try {
        responseJson = jsonDecode(responseBody);
      } catch (e) {
        print("Failed to parse JSON response: $e");
        throw Exception("Invalid response format from server");
      }

      onProgress?.call(0.5);

      // Validate response
      if (responseJson == null ||
          !responseJson.containsKey('success') ||
          responseJson['success'] != true) {
        print("API returned failure or invalid format: $responseJson");
        throw Exception("Conversion failed on server side");
      }

      // Get the filename and fileUrl directly from the response
      final String filename =
          responseJson['filename'] ?? "converted.$outputFormat";

      // Get the file URL from the response
      if (!responseJson.containsKey('fileUrl')) {
        throw Exception("No fileUrl found in response");
      }

      // Extract the fileUrl and construct the full download URL
      // The API returns a relative URL like "/conversions/filename.ext"
      String fileUrl = responseJson['fileUrl'];

      // Create the absolute URL by combining the base URL (without /api part) and the fileUrl
      // This assumes your API base URL is like "https://domain.com/api" and
      // your static files are served from the root like "https://domain.com/conversions/..."

      String downloadUrl =
          "${ApiConfig.baseUrl}//file?folder=conversions&filename=${filename}";

      print("Using direct fileUrl download: $downloadUrl");
      print("Downloading from: $downloadUrl");

      var downloadResponse = await http.get(Uri.parse(downloadUrl));

      if (downloadResponse.statusCode != 200) {
        print("Download failed with status: ${downloadResponse.statusCode}");
        throw Exception(
            "Failed to download converted file (Status: ${downloadResponse.statusCode})");
      }

      onProgress?.call(0.8);

      // Save the file locally
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, filename);

      await File(filePath).writeAsBytes(downloadResponse.bodyBytes);

      print("File saved successfully to: $filePath");
      onProgress?.call(1.0);

      return filePath;
    } catch (e) {
      print("Conversion failed: $e");
      throw Exception('Conversion failed: $e');
    }
  }
}
