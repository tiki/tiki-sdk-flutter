/*
 * Copyright (c) TIKI Inc.
 * MIT license. See LICENSE file in root directory.
 */

/// Native platform channels for TIKI SDK.
///
/// The Flutter Platform Channels are used to call native code from Dart and
/// vice-versa. In TIKI SDK we use it to call [TikiSdk] methods **from** native code.
/// It is **not used** in pure Flutter implementations.
library tiki_sdk_flutter_platform;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tiki_sdk_flutter/main.dart';

import 'req/req.dart';
import 'req/req_build.dart';
import 'req/req_consent_apply.dart';
import 'req/req_consent_get.dart';
import 'req/req_consent_modify.dart';
import 'req/req_ownership_assign.dart';
import 'req/req_ownership_get.dart';
import 'rsp/rsp.dart';
import 'rsp/rsp_build.dart';
import 'rsp/rsp_consent_apply.dart';
import 'rsp/rsp_consent_get.dart';
import 'rsp/rsp_error.dart';
import 'rsp/rsp_ownership.dart';

/// The definition of native platform channels
class TikiPlatformChannel {
  static late final TikiSdk _tikiSdk;

  final methodChannel = const MethodChannel('tiki_sdk_flutter');

  TikiPlatformChannel() {
    methodChannel.setMethodCallHandler(methodHandler);
  }

  /// Handles the method calls from native code.
  ///
  /// When calling TIKI SDK Flutter from native code, one should pass a requestId
  /// that will identify to which request the response belongs to.
  /// All the calls are asynchronous and should be treated like this in each native
  /// platform.
  Future<void> methodHandler(MethodCall call) async {
    String jsonReq = call.arguments['request'];
    switch (call.method) {
      case "build":
        await _handle(ReqBuild.fromJson(jsonReq), _buildSdk);
        break;
      case "assignOwnership":
        await _handle(ReqOwnershipAssign.fromJson(jsonReq), _assignOwnership);
        break;
      case "getOwnership":
        await _handle(ReqOwnershipGet.fromJson(jsonReq), _getOwnership);
        break;
      case "modifyConsent":
        await _handle(ReqConsentModify.fromJson(jsonReq), _modifyConsent);
        break;
      case "getConsent":
        await _handle(ReqConsentGet.fromJson(jsonReq), _getConsent);
        break;
      case "applyConsent":
        ReqConsentApply reqConsentApply = ReqConsentApply.fromJson(jsonReq);
        _applyConsent(reqConsentApply);
        break;
      default:
        Map<Map, String?> map = jsonDecode(jsonReq);
        String requestId = map['requestId']!;
        _error(RspError(
            requestId: requestId,
            message: 'no method handler for method ${call.method}',
            stackTrace: StackTrace.current));
    }
  }

  Future<RspBuild> _buildSdk(ReqBuild req) async {
    TikiSdkFlutterBuilder builder = TikiSdkFlutterBuilder()
      ..origin(req.origin)
      ..apiId(req.apiId);
    if (req.address != null) {
      builder.address(req.address!);
    }
    _tikiSdk = await builder.build();
    return RspBuild(address: _tikiSdk.address);
  }

  Future<RspOwnership> _assignOwnership(ReqOwnershipAssign req) async {
    await _tikiSdk.assignOwnership(req.source, req.type, req.contains,
        about: req.about, origin: req.origin);
    OwnershipModel ownershipModel =
        _tikiSdk.getOwnership(req.source, origin: req.origin)!;
    return RspOwnership(ownership: ownershipModel, requestId: req.requestId);
  }

  Future<RspOwnership> _getOwnership(ReqOwnershipGet req) {
    OwnershipModel? ownershipModel =
        _tikiSdk.getOwnership(req.source, origin: req.origin);
    return Future.value(
        RspOwnership(ownership: ownershipModel, requestId: req.requestId));
  }

  Future<RspConsentGet> _modifyConsent(ReqConsentModify req) async {
    ConsentModel consentModel = await _tikiSdk.modifyConsent(
        req.ownershipId, req.destination,
        about: req.about, reward: req.reward, expiry: req.expiry);
    return RspConsentGet(consent: consentModel, requestId: req.requestId);
  }

  Future<RspConsentGet> _getConsent(ReqConsentGet req) {
    ConsentModel? consentModel =
        _tikiSdk.getConsent(req.source, origin: req.origin);
    return Future.value(
        RspConsentGet(consent: consentModel, requestId: req.requestId));
  }

  Future<RspConsentApply> _applyConsent(ReqConsentApply req) {
    Future<RspConsentApply>? resp;
    _tikiSdk.applyConsent(req.source, req.destination, () {
      resp = Future.value(
          RspConsentApply(success: true, requestId: req.requestId));
    }, onBlocked: (String reason) {
      resp = Future.value(RspConsentApply(
          success: false, reason: reason, requestId: req.requestId));
    });
    return resp!;
  }

  Future<void> _handle<S extends Req, D extends Rsp>(
      S req, Future<D> Function(S) process) async {
    try {
      D rsp = await process(req);
      _success(rsp);
    } catch (e) {
      RspError error = RspError.fromError(e as Error, requestId: req.requestId);
      await methodChannel.invokeMethod('error', {'response': error.toJson()});
    }
  }

  Future<void> _success(Rsp rsp) async =>
      await methodChannel.invokeMethod('success', {'response': rsp.toJson()});

  Future<void> _error(RspError rsp) async =>
      await methodChannel.invokeMethod('error', {'response': rsp.toJson()});
}
