import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/data/models/user.dart';
import 'package:smashly/features/auth/admin_guard.dart';
import 'package:smashly/providers/auth_provider.dart';
import 'package:smashly/routes/app_page_route.dart';
import 'package:smashly/routes/app_routes.dart';

import 'fake_auth_repository.dart';

const _baseRoute = '/test-base';
const _guardRoute = '/test-admin';
const _coverRoute = '/test-cover';
const _loginMarker = 'Login marker';
const _childMarker = 'Admin child';
const _admin = User(
  id: 1,
  fullName: 'Smashly Admin',
  email: 'admin@smashly.com',
  phone: '0900000000',
  role: UserRole.admin,
);
const _customer = User(
  id: 2,
  fullName: 'Smashly Customer',
  email: 'customer@smashly.com',
  phone: '0900000001',
  role: UserRole.customer,
);

class _CountingChild extends StatefulWidget {
  const _CountingChild({required this.onInit});

  final VoidCallback onInit;

  @override
  State<_CountingChild> createState() => _CountingChildState();
}

class _CountingChildState extends State<_CountingChild> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text(_childMarker));
}

class _RouteObserver extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  final removed = <Route<dynamic>>[];

  int get loginPushes =>
      pushed.where((route) => route.settings.name == AppRoutes.login).length;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    pushed.add(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    removed.add(route);
  }
}

Widget _app({
  required AuthProvider auth,
  required _RouteObserver observer,
  required VoidCallback onChildInit,
  String initialRoute = _baseRoute,
  ValueNotifier<int>? rebuilds,
}) {
  Route<dynamic> route(RouteSettings settings) => AppPageRoute<dynamic>(
    settings: settings,
    builder: (_) => switch (settings.name) {
      _baseRoute => const Scaffold(body: Text('Base marker')),
      _coverRoute => const Scaffold(body: Text('Cover marker')),
      AppRoutes.login => const Scaffold(body: Text(_loginMarker)),
      _guardRoute =>
        rebuilds == null
            ? AdminGuard(child: _CountingChild(onInit: onChildInit))
            : ValueListenableBuilder<int>(
                valueListenable: rebuilds,
                builder: (_, value, child) =>
                    AdminGuard(child: _CountingChild(onInit: onChildInit)),
              ),
      _ => throw StateError('Route không có trong bảng test: ${settings.name}'),
    },
  );

  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(
      navigatorObservers: [observer],
      onGenerateInitialRoutes: (_) => [
        route(RouteSettings(name: initialRoute)),
      ],
      onGenerateRoute: route,
    ),
  );
}

