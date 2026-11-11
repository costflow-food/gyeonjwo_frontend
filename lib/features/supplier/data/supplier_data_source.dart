import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/network/authorized_json_get.dart";
import "../../auth/data/auth_session_data_source.dart";

part "supplier_data_source.g.dart";

@Riverpod(keepAlive: true)
SupplierDataSource supplierDataSource(Ref ref) => ApiSupplierDataSource(
  ref.watch(apiClientProvider),
  ref.watch(authSessionDataSourceProvider).freshAccessToken,
);

/// Returns decoded JSON in the 08 API shape (`data`, `meta`).
///
/// Reads: API-29 `GET /suppliers`, API-30 `GET /suppliers/{supplier_id}`,
/// API-31 `GET /supplier-items/{supplier_item_id}/price-history`.
/// Create: 08에 없는 계약입니다(거래처 CRUD는 Must 밖). 서버 지원이 합의되기
/// 전에는 [ApiSupplierDataSource]가 요청을 보내지 않고 거절합니다.
/// Failures use the 08 error shape via [SupplierApiException].
abstract interface class SupplierDataSource {
  Future<Map<String, dynamic>> fetchSuppliers({
    required String query,
    String? cursor,
    int limit = 25,
  });

  Future<Map<String, dynamic>> fetchSupplier(String supplierId);

  Future<Map<String, dynamic>> fetchPriceHistory(String supplierItemId);

  Future<Map<String, dynamic>> createSupplier(
    Map<String, Object?> body, {
    required String idempotencyKey,
  });
}

class SupplierApiException implements Exception {
  const SupplierApiException(this.statusCode, this.body);
  final int statusCode;
  final Map<String, dynamic> body;
}

class ApiSupplierDataSource implements SupplierDataSource {
  const ApiSupplierDataSource(this._dio, this._accessToken);

  static const _suppliers = "/api/v1/suppliers";
  static const _supplierItems = "/api/v1/supplier-items";

  final Dio _dio;
  final ApiTokenReader _accessToken;

  @override
  Future<Map<String, dynamic>> fetchSuppliers({
    required String query,
    String? cursor,
    int limit = 25,
  }) => _get(
    _suppliers,
    queryParameters: {
      if (query.isNotEmpty) "q": query,
      "cursor": ?cursor,
      "limit": limit,
    },
  );

  @override
  Future<Map<String, dynamic>> fetchSupplier(String supplierId) =>
      _get("$_suppliers/${Uri.encodeComponent(supplierId)}");

  @override
  Future<Map<String, dynamic>> fetchPriceHistory(String supplierItemId) => _get(
    "$_supplierItems/${Uri.encodeComponent(supplierItemId)}/price-history",
  );

  /// `POST /suppliers`는 08에 없어 서버에 보내지 않습니다.
  @override
  Future<Map<String, dynamic>> createSupplier(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) async {
    throw const SupplierApiException(501, {
      "error": {
        "code": "SUPPLIER_REGISTRATION_UNSUPPORTED",
        "message": "거래처 등록은 아직 서버에서 지원하지 않습니다.",
      },
    });
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    try {
      return await authorizedJsonGet(
        _dio,
        _accessToken,
        path,
        queryParameters: queryParameters,
      );
    } on ApiReadException catch (error) {
      throw SupplierApiException(error.statusCode, error.body);
    }
  }
}
