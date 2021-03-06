import 'dart:async';

import 'package:flutter/services.dart';

typedef CdnByeInfoListener = void Function(Map<String, dynamic>);

class Cdnbye {
  static const MethodChannel _channel = const MethodChannel('cdnbye');

  // The version of SDK. SDK的版本号
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  // Create a new instance with token and the specified config.
  static Future<int> init(
    token, {
    P2pConfig config,
    CdnByeInfoListener infoListener,
  }) async {
    final int success = await _channel.invokeMethod('init', {
      'token': token,
      'config': config.toMap,
    });
    await _setListen(infoListener);
    return success;
  }

  static Future _setListen(CdnByeInfoListener infoListener) async {
    if (infoListener != null) {
      await _channel.invokeMethod('startListen');
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'info') {
          infoListener(call.arguments);
        }
      });
    }
  }

  // Get parsed local stream url by passing the original stream url(m3u8) to CBP2pEngine instance.
  static Future<String> parseStreamURL(String sourceUrl) async {
    final String url = await _channel.invokeMethod('parseStreamURL', {
      'url': sourceUrl,
    });
    return url;
  }

  // Get the connection state of p2p engine. 获取P2P Engine的连接状态
  static Future<bool> isConnected() => _channel.invokeMethod('isConnected');

  // Restart p2p engine.
  static Future restartP2p() => _channel.invokeMethod('restartP2p');

  // Stop p2p and free used resources.
  static Future stopP2p() => _channel.invokeMethod('stopP2p');

  // Get the peer ID of p2p engine. 获取P2P Engine的peer ID
  static Future<String> getPeerId() => _channel.invokeMethod('getPeerId');
}

// Print log level.
enum P2pLogLevel {
  none,
  debug,
  info,
  warn,
  error,
}

// The configuration of p2p engine.
class P2pConfig {
  /// 打印日志的级别
  final P2pLogLevel logLevel;

  /// 通过webRTCConfig来修改WebRTC默认配置
  @deprecated
  final Map<String, dynamic> webRTCConfig;

  /// 信令服务器地址
  final String wsSignalerAddr;

  /// tracker服务器地址
  final String announce;

  /// 点播模式下P2P在磁盘缓存的最大数据量(设为0可以禁用磁盘缓存)
  final int diskCacheLimit;

  /// P2P在内存缓存的最大数据量，用ts文件个数表示
  final int memoryCacheCountLimit;
  // @Deprecated('Use memoryCacheCountLimit now')
  final int memoryCacheLimit;

  /// 开启或关闭p2p engine
  final bool p2pEnabled;

  /// HTTP下载ts文件超时时间
  final Duration downloadTimeout;

  /// datachannel下载二进制数据的最大超时时间
  final Duration dcDownloadTimeout;

  /// 用户自定义的标签，可以在控制台查看分布图
  final String tag;

  /// 本地代理服务器的端口号
  final int localPort;

  /// 最大连接节点数量
  final int maxPeerConnections;

  /// 在可能的情况下使用Http Range请求来补足p2p下载超时的剩余部分数据
  final bool useHttpRange;

  P2pConfig({
    this.logLevel: P2pLogLevel.warn,
    this.webRTCConfig: const {}, // TODO: 默认值缺少
    this.wsSignalerAddr: 'wss://signal.cdnbye.com',
    this.announce: 'https://tracker.cdnbye.com/v1',
    this.diskCacheLimit: 1024 * 1024 * 1024,
    this.memoryCacheLimit: 60 * 1024 * 1024, // deprecated
    this.memoryCacheCountLimit: 30,
    this.p2pEnabled: true,
    this.downloadTimeout: const Duration(seconds: 10),
    this.dcDownloadTimeout: const Duration(seconds: 4),
    this.tag: "flutter",
    this.localPort: 52019,
    this.maxPeerConnections: 10,
    this.useHttpRange: true,
  });

  P2pConfig.byDefault() : this();

  Map<String, dynamic> get toMap => {
        'logLevel': logLevel.index,
        'webRTCConfig': webRTCConfig,
        'wsSignalerAddr': wsSignalerAddr,
        'announce': announce,
        'diskCacheLimit': diskCacheLimit,
        // 'memoryCacheLimit': memoryCacheLimit,// deprecated
        'memoryCacheCountLimit': memoryCacheCountLimit,
        'p2pEnabled': p2pEnabled,
        'downloadTimeout': downloadTimeout.inSeconds,
        'dcDownloadTimeout': dcDownloadTimeout.inSeconds,
        'tag': tag,
        'localPort': localPort,
        'maxPeerConnections': maxPeerConnections,
        'useHttpRange': useHttpRange,
      };
}
