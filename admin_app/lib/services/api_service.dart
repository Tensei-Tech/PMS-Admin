import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'secure_storage.dart';

class ApiService {
  static const String _envBaseUrl = String.fromEnvironment(
    'ADMIN_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8001/api/admin',
  );
  static const String _tokenKey = 'admin_jwt_access_token';

  /// Base API URL with production HTTPS enforcement
  static String get baseUrl {
    String url = _envBaseUrl;
    if (kReleaseMode &&
        url.startsWith('http://') &&
        !url.contains('127.0.0.1') &&
        !url.contains('localhost')) {
      url = url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  /// Synchronous headers fallback
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Build request headers with secure JWT auth token from Android Keystore / iOS Keychain
  static Future<Map<String, String>> getSecureHeaders() async {
    final reqHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      final token = await SecureStorage.instance.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        reqHeaders['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
    return reqHeaders;
  }

  /// Store administrative JWT token securely
  static Future<void> saveToken(String token) async {
    await SecureStorage.instance.write(key: _tokenKey, value: token);
  }

  /// Clear administrative JWT token
  static Future<void> clearToken() async {
    await SecureStorage.instance.delete(key: _tokenKey);
  }

  /// Authenticate user credentials against Django PostgreSQL backend
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final reqHeaders = await getSecureHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: reqHeaders,
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data.containsKey('access_token')) {
        await saveToken(data['access_token'].toString());
      } else if (data.containsKey('access')) {
        await saveToken(data['access'].toString());
      }
      return data;
    } else {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Invalid credentials');
    }
  }

  /// Fetch Admin Dashboard metrics from Django PostgreSQL backend
  static Future<Map<String, dynamic>> fetchDashboardStats() async {
    try {
      final reqHeaders = await getSecureHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stats/'),
        headers: reqHeaders,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // Fallback or local log
    }
    return {};
  }

  /// Fetch Officer list from backend
  static Future<List<dynamic>> fetchOfficers({String? status, String? district}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (district != null) queryParams['district'] = district;

      final uri = Uri.parse('$baseUrl/officers/').replace(queryParameters: queryParams);
      final reqHeaders = await getSecureHeaders();
      final response = await http.get(uri, headers: reqHeaders);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('results')) return data['results'] as List;
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  /// Fetch dynamic Police Designation Master allowed for a specific role/admin level from DB
  static Future<List<dynamic>> fetchDesignations({String? role}) async {
    try {
      final queryParams = <String, String>{};
      if (role != null) queryParams['role'] = role;

      final uri = Uri.parse('$baseUrl/designations/').replace(queryParameters: queryParams);
      final reqHeaders = await getSecureHeaders();
      final response = await http.get(uri, headers: reqHeaders);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('results')) return data['results'] as List;
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  /// Update Officer account status (Active, Archived, Pending Approval, Rejected)
  static Future<bool> updateOfficerStatus(String uid, String status, {String? roleId}) async {
    try {
      final reqHeaders = await getSecureHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/officers/$uid/status/'),
        headers: reqHeaders,
        body: json.encode({
          'account_status': status,
          if (roleId != null) 'role_id': roleId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch Police Stations list
  static Future<List<dynamic>> fetchStations() async {
    try {
      final reqHeaders = await getSecureHeaders();
      final response = await http.get(Uri.parse('$baseUrl/stations/'), headers: reqHeaders);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('results')) return data['results'] as List;
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  /// Fetch provisioned state registries
  static Future<List<dynamic>> fetchStates() async {
    try {
      final reqHeaders = await getSecureHeaders();
      final response = await http.get(Uri.parse('$baseUrl/states/'), headers: reqHeaders);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) return data;
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  /// Fetch all 36 Indian States/UTs with availability status
  static Future<List<dynamic>> fetchAvailableStates() async {
    try {
      final reqHeaders = await getSecureHeaders();
      final response = await http.get(Uri.parse('$baseUrl/states/available/'), headers: reqHeaders);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) return data;
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  /// Onboard a new state with Super Admin details
  static Future<Map<String, dynamic>> createStateOnboarding({
    required String stateCode,
    required String stateName,
    required String policeForceTitle,
    String? departmentLogoUrl,
    required String superAdminName,
    required String superAdminEmail,
    required String superAdminPhone,
    required String superAdminRank,
    required String password,
    int? age,
    String? gender,
    String? photoUrl,
    String? idCardUrl,
  }) async {
    final reqHeaders = await getSecureHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/states/'),
      headers: reqHeaders,
      body: json.encode({
        'state_code': stateCode,
        'state_name': stateName,
        'police_force_title': policeForceTitle,
        if (departmentLogoUrl != null && departmentLogoUrl.isNotEmpty) 'department_logo_url': departmentLogoUrl,
        'super_admin_name': superAdminName,
        'super_admin_email': superAdminEmail,
        'super_admin_phone': superAdminPhone,
        'super_admin_rank': superAdminRank,
        'password': password,
        if (age != null) 'age': age,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
        if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
        if (idCardUrl != null && idCardUrl.isNotEmpty) 'id_card_url': idCardUrl,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to onboard state');
    }
  }

  static Future<List<dynamic>> fetchStateAdmins(String stateCode) async {
    final reqHeaders = await getSecureHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/states/$stateCode/admins/'),
      headers: reqHeaders,
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded;
      }
      return [];
    } else {
      try {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('error')) {
          throw Exception(data['error']);
        }
      } catch (_) {}
      throw Exception('Failed to fetch state admins for $stateCode (HTTP ${response.statusCode})');
    }
  }

  /// Add a new state admin officer to a state jurisdiction
  static Future<Map<String, dynamic>> addStateAdmin({
    required String stateCode,
    required String name,
    required String email,
    required String phone,
    required String designation,
    String? password,
    int? age,
    String? gender,
    String? photoUrl,
    String? idCardUrl,
  }) async {
    final reqHeaders = await getSecureHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/states/$stateCode/admins/'),
      headers: reqHeaders,
      body: json.encode({
        'name': name,
        'email': email,
        'phone': phone,
        'designation': designation,
        if (password != null && password.isNotEmpty) 'password': password,
        if (age != null) 'age': age,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
        if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
        if (idCardUrl != null && idCardUrl.isNotEmpty) 'id_card_url': idCardUrl,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to add state admin');
    }
  }

  /// Toggle state admin active/deactivated status
  static Future<Map<String, dynamic>> toggleStateAdminStatus({
    required String stateCode,
    required String uid,
  }) async {
    final reqHeaders = await getSecureHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/states/$stateCode/admins/$uid/toggle-status/'),
      headers: reqHeaders,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to toggle admin status');
    }
  }
}
