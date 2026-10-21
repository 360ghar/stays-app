// Helpers for the contract tests: backend-shaped fixtures and a fake HTTP
// adapter that records what the app puts on the wire.
//
// Fixtures come from the backend's own Pydantic models (tool/api_fixtures.py).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/config/app_config.dart';

/// Sets the app config that providers read while they log. Call it in
/// `setUpAll`.
void useTestConfig() {
  AppConfig.setConfig(
    const AppConfig(
      environment: 'test',
      apiBaseUrl: 'https://api.example.test',
      supabaseUrl: 'https://supabase.example.test',
      supabasePublishableKey: 'key-test',
    ),
  );
}

Map<String, dynamic> fixture(String group) =>
    jsonDecode(File('test/fixtures/api/$group.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> obj(Object? value) =>
    Map<String, dynamic>.from(value! as Map);

List<Map<String, dynamic>> items(Object? page) =>
    (obj(page)['items'] as List).map(obj).toList(growable: false);

/// One answer of the fake server.
class FakeReply {
  const FakeReply(this.body, {this.status = 200, this.headers = const {}});

  final Object? body;
  final int status;
  final Map<String, String> headers;
}

/// Records every request and answers with [reply].
class RecordingAdapter implements HttpClientAdapter {
  RecordingAdapter(this.reply);

  FakeReply Function(RequestOptions request) reply;
  final List<RequestOptions> requests = [];

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final answer = reply(options);
    final body = answer.body == null ? '' : jsonEncode(answer.body);
    return ResponseBody.fromString(
      body,
      answer.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final entry in answer.headers.entries) entry.key: [entry.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A Dio client that talks to [adapter]. Like the app client it accepts every
/// status, so the provider reads error bodies itself.
Dio fakeDio(RecordingAdapter adapter) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://api.example.test',
      validateStatus: (_) => true,
    ),
  )..httpClientAdapter = adapter;
}

/// The query keys of a recorded request as a multimap.
Map<String, List<String>> queryOf(RequestOptions request) =>
    request.uri.queryParametersAll;

/// Asserts that [body] satisfies the request contract the backend publishes
/// for [schema] (see `requests.json`): every key is declared when the body
/// rejects unknown keys, and every required key is present.
void expectBodyMatches(String schema, Map<String, dynamic> body) {
  final contract = obj(obj(fixture('requests'))[schema]);
  final declared = obj(contract['properties']).keys.toSet();
  final required = (contract['required'] as List).cast<String>();
  if (contract['extra_forbidden'] == true) {
    expect(
      body.keys.toSet().difference(declared),
      isEmpty,
      reason: '$schema rejects unknown keys',
    );
  }
  expect(
    required.toSet().difference(body.keys.toSet()),
    isEmpty,
    reason: '$schema requires these keys',
  );
}

/// Asserts that every query key of [request] is declared by the backend for
/// the operation ([operation] is `METHOD /path`). An undeclared key is a 422.
void expectQueryDeclared(RequestOptions request, String operation) {
  final ops = obj(fixture('operations'));
  final declared = obj(obj(ops[operation])['query']).keys.toSet()
    ..addAll(const ['cursor', 'limit', 'include_total']);
  expect(
    queryOf(request).keys.toSet().difference(declared),
    isEmpty,
    reason: '$operation declares ${declared.toList()..sort()}',
  );
}
