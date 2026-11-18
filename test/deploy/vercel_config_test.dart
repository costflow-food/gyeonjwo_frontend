// .github/vercel/config.json(Vercel Build Output v3) 라우팅 규칙 검사 (KAN-290).
// 배포 미리보기 환경이 없어서, 경로 순서와 리다이렉트 정규식을 여기서 막는다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<Map<String, dynamic>> _routes() {
  final config = jsonDecode(
    File('.github/vercel/config.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return (config['routes'] as List).cast<Map<String, dynamic>>();
}

int _filesystemIndex(List<Map<String, dynamic>> routes) =>
    routes.indexWhere((r) => r['handle'] == 'filesystem');

int _redirectIndex(List<Map<String, dynamic>> routes) =>
    routes.indexWhere((r) => r['status'] == 302);

/// filesystem 단계에서 파일을 못 찾은 경로가 받는 Location. 리다이렉트가 없으면 null(=404).
String? _redirectFor(String path) {
  final routes = _routes();
  final route = routes[_redirectIndex(routes)];
  final match = RegExp(route['src'] as String).firstMatch(path);
  if (match == null) return null;
  final location = (route['headers'] as Map)['Location'] as String;
  return location.replaceAll(r'$1', match.group(1)!);
}

void main() {
  test('security headers come first, then filesystem, then the redirect', () {
    final routes = _routes();
    final headers = routes.first;
    expect(headers['src'], '/(.*)');
    expect(headers['continue'], isTrue);
    expect(
      (headers['headers'] as Map).keys,
      contains('Strict-Transport-Security'),
    );

    final filesystem = _filesystemIndex(routes);
    final redirect = _redirectIndex(routes);
    expect(filesystem, greaterThan(0));
    // 실제 파일(확장자 없는 assets/NOTICES 포함)이 리다이렉트보다 먼저 응답해야 한다.
    expect(redirect, greaterThan(filesystem));
    expect(redirect, routes.length - 1);
  });

  test('paths without # go to the hash route', () {
    const cases = {
      '/tasks': '/#/tasks',
      '/tasks/': '/#/tasks',
      '/tasks/REQ-1': '/#/tasks/REQ-1',
      '/tasks/REQ-1/review': '/#/tasks/REQ-1/review',
      '/cases/REQ-1': '/#/cases/REQ-1',
      '/cases/REQ-1/review/': '/#/cases/REQ-1/review',
      '/transactions': '/#/transactions',
      '/suppliers': '/#/suppliers',
      '/logs': '/#/logs',
      '/account': '/#/account',
      '/login/permissions': '/#/login/permissions',
      '/a.b/c': '/#/a.b/c',
    };
    cases.forEach((path, location) {
      expect(_redirectFor(path), location, reason: path);
    });
  });

  test('the root, OAuth return and missing files are not redirected', () {
    const untouched = [
      '/', // OAuth 콜백 /?code=... 도 경로는 '/'
      '/index.html',
      '/main.dart.js',
      '/flutter_bootstrap.js',
      '/canvaskit/canvaskit.wasm',
      '/assets/AssetManifest.bin.json',
      '/missing.png',
      '/tasks/v1.2',
      '/foo.png/',
      '//',
    ];
    for (final path in untouched) {
      expect(_redirectFor(path), isNull, reason: path);
    }
  });

  test('the redirect never leaves the site', () {
    const probes = ['//evil', '//evil.com', r'/\evil', '/%2F%2Fevil', '/@evil'];
    for (final path in probes) {
      final location = _redirectFor(path);
      if (location != null) {
        expect(location, startsWith('/#/'), reason: path);
      }
    }
  });

  test('long dotted paths are matched without slow backtracking', () {
    final path = '/${'.' * 14000}/';
    final watch = Stopwatch()..start();
    _redirectFor(path);
    _redirectFor('/${'a.' * 7000}/');
    expect(watch.elapsedMilliseconds, lessThan(50));
  });
}