void main() {
  late FakeAuthRepository repo;
  late AuthProvider auth;
  late _RouteObserver observer;
  late int childBuilds;

  setUp(() {
    repo = FakeAuthRepository();
    auth = AuthProvider(repo);
    addTearDown(auth.dispose);
    observer = _RouteObserver();
    childBuilds = 0;
  });

  tearDown(() {
    expect(repo.unexpectedCalls, 0);
  });

  Future<void> loginAs(User user) async {
    repo.willLogin(user);
    expect(await auth.login(user.email, 'Password123'), same(user));
  }

  Future<NavigatorState> pumpApp(
    WidgetTester tester, {
    String initialRoute = _baseRoute,
    ValueNotifier<int>? rebuilds,
  }) async {
    await tester.pumpWidget(
      _app(
        auth: auth,
        observer: observer,
        onChildInit: () => childBuilds++,
        initialRoute: initialRoute,
        rebuilds: rebuilds,
      ),
    );
    return tester.state<NavigatorState>(find.byType(Navigator));
  }

  testWidgets('ADMIN hiển thị child', (tester) async {
    await loginAs(_admin);
    await pumpApp(tester, initialRoute: _guardRoute);
    await tester.pumpAndSettle();

    expect(find.text(_childMarker), findsOneWidget);
    expect(childBuilds, 1);
    expect(observer.loginPushes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chưa đăng nhập chuyển Login và xóa stack', (tester) async {
    final navigator = await pumpApp(tester);
    navigator.pushNamed<dynamic>(_guardRoute);
    await tester.pumpAndSettle();

    expect(find.text(_loginMarker), findsOneWidget);
    expect(childBuilds, 0);
    expect(find.byType(_CountingChild, skipOffstage: false), findsNothing);
    expect(navigator.canPop(), isFalse);
    expect(observer.loginPushes, 1);
    expect(
      observer.removed.map((route) => route.settings.name),
      unorderedEquals([_baseRoute, _guardRoute]),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guard là route đầu tiên chuyển Login mà không dựng child', (
    tester,
  ) async {
    final navigator = await pumpApp(tester, initialRoute: _guardRoute);
    await tester.pumpAndSettle();

    expect(find.text(_loginMarker), findsOneWidget);
    expect(childBuilds, 0);
    expect(navigator.canPop(), isFalse);
    expect(observer.loginPushes, 1);
    expect(observer.removed.map((route) => route.settings.name), [_guardRoute]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CUSTOMER chuyển Login và giữ nguyên user, không logout', (
    tester,
  ) async {
    await loginAs(_customer);
    final navigator = await pumpApp(tester);
    navigator.pushNamed<dynamic>(_guardRoute);
    await tester.pumpAndSettle();

    expect(find.text(_loginMarker), findsOneWidget);
    expect(childBuilds, 0);
    expect(find.byType(_CountingChild, skipOffstage: false), findsNothing);
    expect(observer.loginPushes, 1);
    expect(repo.logoutCalls, 0);
    expect(auth.currentUser, same(_customer));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Logout khi guard hiện hành chuyển Login đúng một lần', (
    tester,
  ) async {
    await loginAs(_admin);
    await pumpApp(tester, initialRoute: _guardRoute);
    await tester.pumpAndSettle();
    expect(find.text(_childMarker), findsOneWidget);

    await auth.logout();
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text(_loginMarker), findsOneWidget);
    expect(find.byType(_CountingChild, skipOffstage: false), findsNothing);
    expect(childBuilds, 1);
    expect(observer.loginPushes, 1);
    expect(repo.logoutCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guard bị che chỉ chuyển Login sau khi lộ lại', (tester) async {
    await loginAs(_admin);
    final navigator = await pumpApp(tester, initialRoute: _guardRoute);
    await tester.pumpAndSettle();
    expect(childBuilds, 1);
    navigator.pushNamed<dynamic>(_coverRoute);
    await tester.pumpAndSettle();

    await auth.logout();
    await tester.pumpAndSettle();

    expect(find.text('Cover marker'), findsOneWidget);
    expect(observer.loginPushes, 0);
    expect(find.byType(_CountingChild, skipOffstage: false), findsNothing);
    expect(childBuilds, 1);
    expect(tester.takeException(), isNull);

    navigator.pop();
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text(_loginMarker), findsOneWidget);
    expect(observer.loginPushes, 1);
    expect(navigator.canPop(), isFalse);
    expect(childBuilds, 1);
    expect(find.byType(_CountingChild, skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rebuild liên tiếp khi thiếu quyền chỉ push Login một lần', (
    tester,
  ) async {
    final rebuilds = ValueNotifier<int>(0);
    addTearDown(rebuilds.dispose);
    await loginAs(_admin);
    await pumpApp(tester, initialRoute: _guardRoute, rebuilds: rebuilds);
    await tester.pumpAndSettle();

    await auth.logout();
    expect(auth.isAdmin, isFalse);
    rebuilds.value = 1;
    rebuilds.value = 2;
    rebuilds.value = 3;
    await tester.pump(Duration.zero);
    expect(observer.loginPushes, 1);

    rebuilds.value = 4;
    rebuilds.value = 5;
    await tester.pump(Duration.zero);
    rebuilds.value = 6;
    await tester.pump(Duration.zero);
    expect(auth.isAdmin, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();

    expect(find.text(_loginMarker), findsOneWidget);
    expect(observer.loginPushes, 1);
    expect(childBuilds, 1);
    expect(find.byType(_CountingChild, skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
