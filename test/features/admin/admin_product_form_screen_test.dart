import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/data/daos/product_dao.dart';
import 'package:smashly/data/repositories/product_repository.dart';
import 'package:smashly/features/admin/admin_product_form_screen.dart';
import 'package:smashly/shared/widgets/buttons/primary_button.dart';
import 'package:smashly/shared/widgets/inputs/app_text_field.dart';
import 'package:smashly/providers/admin_product_form_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// S15: validate, nhóm thông số vợt theo danh mục, hỏi lại khi rời màn,
/// lưu thành công thì quay về và có dòng mới trong DB.
void main() {
  late Database db;

  setUpAll(sqfliteFfiInit);

  tearDown(() => db.close());

  /// Cho các câu SQL (chạy thật trên ffi) kịp xong rồi vẽ lại màn.
  Future<void> waitForDb(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  /// Mở Form từ một màn giả; trả về hàm đọc kết quả `pop` của Form.
  Future<Object? Function()> pumpForm(
    WidgetTester tester, {
    int? productId,
  }) async {
    await tester.runAsync(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: DbSchema.version,
          onConfigure: DatabaseHelper.onConfigure,
          onCreate: DatabaseHelper.onCreate,
        ),
      );
    });
    final repository = ProductRepository(
      database: () async => db,
      productDao: const ProductDao(),
    );

    // Màn cao để không phải cuộn tới các ô ở dưới.
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    Object? popResult;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                popResult = await Navigator.of(context).push<Object?>(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => AdminProductFormProvider(
                        repository,
                        productId: productId,
                      ),
                      child: const AdminProductFormScreen(),
                    ),
                  ),
                );
              },
              child: const Text('Mở form'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở form'));
    await tester.pump();
    await waitForDb(tester);
    return () => popResult;
  }

  Finder field(String label) => find.widgetWithText(AppTextField, label);

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    await waitForDb(tester);
  }

  Future<void> selectCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('thêm mới: bấm Lưu khi trống thì báo lỗi từng ô', (
    tester,
  ) async {
    await pumpForm(tester);

    await tapSave(tester);

    expect(find.text('Vui lòng chọn ảnh sản phẩm'), findsOneWidget);
    expect(find.text('Vui lòng nhập tên sản phẩm'), findsOneWidget);
    expect(find.text('Vui lòng nhập thương hiệu'), findsOneWidget);
    expect(find.text('Vui lòng chọn danh mục'), findsOneWidget);
    expect(find.text('Vui lòng nhập giá bán'), findsOneWidget);
    expect(find.text('Vui lòng nhập tồn kho'), findsOneWidget);
    expect(find.byType(AdminProductFormScreen), findsOneWidget);
  });

  testWidgets('giá = 0 và giá gốc không lớn hơn giá bán thì báo lỗi', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(field('Giá bán (đ)'), '0');
    await tester.enterText(field('Giá gốc (tùy chọn)'), '500000');
    await tapSave(tester);
    expect(find.text('Giá bán phải lớn hơn 0'), findsOneWidget);

    await tester.enterText(field('Giá bán (đ)'), '900000');
    await tapSave(tester);
    expect(find.text('Giá gốc phải lớn hơn giá bán'), findsOneWidget);
  });

  testWidgets('sửa vợt: điền sẵn dữ liệu, đổi sang Giày thì ẩn thông số vợt', (
    tester,
  ) async {
    await pumpForm(tester, productId: 1);

    expect(find.text('Sửa sản phẩm'), findsOneWidget);
    expect(find.text('Yonex Astrox 99 Pro'), findsOneWidget);
    expect(find.text('Thông số vợt'), findsOneWidget);

    await selectCategory(tester, 'Giày');

    expect(find.text('Thông số vợt'), findsNothing);
    expect(
      find.text(
        'Sản phẩm không còn là vợt: thông số vợt cũ sẽ bị xóa khi lưu.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('rời màn khi có thay đổi chưa lưu thì hỏi lại', (tester) async {
    await pumpForm(tester);
    await tester.enterText(field('Tên sản phẩm'), 'Vợt nháp');
    await tester.pump();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi?'), findsOneWidget);

    await tester.tap(find.text('Ở lại'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminProductFormScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ thay đổi'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminProductFormScreen), findsNothing);
  });

  testWidgets('chưa sửa gì thì Back rời màn ngay, không hỏi', (tester) async {
    await pumpForm(tester, productId: 1);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Bỏ thay đổi?'), findsNothing);
    expect(find.byType(AdminProductFormScreen), findsNothing);
  });

  testWidgets('thêm giày hợp lệ: lưu vào DB, báo thành công và quay về', (
    tester,
  ) async {
    final popResult = await pumpForm(tester);
    const imagePath = 'assets/images/products/shoes/shoe_yonex_65z3.png';

    // Chọn ảnh trong bottom sheet.
    await tester.tap(find.text('Chạm để chọn ảnh'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == imagePath,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(field('Tên sản phẩm'), 'Giày UC18');
    await tester.enterText(field('Thương hiệu'), 'Yonex');
    await selectCategory(tester, 'Giày');
    await tester.enterText(field('Giá bán (đ)'), '1990000');
    await tester.enterText(field('Tồn kho'), '0');
    await tester.enterText(field('Sizes (tùy chọn)'), ' 40, 41,,42 ');
    await tapSave(tester);

    expect(find.byType(AdminProductFormScreen), findsNothing);
    expect(find.text('Đã lưu sản phẩm'), findsOneWidget);
    expect(popResult(), isTrue);

    final rows = await tester.runAsync(
      () => db.query(
        DbSchema.products,
        where: 'name = ?',
        whereArgs: ['Giày UC18'],
      ),
    );
    final row = rows!.single;
    expect(row['price'], 1990000);
    expect(row['stock'], 0);
    expect(row['image_path'], imagePath);
    expect(row['sizes'], '40,41,42');
    expect(row['is_active'], 1);
  });
}
