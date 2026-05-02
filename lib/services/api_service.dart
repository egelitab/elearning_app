import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ApiService {
  
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:5000/api";
    try {
      if (Platform.isAndroid) return "http://10.0.2.2:5000/api";
    } catch (_) {}
    return "http://localhost:5000/api";
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

  Future<void> downloadAndOpenFile(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      String cleanBaseUrl = baseUrl.replaceAll('/api', '');
      String url = '$cleanBaseUrl$filePath';
      
      final response = await http.get(
        Uri.parse(Uri.encodeFull(url)),
        headers: token != null ? {"Authorization": "Bearer $token"} : {},
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        
        String fileName = filePath.split('/').last;
        if (fileName.isEmpty || !fileName.contains('.')) {
          fileName = "file_${DateTime.now().millisecondsSinceEpoch}.bin";
        }
        
        final File file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        
        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done) {
          throw Exception(result.message);
        }
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Could not open file: $e");
    }
  }
}


