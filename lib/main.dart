import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

import 'delegate_node_status_widget.dart';
import 'input_address_widget.dart';
import 'statistics_service_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delegate Checker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Delegate Checker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class DelegateNodeStatus {
  String host = '';
  bool isErrHost = false;
  String friendlyName = '';
  String certExp = '';
  String nodeHealth = '';
  bool isErrNodeHealth = false;
  String delegateStatus = '';
  bool isErrDelegateStatus = false;
}

class _MyHomePageState extends State<MyHomePage> {
  String ssUrl = '';
  bool isSsActive = false;
  late String ssStatus;
  Color ssStatusColor = Colors.red;
  late List<dynamic> statisticsServiceJson;
  late Future<List<dynamic>> initFuture;

  GlobalKey<DelegateNodeStatusState> addressKey = GlobalKey();

  Future<void> setStateAddress(String address) async {
    debugPrint('委任ノード情報取得 Start');

    DelegateNodeStatus delegateStat = DelegateNodeStatus();

    // ランダムにノードを取得
    Map<String, dynamic> nodeInfoMap = getRandomNodeInfoSSL();

    // アカウント情報取得
    Map<String, dynamic> accountInfo =
        await getAccountInfoSSL(nodeInfoMap, address);
    if (accountInfo.isEmpty) {
      // アカウント情報取得失敗
      debugPrint('アカウント情報取得失敗');
      delegateStat.host = 'failed to get account info';
      delegateStat.isErrHost = true;
      // 委任状況ウィジェットへわたす
      addressKey.currentState!.setDelegateNodeStatus(delegateStat);
      return;
    }

    // リンクキー、ノードキー取得
    Map<String, String> supPubKeyMap = getSupplementalPublicKeys(accountInfo);
    if (supPubKeyMap['linked']!.isEmpty) {
      // リンクキーなし
      debugPrint('リンクキーなし');
      delegateStat.host = 'no linked key';
      delegateStat.isErrHost = true;
      // 委任状況ウィジェットへわたす
      addressKey.currentState!.setDelegateNodeStatus(delegateStat);
      return;
    }
    Map<String, dynamic> delegateNodeInfoMap = {};
    if (supPubKeyMap['node']!.isEmpty) {
      // ノードキーなし
      delegateNodeInfoMap =
          searchNodeAccountInfo(accountInfo['account']['publicKey']!);
      if (delegateNodeInfoMap.isEmpty) {
        debugPrint('ノードキーなし');
        delegateStat.host = 'no node key';
        delegateStat.isErrHost = true;
        // 委任状況ウィジェットへわたす
        addressKey.currentState!.setDelegateNodeStatus(delegateStat);
        return;
      }
    } else {
      // ノードキーあり
      delegateNodeInfoMap = searchNodeInfo(supPubKeyMap['node']!);
    }
    if (delegateNodeInfoMap.isEmpty) {
      // 委任ノードが存在しない
      debugPrint('委任ノードが存在しない');
      delegateStat.host = 'delegation node does not exist';
      delegateStat.isErrHost = true;
      // 委任状況ウィジェットへわたす
      addressKey.currentState!.setDelegateNodeStatus(delegateStat);
      return;
    }

    // ホスト
    delegateStat.host = delegateNodeInfoMap['host'];
    // フレンドリーネーム
    delegateStat.friendlyName = delegateNodeInfoMap['friendlyName'];
    // ノードヘルス
    delegateStat.nodeHealth =
        delegateNodeInfoMap['apiStatus']?['nodeStatus']['apiNode'];
    delegateStat.nodeHealth += '/';
    delegateStat.nodeHealth +=
        delegateNodeInfoMap['apiStatus']?['nodeStatus']['db'];
    if (delegateStat.nodeHealth.contains('down')) {
      delegateStat.isErrNodeHealth = true;
      // 委任状況ウィジェットへわたす
      addressKey.currentState!.setDelegateNodeStatus(delegateStat);
      return;
    }
    // 証明書
    delegateStat.certExp = delegateNodeInfoMap['certificateExpiration'];

    // 委任ノードSSLチェック
    bool isDelegateNodeSSL = false;
    if (delegateNodeInfoMap['apiStatus'] != null &&
        delegateNodeInfoMap['apiStatus']['isHttpsEnabled'] != null &&
        delegateNodeInfoMap['apiStatus']['isHttpsEnabled'] == true) {
      isDelegateNodeSSL = true;
    }

    // 委任状況
    if (isDelegateNodeSSL) {
      // SSLノード
      bool isDelegate =
          await isUnlockedAccount(delegateNodeInfoMap, supPubKeyMap['linked']!);
      if (isDelegate) {
        delegateStat.delegateStatus = 'Active';
      } else {
        delegateStat.delegateStatus = 'Inactive';
        delegateStat.isErrDelegateStatus = true;
      }
    } else {
      // non-SSLノード
      delegateStat.delegateStatus = 'Unable to check because it is non-HTTPS';
      delegateStat.isErrDelegateStatus = true;
    }

    // 委任状況ウィジェットへわたす
    addressKey.currentState!.setDelegateNodeStatus(delegateStat);
  }

