import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import '../dashboards/file_viewer_screen.dart';

class ApiService {
  
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:5000/api";
    try {
      if (Platform.isAndroid) return "http://10.0.2.2:5000/api";
    } catch (_) {}
    return "http://localhost:5000/api";
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    print("Using baseUrl: $baseUrl");
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

  // ========================
  // Password Reset Flow
  // ========================

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to request password reset');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-reset-code'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "code": code}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Invalid reset code');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> resetPassword(String confirmToken, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"confirmToken": confirmToken, "newPassword": newPassword}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<List<dynamic>> getStudentCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/courses/student'),
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

  Future<List<dynamic>> getInstructorCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

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

  Future<Map<String, dynamic>> uploadMaterial(String? courseId, String title, String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception("You are not logged in");

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/materials'));
      request.headers['Authorization'] = 'Bearer $token';
      if (courseId != null) {
        request.fields['course_id'] = courseId;
      }
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
    print("Fetching Enrollment Stats from: $baseUrl/courses/$courseId/enrollment-stats");
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

  Future<List<dynamic>> getCourseChapters(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/courses/$courseId/chapters'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load chapters');
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

  Future<Map<String, dynamic>> shareMaterials(List<String> materialIds, String? courseId, String? departmentId, String? section, {String? chapterId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final body = {
        "material_ids": materialIds,
        "course_id": courseId,
        "department_id": departmentId,
        "chapter_id": chapterId,
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

  Future<Map<String, dynamic>> unshareMaterials(List<String> materialIds, String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/materials/unshare'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          "material_ids": materialIds,
          "course_id": courseId,
        }),
      );
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) return data;
      throw Exception(data['message'] ?? 'Failed to unshare materials');
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getMaterialsByCourse(String courseId, {String? chapterId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      String url = '$baseUrl/materials/course/$courseId';
      if (chapterId != null) url += '?chapter_id=$chapterId';

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
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

  Future<List<dynamic>> getMyGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/groups/student/my-groups'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load your groups');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  // === Assessment Methods ===

  Future<List<dynamic>> getAssessments(String courseId) async {
    print("Fetching Assessments from: $baseUrl/assignments/course/$courseId");
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/assignments/course/$courseId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load assessments');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getStudentAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/assignments/student/my-assignments'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load assignments');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> submitAssignment(String assignmentId, String filePath, {String? groupId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/assignments/submit'));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['assignment_id'] = assignmentId;
      if (groupId != null) {
        request.fields['group_id'] = groupId;
      }
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Submission failed');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> createAssessment(Map<String, dynamic> assessmentData, {String? filePath}) async {

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/assignments'));
      request.headers['Authorization'] = 'Bearer $token';
      
      assessmentData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to create assessment');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getExistingGroups(String courseId) async {
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

  // === Grading Methods ===

  Future<List<dynamic>> getGradingOverview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/assignments/grading-overview'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load grading overview');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getSubmissions(String assignmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/assignments/$assignmentId/submissions'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load submissions');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> gradeSubmission(String submissionId, double grade, String feedback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.put(
        Uri.parse('$baseUrl/assignments/submissions/$submissionId/grade'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "grade": grade,
          "feedback": feedback
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to grade submission');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  // === Inbox & Message Methods ===

  Future<List<dynamic>> getInbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/messages/inbox'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load inbox');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getChatHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/messages/history/$userId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load chat history');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> sendMessage(String receiverId, String content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "receiver_id": receiverId,
          "content": content
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode != 201 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  // --- Group Chat Methods ---

  Future<List<dynamic>> getGroupInbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/messages/group/inbox'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load group inbox');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getGroupChatHistory(String groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/messages/group/history/$groupId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load group chat history');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> sendGroupMessage(String groupId, String content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/messages/group'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "group_id": groupId,
          "content": content,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode != 201 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to send group message');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getInstructorGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/messages/instructor/groups'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load instructor groups');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  // === Announcement Methods ===

  Future<List<dynamic>> getAnnouncements(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final endpoint = role == 'instructor' ? 'instructor' : 'student';
      final response = await http.get(
        Uri.parse('$baseUrl/announcements/$endpoint'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load announcements');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> createAnnouncement(String courseId, String title, String content, {String? section, List<String>? attachments}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final Map<String, dynamic> body = {
        "course_id": courseId,
        "title": title,
        "content": content
      };
      if (section != null) body["section"] = section;
      if (attachments != null) body["attachments"] = attachments;

      final response = await http.post(
        Uri.parse('$baseUrl/announcements'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode != 201 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to create announcement');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> updateAnnouncement(String id, String title, String content, {String? section, List<String>? attachments}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final Map<String, dynamic> body = {
        "title": title,
        "content": content
      };
      if (section != null) body["section"] = section;
      if (attachments != null) body["attachments"] = attachments;

      final response = await http.put(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to update announcement');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.delete(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete announcement');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  // === Instructor Files Methods ===

  Future<Map<String, dynamic>> getInstructorStorage({String? folderId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final url = folderId != null 
          ? '$baseUrl/instructor-files?folder_id=$folderId'
          : '$baseUrl/instructor-files';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load storage');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> createFolder(String name, {String? parentId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/instructor-files/folder'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": name,
          "parent_id": parentId
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode != 201 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to create folder');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> uploadInstructorFile(String filePath, {String? folderId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/instructor-files/upload'));
      request.headers['Authorization'] = 'Bearer $token';
      if (folderId != null) request.fields['folder_id'] = folderId;
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode != 201 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to upload file');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> renameEntry(String id, String type, String newName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final url = type == 'folder' 
          ? '$baseUrl/instructor-files/folder/$id/rename'
          : '$baseUrl/instructor-files/file/$id/rename';

      final response = await http.patch(
        Uri.parse(url),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"name": newName}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to rename $type');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> softDeleteEntry(String id, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final url = type == 'folder' 
          ? '$baseUrl/instructor-files/folder/$id'
          : '$baseUrl/instructor-files/file/$id';

      final response = await http.delete(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete $type');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> moveEntry(String id, String type, String? targetFolderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.patch(
        Uri.parse('$baseUrl/instructor-files/move'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          "id": id,
          "type": type,
          "target_folder_id": targetFolderId
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to move $type');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> duplicateEntry(String id, String type, String? targetFolderId, {String? newName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/instructor-files/duplicate'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({
          "id": id,
          "type": type,
          "target_folder_id": targetFolderId,
          "new_name": newName
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 201 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to duplicate $type');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getRecycleBin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/instructor-files/recycle-bin'),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load recycle bin');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> restoreEntry(String id, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.patch(
        Uri.parse('$baseUrl/instructor-files/restore'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"id": id, "type": type}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to restore $type');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> permanentlyDeleteEntry(String id, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.delete(
        Uri.parse('$baseUrl/instructor-files/permanent/$type/$id'),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to permanently delete $type');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.patch(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(profileData),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // Update local storage with new data
        final updated = data['data'];
        if (updated['title'] != null) await prefs.setString('title', updated['title']);
        if (updated['first_name'] != null) await prefs.setString('first_name', updated['first_name']);
        if (updated['middle_name'] != null) await prefs.setString('middle_name', updated['middle_name']);
        if (updated['last_name'] != null) await prefs.setString('last_name', updated['last_name']);
        if (updated['email'] != null) await prefs.setString('email', updated['email']);
        
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }
  Future<List<dynamic>> getCalendars() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/calendars'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load calendars');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getMySchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/schedules/my-schedule'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load schedules');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getSystemMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/system-messages/my-messages'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load system messages');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<bool> isFileDownloaded(String filePath, {String? fileName}) async {
    if (filePath.isEmpty) return false;
    try {
      Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download/ELMS');
      } else {
        dir = Directory('${(await getApplicationDocumentsDirectory()).path}/ELMS');
      }
      
      String finalFileName = fileName ?? filePath.split('/').last;
      if (!finalFileName.contains('.') && filePath.contains('.')) {
        final ext = filePath.split('.').last;
        finalFileName = "$finalFileName.$ext";
      }
      
      if (finalFileName.isEmpty || !finalFileName.contains('.')) return false;
      final file = File('${dir.path}/$finalFileName');
      return await file.exists();
    } catch (_) {
      return false;
    }
  }


  Future<void> downloadAndOpenFile(String filePath, {BuildContext? context, String? fileName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Normalize backslashes (common in Windows paths from backend)
      String normalizedPath = filePath.replaceAll('\\', '/');
      
      String url;
      if (normalizedPath.startsWith('http')) {
        url = normalizedPath;
      } else {
        String cleanBaseUrl = baseUrl.replaceAll('/api', '');
        
        // Handle cases where the path might contain an absolute Windows path (C:\...)
        if (normalizedPath.contains(':/')) {
          int uploadsIdx = normalizedPath.indexOf('/uploads/');
          if (uploadsIdx != -1) {
            normalizedPath = normalizedPath.substring(uploadsIdx);
          }
        }

        // Ensure proper slash formatting between base and path
        if (!normalizedPath.startsWith('/') && !cleanBaseUrl.endsWith('/')) {
          url = '$cleanBaseUrl/$normalizedPath';
        } else if (normalizedPath.startsWith('/') && cleanBaseUrl.endsWith('/')) {
           url = cleanBaseUrl + normalizedPath.substring(1);
        } else {
          url = '$cleanBaseUrl$normalizedPath';
        }
      }
      
      final response = await http.get(
        Uri.parse(Uri.encodeFull(url)),
        headers: token != null ? {"Authorization": "Bearer $token"} : {},
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        Directory dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download/ELMS');
        } else {
          dir = Directory('${(await getApplicationDocumentsDirectory()).path}/ELMS');
        }
        
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        
        String finalFileName = fileName ?? filePath.split('/').last;
        // Ensure extension is preserved if missing from fileName but present in filePath
        if (!finalFileName.contains('.') && filePath.contains('.')) {
          final ext = filePath.split('.').last;
          finalFileName = "$finalFileName.$ext";
        }

        if (finalFileName.isEmpty || !finalFileName.contains('.')) {
          finalFileName = "file_${DateTime.now().millisecondsSinceEpoch}.bin";
        }
        
        final File file = File('${dir.path}/$finalFileName');
        await file.writeAsBytes(response.bodyBytes);
        
        if (context != null && ['txt', 'docx', 'pptx', 'xlsx', 'doc', 'ppt', 'xls', 'pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(finalFileName.split('.').last.toLowerCase())) {
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FileViewerScreen(filePath: file.path, fileName: finalFileName)
            ),
          );
        } else {
          final result = await OpenFilex.open(file.path);
          if (result.type != ResultType.done) {
            throw Exception(result.message);
          }
        }
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Could not open file: $e");
    }
  }
  // === Notification Methods ===

  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/settings'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load settings');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateNotificationSettings(Map<String, bool> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/settings'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(settings),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to update settings');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to mark notification as read');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, int>> getUnreadNotificationCounts() async {
    try {
      // Count unread push-notifications by type.
      // NOTE: 'system' typed push-notifications are intentionally skipped here
      // because admin broadcast messages are already counted exclusively via
      // _getUnseenSystemMessageCount() below. Counting them in both places
      // caused every admin message to appear twice in the badge count.
      final notifications = await getNotifications();
      final counts = <String, int>{
        'chat': 0,
        'announcement': 0,
        'material': 0,
        'task': 0,
        'system': 0,
        'total': 0,
      };
      for (final n in notifications) {
        if (n['is_read'] == true) continue;
        final type = (n['type'] ?? '').toString();
        // Skip 'system' push-notifications — they duplicate the system_messages table count
        if (type == 'system') continue;
        counts['total'] = (counts['total'] ?? 0) + 1;
        if (type == 'chat') {
          counts['chat'] = (counts['chat'] ?? 0) + 1;
        } else if (type == 'announcement') {
          counts['announcement'] = (counts['announcement'] ?? 0) + 1;
        } else if (type == 'material' || type == 'task') {
          counts['material'] = (counts['material'] ?? 0) + 1;
        }
      }

      // Count unseen admin system-broadcast messages (the sole source of 'system' badge count)
      final systemMsgCount = await _getUnseenSystemMessageCount();
      counts['system'] = systemMsgCount;
      counts['total'] = (counts['total'] ?? 0) + systemMsgCount;

      return counts;
    } catch (e) {
      return {'chat': 0, 'announcement': 0, 'material': 0, 'system': 0, 'total': 0};
    }
  }


  /// Returns how many admin system-broadcast messages the user has NOT yet opened.
  /// Uses the same SharedPreferences key as SystemNotificationsScreen so they stay in sync.
  static const _openedIdsKey = 'system_notifications_opened_ids';

  Future<int> _getUnseenSystemMessageCount() async {
    try {
      final messages = await getSystemMessages();
      final prefs = await SharedPreferences.getInstance();
      final openedIds = (prefs.getStringList(_openedIdsKey) ?? []).toSet();
      int unseen = 0;
      for (final m in messages) {
        final id = m['id']?.toString() ?? m['created_at']?.toString() ?? '';
        if (!openedIds.contains(id)) unseen++;
      }
      return unseen;
    } catch (_) {
      return 0;
    }
  }

  /// Marks ALL system-broadcast messages as opened, clearing the badge.
  Future<void> markSystemMessagesSeen() async {
    try {
      final messages = await getSystemMessages();
      final prefs = await SharedPreferences.getInstance();
      final ids = messages
          .map((m) => m['id']?.toString() ?? m['created_at']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      final existing = (prefs.getStringList(_openedIdsKey) ?? []).toSet();
      existing.addAll(ids);
      await prefs.setStringList(_openedIdsKey, existing.toList());
    } catch (_) {}
  }


  // ========================
  // Support Tickets
  // ========================

  Future<Map<String, dynamic>> createSupportTicket(String subject, String description, {String priority = 'Medium'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/tickets'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"subject": subject, "description": description, "priority": priority}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to create ticket');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<List<dynamic>> getMySupportTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/tickets/my-tickets'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load tickets');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  // ========================
  // Enrollments
  // ========================

  Future<List<dynamic>> getEnrollmentsByCourse(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/enrollments/course/$courseId'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load enrollments');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> enrollStudent(String courseId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/enrollments'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"course_id": courseId, "user_id": userId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to enroll student');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> updateAssignment(String id, Map<String, dynamic> updates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.put(
        Uri.parse('$baseUrl/assignments/$id'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode(updates),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to update assignment');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> deleteAssignment(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.delete(
        Uri.parse('$baseUrl/assignments/$id'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete assignment');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  // ========================
  // Attendance
  // ========================

  Future<Map<String, dynamic>> createAttendanceSession(String courseId, String title, String sessionDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/sessions'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"course_id": courseId, "title": title, "session_date": sessionDate}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to create session');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<List<dynamic>> getAttendanceSessions(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/attendance/course/$courseId/sessions'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load sessions');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> getAttendanceSessionDetail(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/attendance/sessions/$sessionId'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load session');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> markAttendance(String sessionId, List<Map<String, String>> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.put(
        Uri.parse('$baseUrl/attendance/sessions/$sessionId/mark'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"records": records}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to mark attendance');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ========================
  // Document Conversion
  // ========================

  Future<Map<String, dynamic>> convertTextToPdf(String title, String content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/convert/text-to-pdf'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"title": title, "content": content}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Conversion failed');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ========================
  // Quizzes
  // ========================

  Future<Map<String, dynamic>> createQuiz(Map<String, dynamic> quizData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/quizzes'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode(quizData),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to create quiz');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> addQuizQuestion(String quizId, Map<String, dynamic> questionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/quizzes/$quizId/questions'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode(questionData),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to add question');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> publishQuiz(String quizId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.put(
        Uri.parse('$baseUrl/quizzes/$quizId/publish'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to publish quiz');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<List<dynamic>> getQuizzesByCourse(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/quizzes/course/$courseId'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load quizzes');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> getQuizDetail(String quizId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/quizzes/$quizId'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load quiz');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> startQuizAttempt(String quizId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/quizzes/$quizId/start'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if ((response.statusCode == 201 || response.statusCode == 200) && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to start quiz');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> submitQuizAttempt(String attemptId, List<Map<String, dynamic>> answers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/quizzes/attempts/$attemptId/submit'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"answers": answers}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to submit quiz');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ========================
  // Analytics
  // ========================

  Future<Map<String, dynamic>> getStudentAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/analytics/student/overview'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load analytics');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> getInstructorAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/analytics/instructor/overview'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load analytics');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> getCourseAnalytics(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/analytics/instructor/course/$courseId'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load course analytics');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  // ========================
  // Course Goals
  // ========================
  Future<List<dynamic>> getCourseGoals(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/goals/$courseId'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data; 
      } else {
        throw Exception(data['message'] ?? 'Failed to load goals');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<Map<String, dynamic>> createCourseGoal(String courseId, Map<String, dynamic> goalData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.post(
        Uri.parse('$baseUrl/goals/$courseId'),
        headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
        body: jsonEncode(goalData)
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to create goal');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }
  Future<Map<String, dynamic>> updateCourseGoal(String goalId, Map<String, dynamic> goalData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.put(
        Uri.parse('$baseUrl/goals/$goalId'),
        headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
        body: jsonEncode(goalData)
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update goal');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<List<dynamic>> getMyGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("You are not logged in");

      final response = await http.get(
        Uri.parse('$baseUrl/goals/student/my-goals'),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data; 
      } else {
        throw Exception(data['message'] ?? 'Failed to load goals');
      }
    } catch (e) {
      throw Exception('Server Error: $e');
    }
  }

  Future<void> logReadingDuration(String courseId, String materialId, int durationSeconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      await http.post(
        Uri.parse('$baseUrl/goals/log-reading'),
        headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
        body: jsonEncode({
          "courseId": courseId,
          "materialId": materialId,
          "durationSeconds": durationSeconds
        })
      );
    } catch (e) {
      print("Failed to log reading duration: $e");
    }
  }

  Future<int> getStudentStarCount() async {
    final token = await _getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/goals/student/star-count'),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['total_stars'] ?? 0;
      }
    } catch (e) {
      print("Error fetching stars: $e");
    }
    return 0;
  }

  Future<void> saveRecentlyOpenedMaterial(Map<String, dynamic> material) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recently_opened_material', jsonEncode(material));
    } catch (e) {
      debugPrint("Error saving recently opened material: $e");
    }
  }

  Future<Map<String, dynamic>?> getRecentlyOpenedMaterial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('recently_opened_material');
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("Error getting recently opened material: $e");
    }
    return null;
  }
}

