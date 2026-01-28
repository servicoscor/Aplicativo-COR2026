import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../errors/app_exception.dart';

/// Cliente HTTP centralizado usando Dio
class ApiClient {
  late final Dio _dio;
  final Ref _ref;

  ApiClient(this._ref) {
    _dio = Dio();
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Adiciona BASE_URL dinamicamente
          final baseUrl = _ref.read(baseUrlProvider);
          options.baseUrl = baseUrl;

          // Timeout
          options.connectTimeout = const Duration(seconds: 10);
          options.receiveTimeout = const Duration(seconds: 30);

          // Headers padrão
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';

          if (kDebugMode) {
            print('🌐 REQUEST: ${options.method} ${options.baseUrl}${options.path}');
            if (options.data != null) {
              print('📦 BODY: ${options.data}');
            }
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('✅ RESPONSE [${response.statusCode}]: ${response.requestOptions.path}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('❌ ERROR [${error.response?.statusCode}]: ${error.requestOptions.path}');
            print('   Message: ${error.message}');
          }
          handler.next(error);
        },
      ),
    );
  }

  /// GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST request
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT request
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE request
  Future<T> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Trata erros do Dio e converte para AppException
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Tempo de conexão esgotado. Verifique sua internet.',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          'Sem conexão com o servidor. Verifique se a API está rodando.',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final data = error.response?.data;
        String message = 'Erro no servidor';

        if (data is Map && data.containsKey('detail')) {
          message = data['detail'].toString();
        }

        if (statusCode == 404) {
          return NotFoundException(message, originalError: error);
        }
        if (statusCode == 401 || statusCode == 403) {
          return UnauthorizedException(message, originalError: error);
        }
        if (statusCode == 422) {
          return ValidationException(message, originalError: error);
        }
        if (statusCode >= 500) {
          return ServerException(message, originalError: error);
        }

        return ApiException(message, statusCode: statusCode, originalError: error);

      case DioExceptionType.cancel:
        return AppException('Requisição cancelada', originalError: error);

      default:
        return NetworkException(
          'Erro de conexão: ${error.message}',
          originalError: error,
        );
    }
  }
}

/// Provider para o ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});
