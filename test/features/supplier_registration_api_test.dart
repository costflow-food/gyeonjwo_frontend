import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/supplier/data/supplier_data_source.dart";
import "package:gyeonjwo_frontend/features/supplier/data/supplier_repository_impl.dart";
import "package:gyeonjwo_frontend/features/supplier/domain/supplier.dart";

void main() {
  test(
    "registration sends the supported contract and reads the 201 summary",
    () async {
      final dio = Dio(BaseOptions(baseUrl: "https://dev.example.invalid"));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.method, "POST");
            expect(request.path, "/api/v1/suppliers");
            expect(request.headers["Authorization"], "Bearer test-token");
            expect(request.data, {
              "name": "테스트 업체",
              "contact_email": null,
              "contact_name": "담당자",
              "contact_phone": null,
              "location": null,
              "item_names": ["냉동 망고"],
            });
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 201,
                data: {
                  "data": {
                    "supplier_id": "test-id",
                    "name": "테스트 업체",
                    "source_type": "REGISTERED",
                    "item_names": ["냉동 망고"],
                  },
                },
              ),
            );
          },
        ),
      );
      final repo = SupplierRepositoryImpl(
        ApiSupplierDataSource(
          dio,
          ({bool forceRefresh = false}) async => "test-token",
        ),
      );
      final supplier = await repo.registerSupplier(
        const SupplierDraft(
          name: "테스트 업체",
          contactName: "담당자",
          items: [SupplierItemDraft(itemName: "냉동 망고")],
        ),
      );
      expect(supplier.id, "test-id");
    },
  );
}
