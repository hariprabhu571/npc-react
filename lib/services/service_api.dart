import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


import '../Urls.dart';
import '../models/service_type_model.dart';

class ApiResult<T> {
  final bool isSuccess;
  final String? errorMessage;
  final T? data;

  ApiResult({
    required this.isSuccess,
    this.errorMessage,
    this.data,
  });

  factory ApiResult.success(T data) {
    return ApiResult(isSuccess: true, data: data);
  }

  factory ApiResult.error(String message) {
    return ApiResult(isSuccess: false, errorMessage: message);
  }
}

class ServiceApi {
  Future<String?> _getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("Session-ID");
  }

  Future<ApiResult<List<ServiceTypeData>>> fetchServiceDetails(String serviceName) async {
    try {
      final sessionId = await _getSessionId();
      if (sessionId == null) {
        return ApiResult.error("Session ID not found. Please login again.");
      }

      final response = await http.get(
        Uri.parse('$ip/get_service_details.php?service_name=$serviceName'),
        headers: {
          'Session-ID': sessionId,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          final List<dynamic> serviceData = responseData['data'];

          // Convert the data to our model objects
          List<ServiceTypeData> types = serviceData
              .map((data) => ServiceTypeData.fromJson(data))
              .toList();

          return ApiResult.success(types);
        } else {
          return ApiResult.error(responseData['message'] ?? "Unknown error");
        }
      } else {
        return ApiResult.error("Failed to fetch service data: ${response.statusCode}");
      }
    } catch (e) {
      return ApiResult.error("Error: $e");
    }
  }

  Future<ApiResult<bool>> addServiceType(
      String serviceName,
      String serviceTypeName,
      List<PricingField> pricingFields
      ) async {
    try {
      final sessionId = await _getSessionId();
      if (sessionId == null) {
        return ApiResult.error("Session ID not found. Please login again.");
      }

      final Map<String, dynamic> requestBody = {
        "service_name": serviceName,
        "service_type_name": serviceTypeName,
        "pricing": pricingFields.map((field) => {
          "room_size": field.roomSize,
          "price": field.price
        }).toList()
      };

      final response = await http.post(
        Uri.parse('$ip/add_service_type.php'),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': sessionId,
        },
        body: jsonEncode(requestBody),
      );
      print(response);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          return ApiResult.success(true);
        } else {
          return ApiResult.error(responseData['message'] ?? "Failed to add service type");
        }
      } else {
        return ApiResult.error("Server error: ${response.statusCode}");
      }
    } catch (e) {
      return ApiResult.error("Error: $e");
    }
  }

  Future<ApiResult<bool>> updateServiceTypeName(int serviceTypeId, String newName) async {
    try {
      final sessionId = await _getSessionId();
      if (sessionId == null) {
        return ApiResult.error("Session ID not found. Please login again.");
      }

      final Map<String, dynamic> requestBody = {
        "service_type_id": serviceTypeId,
        "service_type_name": newName,
      };

      final response = await http.post(
        Uri.parse('$ip/update_service_type.php'),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': sessionId,
        },
        body: jsonEncode(requestBody),
      );
  print(response);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          return ApiResult.success(true);
        } else {
          return ApiResult.error(responseData['message'] ?? "Failed to update service type");
        }
      } else {
        return ApiResult.error("Server error: ${response.statusCode}");
      }
    } catch (e) {
      return ApiResult.error("Error: $e");
    }
  }

  Future<ApiResult<bool>> deleteServiceType(String serviceTypeId) async {
    try {
      final sessionId = await _getSessionId();
      if (sessionId == null) {
        return ApiResult.error("Session ID not found. Please login again.");
      }

      final response = await http.post(
        Uri.parse('$ip/delete-service-type.php'),
        headers: {
          'Session-ID': sessionId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_type_id': serviceTypeId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          return ApiResult.success(true);
        } else {
          return ApiResult.error(responseData['message'] ?? "Unknown error");
        }
      } else {
        return ApiResult.error("Failed to delete service type: ${response.statusCode}");
      }
    } catch (e) {
      return ApiResult.error("Error: $e");
    }
  }

  Future<ApiResult<bool>> addPricingField(String service_name,String serviceTypeName, String roomSize, String price) async {
    try {
      final sessionId = await _getSessionId();
      if (sessionId == null) {
        return ApiResult.error("Session ID not found. Please login again.");
      }

      final Map<String, dynamic> requestBody = {
        "service_name":service_name,
        "service_type_name": serviceTypeName,
        "room_size": roomSize,
        "price": price,
      };
  print(requestBody);
      final response = await http.post(
        Uri.parse('$ip/add_pricing_field.php'),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': sessionId,
        },
        body: jsonEncode(requestBody),
      );
      print(response);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          return ApiResult.success(true);
        } else {
          return ApiResult.error(responseData['message'] ?? "Failed to add pricing field");
        }
      } else {
        return ApiResult.error("Server error: ${response.statusCode}");
      }
    } catch (e) {
      return ApiResult.error("Error: $e");
    }
  }

  Future<ApiResult<bool>> updatePricingField(int fieldId, String roomSize, String price) async {
    try {
      final sessionId = await _getSessionId();
      if (sessionId == null) {
        return ApiResult.error("Session ID not found. Please login again.");
      }

      final Map<String, dynamic> requestBody = {
        "pricing_field_id": fieldId,
        "room_size": roomSize,
        "price": price,
      };

      final response = await http.post(
        Uri.parse('$ip/update_pricing_field.php'),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': sessionId,
        },
        body: jsonEncode(requestBody),
      );
      print(response);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          return ApiResult.success(true);
        } else {
          return ApiResult.error(responseData['message'] ?? "Failed to update pricing field");
        }
      } else {
        return ApiResult.error("Server error: ${response.statusCode}");
      }
    } catch (e) {
      return ApiResult.error("Error: $e");
    }
  }

  // In your service API class
  Future<ApiResult<bool>> deletePricingField(String fieldId) async {
    try {
      final sessionId = await _getSessionId();
      if (sessionId == null) {
        return ApiResult.error("Session ID not found. Please login again.");
      }

      final response = await http.post(
        Uri.parse('$ip/delete-pricing-field.php'),
        headers: {
          'Session-ID': sessionId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_type_id': fieldId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          return ApiResult.success(true);
        } else {
          return ApiResult.error(responseData['message'] ?? "Unknown error");
        }
      } else if (response.statusCode == 404) {
        return ApiResult.error("Pricing field not found");
      } else {
        return ApiResult.error("Failed to delete pricing field: ${response.statusCode}");
      }
    } catch (e) {
      return ApiResult.error("Error: $e");
    }
  }

// In your UI/controller class

}