import 'package:sentry/sentry.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../keys.dart';

class AuthenticationProvider {
  static Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    try {
      Response response = await Dio().post('${Keys.BASE_URL}/users/login',
          data: {"email": email, "password": password},
          options: Options(responseType: ResponseType.json));
      return {
        "success": true,
        "token": response.data['token'],
        "user": response.data['user']
      };
    } on DioException catch (e) {
      await Sentry.captureException(e, stackTrace: e.stackTrace);
      if (e.response?.statusCode == 400) {
        return {"success": false, "error": "Invalid email or password"};
      }
      return {"success": false, "error": "Something went wrong"};
    }
  }

  static logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  static Future<Map<String, dynamic>> register(
      {required String username,
      required String email,
      required String password}) async {
    try {
      Response response = await Dio().post('${Keys.BASE_URL}/users/signup',
          data: {"username": username, "email": email, "password": password},
          options: Options(responseType: ResponseType.json));
      return {
        "success": true,
        "token": response.data['token'],
        "user": response.data['user']
      };
    } on DioException catch (e) {
      await Sentry.captureException(e, stackTrace: e.stackTrace);
      if (e.response?.statusCode == 400) {
        return {
          "success": false,
          "errors": e.response?.data['errors'][0]['email']
        };
      }
      return {"success": false};
    }
  }

  static updateUserData(Map<String, dynamic> userJson, String userToken) async {
    try {
      Response response = await Dio().put(
          '${Keys.BASE_URL}/users/${userJson["_id"]}/',
          data: userJson
            ..removeWhere((key, value) => key == '_id' || value == null),
          options: Options(
              headers: {"Authorization": "Bearer $userToken"},
              responseType: ResponseType.json));
      return {"success": true, "user": response.data['user']};
    } on DioException catch (e) {
      await Sentry.captureException(e, stackTrace: e.stackTrace);
      if (e.response?.statusCode == 400) {
        return {
          "success": false,
          "errors": e.response!.data['errors'][0]['email']
        };
      }
      return {"success": false};
    }
  }
}