  ///
  /// 画面初期化時
  ///
  @override
  void initState() {
    super.initState();

    // Statistics ServiceからJson取得
    Future<List<dynamic>> ssFuture = Future(() async {
      var url = Uri.https('tools2.harvestasya.com', '/dss/nodes');
      ssUrl = url.host.toString() + url.path.toString();
      var response = await http.get(url);
      if (response.statusCode == 200) {
        // SS取得成功
        ssStatus = 'Active';
        isSsActive = true;
        ssStatusColor = Colors.green;
        statisticsServiceJson = convert.jsonDecode(response.body);
      } else {
        // SS取得失敗
        ssStatus = 'Inactive';
        isSsActive = false;
        ssStatusColor = Colors.red;
        statisticsServiceJson = [];
        debugPrint('Request failed with status: ${response.statusCode}.');
      }
      return statisticsServiceJson;
    });
    // Statistics ServiceからJson取得待機
    Future<List<dynamic>> ssFutureWait = Future.wait([ssFuture]);
    initFuture = ssFutureWait;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: initFuture,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none: // ？？？
              case ConnectionState.waiting: // 処理中データ: Null
              case ConnectionState.active: // 処理中データ: Not Null
                return const Center(
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(strokeWidth: 8.0),
                  ),
                );
              case ConnectionState.done: // 完了
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      StatisticsServiceWidget(
                        ssUrl: ssUrl,
                        ssStatus: ssStatus,
                        ssStatusColor: ssStatusColor,
                      ),
                      InputAddressWidget(
                        notifySetStateAddress: setStateAddress,
                      ),
                      DelegateNodeStatusWidget(
                        key: addressKey,
                        isStatisticsServiceActive: isSsActive,
                        statisticsServiceJson: statisticsServiceJson,
                      ),
                    ],
                  ),
                );
            }
          },
        ),
      ),
    );
  }

  /// アンロックアカウント判定
  Future<bool> isUnlockedAccount(
      Map<String, dynamic> nodeInfoMap, String pubKey) async {
    // RESTゲートウェイURL取得
    String restGatewayUrl = getRestGatewayUrlSSL(nodeInfoMap);
    if (restGatewayUrl.isEmpty) {
      // RESTゲートウェイURL取得失敗
      return false;
    }

    // プロトコル除去
    String host = restGatewayUrl.replaceAll('https://', '');
    // アカウント検索URL作成
    Uri uri = Uri.https(host, 'node/unlockedaccount');

    debugPrint('account info url: $uri');
    var response = await http.get(uri);

    dynamic result;
    if (response.statusCode == 200) {
      // 取得成功;
      result = convert.jsonDecode(response.body);
    } else {
      // 取得失敗
      return false;
    }
    List<dynamic> unlockedAccountList = result['unlockedAccount'];

    for (String unlockedPubKey in unlockedAccountList) {
      if (unlockedPubKey == pubKey) {
        return true;
      }
    }

    return false;
  }

  /// ノードキーでノード情報を検索
  Map<String, dynamic> searchNodeInfo(String nodePubKey) {
    Map<String, dynamic> nodeInfoMap = {};

    for (Map<String, dynamic> item in statisticsServiceJson) {
      if (item['apiStatus'] != null &&
          item['apiStatus']['nodePublicKey'] != null &&
          item['apiStatus']['nodePublicKey'] == nodePubKey) {
        debugPrint('委任アカウントです。');
        nodeInfoMap = item;
        break;
      }
    }

    return nodeInfoMap;
  }

  /// ノードキーでノードアカウント情報を検索
  Map<String, dynamic> searchNodeAccountInfo(String nodePubKey) {
    Map<String, dynamic> nodeInfoMap = {};

    for (Map<String, dynamic> item in statisticsServiceJson) {
      if (item['publicKey'] == nodePubKey) {
        debugPrint('ノードアカウントです。');
        nodeInfoMap = item;
        break;
      }
    }

    return nodeInfoMap;
  }

  /// リンクキー、ノードキー取得
  Map<String, String> getSupplementalPublicKeys(
      Map<String, dynamic> accountInfo) {
    Map<String, String> supplementalPublicKeysMap = <String, String>{};
    supplementalPublicKeysMap['linked'] = '';
    supplementalPublicKeysMap['node'] = '';

    if (accountInfo.isNotEmpty) {
      String linkedPublicKey = '';
      String nodePublicKey = '';

      if (accountInfo['account'] != null &&
          accountInfo['account']['supplementalPublicKeys'] != null) {
        dynamic supPubKeys = accountInfo['account']['supplementalPublicKeys'];

        // リンクキー取得
        if (supPubKeys['linked'] != null &&
            supPubKeys['linked']['publicKey'] != null) {
          linkedPublicKey = supPubKeys['linked']['publicKey'];
        }
        // ノードキー取得
        if (supPubKeys['node'] != null &&
            supPubKeys['node']['publicKey'] != null) {
          nodePublicKey = supPubKeys['node']['publicKey'];
        }
      }

      supplementalPublicKeysMap['linked'] = linkedPublicKey;
      supplementalPublicKeysMap['node'] = nodePublicKey;
      debugPrint('linkedPublicKey: $linkedPublicKey');
      debugPrint('nodePublicKey: $nodePublicKey');
    }
    return supplementalPublicKeysMap;
  }

  /// アカウント情報取得(SSL)<br>
  /// 取得出来なかった場合は空リストを返す
  Future<Map<String, dynamic>> getAccountInfoSSL(
      Map<String, dynamic> nodeInfoMap, String address) async {
    // RESTゲートウェイURL取得
    String restGatewayUrl = getRestGatewayUrlSSL(nodeInfoMap);
    if (restGatewayUrl.isEmpty) {
      // RESTゲートウェイURL取得失敗
      return {};
    }

    // プロトコル除去
    String host = restGatewayUrl.replaceAll('https://', '');
    // アカウント検索URL作成
    Uri uri = Uri.https(host, '/accounts/$address');
    debugPrint('account info url: $uri');

    try {
      // アカウント検索
      var response = await http.get(uri);
      if (response.statusCode == 200) {
        // 取得成功;
        return convert.jsonDecode(response.body);
      }
    } catch (e) {
      // 取得失敗
      return {};
    }

    return {};
  }

  /// ノード情報マップからRESTゲートウェイURLを取得(SSL)<br>
  /// 失敗した場合は空文字列を返す
  String getRestGatewayUrlSSL(Map<String, dynamic> nodeInfoMap) {
    String restGatewayUrl = '';
    if (nodeInfoMap['apiStatus'] != null &&
        nodeInfoMap['apiStatus']['isHttpsEnabled'] == true &&
        nodeInfoMap['apiStatus']['restGatewayUrl'] != null) {
      restGatewayUrl = nodeInfoMap['apiStatus']['restGatewayUrl'];
    }
    return restGatewayUrl;
  }

  /// SSLなノードホストをランダムに取得
  Map<String, dynamic> getRandomNodeInfoSSL() {
    // SSLノードリスト作成
    List<Map<String, dynamic>> sslNodeHostList = [];
    for (Map<String, dynamic> item in statisticsServiceJson) {
      if (item['apiStatus'] != null &&
          item['apiStatus']['isHttpsEnabled'] == true &&
          item['apiStatus']['webSocket'] != null &&
          item['apiStatus']['webSocket']['isAvailable'] == true &&
          item['apiStatus']['webSocket']['wss'] == true) {
        sslNodeHostList.add(item);
      }
    }
    // ランダムに取得
    Random random = Random();
    Map<String, dynamic> randomNode =
        sslNodeHostList[random.nextInt(sslNodeHostList.length)];

    debugPrint('random connection node: ${randomNode['host']}');
    return randomNode;
  }
}
