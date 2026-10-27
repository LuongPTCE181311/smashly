import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/core/utils/validators.dart';
import 'package:smashly/shared/widgets/inputs/app_text_field.dart';

const _emptyError = 'Email không được để trống';
const _formatError = 'Email không đúng định dạng';

final _emailField = find.widgetWithText(TextFormField, 'Email');
final _otherField = find.widgetWithText(TextFormField, 'Khác');

/// Form có ô Email (validator thật) và một ô khác để chuyển focus sang = rời ô Email.
Future<({GlobalKey<FormState> formKey, FocusNode emailFocus})> _pumpForm(
  WidgetTester tester,
) async {
  final formKey = GlobalKey<FormState>();
  final emailFocus = FocusNode();
  addTearDown(emailFocus.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Form(
          key: formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Email',
                focusNode: emailFocus,
                validator: validateEmail,
              ),
              const AppTextField(label: 'Khác'),
            ],
          ),
        ),
      ),
    ),
  );
  return (formKey: formKey, emailFocus: emailFocus);
}

void main() {
  testWidgets(
    '(a) ô chưa chạm, Form.validate() báo lỗi → gõ giá trị đúng → lỗi biến mất',
    (tester) async {
      final form = await _pumpForm(tester);

      // Bấm submit khi chưa chạm ô nào.
      expect(form.formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text(_emptyError), findsOneWidget);

      await tester.enterText(_emailField, 'a@b.co');
      await tester.pump();

      // Vẫn đang ở trong ô: lỗi phải mất nhờ validate theo từng ký tự, không phải nhờ rời ô.
      expect(form.emailFocus.hasFocus, isTrue);
      expect(find.text(_emptyError), findsNothing);
      expect(find.text(_formatError), findsNothing);
    },
  );

  testWidgets('(b) rời ô với giá trị sai → hiện lỗi', (tester) async {
    await _pumpForm(tester);

    await tester.enterText(_emailField, 'abc');
    await tester.pump();
    expect(find.text(_formatError), findsNothing);

    await tester.tap(_otherField);
    await tester.pump();
    expect(find.text(_formatError), findsOneWidget);
  });

  testWidgets(
    '(c) ô đang đúng, gõ thành sai nhưng chưa rời ô → chưa hiện lỗi; rời ô → hiện',
    (tester) async {
      final form = await _pumpForm(tester);

      await tester.enterText(_emailField, 'a@b.co');
      await tester.tap(_otherField);
      await tester.pump();
      expect(find.text(_formatError), findsNothing);

      await tester.tap(_emailField);
      await tester.enterText(_emailField, 'abc');
      await tester.pump();
      expect(form.emailFocus.hasFocus, isTrue);
      expect(find.text(_formatError), findsNothing);

      await tester.tap(_otherField);
      await tester.pump();
      expect(find.text(_formatError), findsOneWidget);
    },
  );

  testWidgets(
    '(d) rời ô với giá trị sai → hiện lỗi → quay lại gõ giá trị đúng → lỗi mất',
    (tester) async {
      final form = await _pumpForm(tester);

      await tester.enterText(_emailField, 'abc');
      await tester.tap(_otherField);
      await tester.pump();
      expect(find.text(_formatError), findsOneWidget);

      await tester.tap(_emailField);
      await tester.enterText(_emailField, 'a@b.co');
      await tester.pump();
      expect(form.emailFocus.hasFocus, isTrue);
      expect(find.text(_formatError), findsNothing);
      expect(find.text(_emptyError), findsNothing);
    },
  );
}
