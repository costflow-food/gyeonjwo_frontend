import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/supplier/data/supplier_data_source.dart";
import "package:gyeonjwo_frontend/features/supplier/data/supplier_repository_impl.dart";
import "package:gyeonjwo_frontend/features/supplier/domain/supplier.dart";
import "package:gyeonjwo_frontend/features/supplier/domain/supplier_update.dart";

const _initial = SupplierDetail(
  id: "s1",
  name: "서산참농산",
  sourceType: SupplierSourceType.registered,
  contact: SupplierContact(name: "김담당"),
  contactEmail: "sales@example.invalid",
  location: "충남 서산",
  items: [
    SupplierItem(
      id: "i1",
      itemName: "깐마늘",
      unit: "kg",
      certifications: [
        Certification(name: "HACCP", status: CertificationStatus.confirmed),
      ],
    ),
    SupplierItem(id: "i2", itemName: "대파", certifications: []),
  ],
);

/// The draft the edit form makes when nothing was touched.
SupplierDraft _unchanged({
  String name = "서산참농산",
  String? contactEmail = "sales@example.invalid",
  String? contactName = "김담당",
  String? contactPhone,
  String? location = "충남 서산",
  List<SupplierItemDraft>? items,
}) => SupplierDraft(
  name: name,
  contactEmail: contactEmail,
  contactName: contactName,
  contactPhone: contactPhone,
  location: location,
  items:
      items ??
      const [
        SupplierItemDraft(
          supplierItemId: "i1",
          itemName: "깐마늘",
          unit: "kg",
          certifications: ["HACCP"],
        ),
        SupplierItemDraft(supplierItemId: "i2", itemName: "대파"),
      ],
);

void main() {
  test("no change makes an empty body", () {
    expect(SupplierUpdate.body(_initial, _unchanged()), isEmpty);
  });

  test("changed and cleared basic fields only; cleared becomes null", () {
    final body = SupplierUpdate.body(
      _initial,
      _unchanged(name: "서산참농산(주)", contactName: null, contactPhone: " "),
    );
    expect(body, {"name": "서산참농산(주)", "contact_name": null});
  });

  test("an edited saved item sends its id and the changed attributes", () {
    final body = SupplierUpdate.body(
      _initial,
      _unchanged(
        items: const [
          SupplierItemDraft(
            supplierItemId: "i1",
            itemName: "깐마늘",
            certifications: ["HACCP", "유기농"],
            unitsPerBox: "20",
          ),
          SupplierItemDraft(supplierItemId: "i2", itemName: "대파"),
        ],
      ),
    );
    expect(body, {
      "items": [
        {
          "supplier_item_id": "i1",
          "unit": null,
          "units_per_box": "20",
          "certifications": ["HACCP", "유기농"],
        },
      ],
    });
  });

  test("a new item is sent without an id and without blank fields", () {
    final body = SupplierUpdate.body(
      _initial,
      _unchanged(
        items: const [
          SupplierItemDraft(
            supplierItemId: "i1",
            itemName: "깐마늘",
            unit: "kg",
            certifications: ["HACCP"],
          ),
          SupplierItemDraft(supplierItemId: "i2", itemName: "대파"),
          SupplierItemDraft(itemName: "냉동 망고", origin: "베트남"),
        ],
      ),
    );
    expect(body, {
      "items": [
        {"item_name": "냉동 망고", "origin": "베트남"},
      ],
    });
  });

  test("update sends PATCH to the supplier and reads the detail", () async {
    final dio = Dio(BaseOptions(baseUrl: "https://dev.example.invalid"));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          expect(request.method, "PATCH");
          expect(request.path, "/api/v1/suppliers/s1");
          expect(request.headers["Authorization"], "Bearer test-token");
          expect(request.headers["Idempotency-Key"], isNotEmpty);
          expect(request.data, {"location": "충남 당진"});
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: {
                "data": {
                  "supplier_id": "s1",
                  "name": "서산참농산",
                  "source_type": "REGISTERED",
                  "location": "충남 당진",
                  "items": [],
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
    final supplier = await repo.updateSupplier("s1", {"location": "충남 당진"});
    expect(supplier.location, "충남 당진");
  });

  test("a 409 keeps the server code and message", () async {
    final dio = Dio(BaseOptions(baseUrl: "https://dev.example.invalid"));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) => handler.reject(
          DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: request,
              statusCode: 409,
              data: {
                "error": {
                  "code": "SUPPLIER_CANDIDATE_LOCKED",
                  "message": "진행 중인 업무의 후보에 올라 있어 바꿀 수 없습니다.",
                  "retryable": false,
                },
              },
            ),
          ),
        ),
      ),
    );
    final repo = SupplierRepositoryImpl(
      ApiSupplierDataSource(
        dio,
        ({bool forceRefresh = false}) async => "test-token",
      ),
    );
    await expectLater(
      repo.updateSupplier("s1", {"location": "충남 당진"}),
      throwsA(
        isA<SupplierFailure>()
            .having((f) => f.code, "code", "SUPPLIER_CANDIDATE_LOCKED")
            .having(
              (f) => f.message,
              "message",
              "진행 중인 업무의 후보에 올라 있어 바꿀 수 없습니다.",
            ),
      ),
    );
  });
}
