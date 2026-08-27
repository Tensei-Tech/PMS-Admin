import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _envBaseUrl = String.fromEnvironment('ADMIN_API_BASE_URL', defaultValue: 'http://127.0.0.1:8001/api/admin');
  static String baseUrl = _envBaseUrl;

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Authenticate user credentials against Django PostgreSQL backend
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: headers,
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Invalid credentials');
    }
  }

  /// Fetch Admin Dashboard metrics from Django PostgreSQL backend
  static Future<Map<String, dynamic>> fetchDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats/'),
        headers: headers,
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
      final response = await http.get(uri, headers: headers);
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
      final response = await http.post(
        Uri.parse('$baseUrl/officers/$uid/status/'),
        headers: headers,
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
      final response = await http.get(Uri.parse('$baseUrl/stations/'), headers: headers);
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
      final response = await http.get(Uri.parse('$baseUrl/states/'), headers: headers);
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
      final response = await http.get(Uri.parse('$baseUrl/states/available/'), headers: headers);
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
    required String superAdminName,
    required String superAdminEmail,
    required String superAdminPhone,
    required String superAdminRank,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/states/'),
      headers: headers,
      body: json.encode({
        'state_code': stateCode,
        'state_name': stateName,
        'police_force_title': policeForceTitle,
        'super_admin_name': superAdminName,
        'super_admin_email': superAdminEmail,
        'super_admin_phone': superAdminPhone,
        'super_admin_rank': superAdminRank,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to onboard state');
    }
  }
}
