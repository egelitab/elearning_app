import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  
  static const String baseUrl = "http://10.0.2.2:5000/api"; 

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);

      // Change the condition to check for the presence of the accessToken
      if (response.statusCode == 200 && data['accessToken'] != null) {
        return data;
      } else {
        // If the backend sends an error message, use it, otherwise fallback
        throw Exception(data['message'] ?? 'Invalid email or password');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
 
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getInstructorCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("You are not logged in");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/courses/instructor'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load courses');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getInstructorMaterials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/materials/instructor'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load materials');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadMaterial(String courseId, String title, String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception("You are not logged in");

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/materials'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['course_id'] = courseId;
      request.fields['title'] = title;

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Upload failed');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getCourseEnrollmentStats(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/courses/$courseId/enrollment-stats'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch enrollment stats');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<dynamic> getInstructorTargets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/courses/instructor/targets'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load targets');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> renameMaterial(String id, String newTitle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.patch(
        Uri.parse('$baseUrl/materials/$id/rename'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"title": newTitle}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) return data;
      throw Exception(data['message'] ?? 'Failed to rename material');
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteMaterial(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.delete(
        Uri.parse('$baseUrl/materials/$id'),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) return data;
      throw Exception(data['message'] ?? 'Failed to delete material');
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> shareMaterials(List<String> materialIds, String departmentId, String? section) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final body = {
        "material_ids": materialIds,
        "department_id": departmentId,
      };
      if (section != null) body["section"] = section;

      final response = await http.post(
        Uri.parse('$baseUrl/materials/share'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) return data;
      throw Exception(data['message'] ?? 'Failed to share materials');
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getGroups(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/groups/$courseId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load groups');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> generateGroups(String courseId, int studentsPerGroup, {String? departmentId, String? section, String? method, String? title}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final Map<String, dynamic> body = {"studentsPerGroup": studentsPerGroup};
      if (departmentId != null) body["departmentId"] = departmentId;
      if (section != null) body["section"] = section;
      if (method != null) body["method"] = method;
      if (title != null) body["title"] = title;

      final response = await http.post(
        Uri.parse('$baseUrl/groups/$courseId/generate'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to generate groups');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> deleteGroupBatch(String courseId, String batchName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.delete(
        Uri.parse('$baseUrl/groups/$courseId/batch?batchName=${Uri.encodeComponent(batchName)}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete groups');
      }
    } catch (e) {
      throw Exception("Error deleting groups: $e");
    }
  }
}
