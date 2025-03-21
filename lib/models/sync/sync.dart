import 'package:flutter/foundation.dart';
import 'package:memofante/models/sync/transaction.dart';
import 'package:memofante/models/discovered_word.dart';
import 'package:objectbox/objectbox.dart';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> getSyncJson(
    Box<Transaction> transactionBox, Box<DiscoveredWord> discoveredWordBox) {
  final transactions = Transaction.fetchAllTransactions(transactionBox);
  final words = discoveredWordBox.getAll();

  return {
    "type": "local_state",
    "words": words.map((word) => word.toJson()).toList(),
    "transactions": transactions.map((tx) => tx.toJson()).toList(),
  };
}

const Duration _reconnectDelay = Duration(milliseconds: 100);

enum SyncState {
  idle,
  requestedSync,
  sendingData,
}

class SyncWebSocketClient extends ChangeNotifier {
  final Box<Transaction> transactionBox;
  final Box<DiscoveredWord> discoveredWordBox;
  WebSocket? _socket;
  String? _syncCode;
  String? get syncCode => _syncCode;
  // New fields for reconnection logic.
  late String _url;
  bool _isManuallyClosed = true;
  bool canSync = false;

  bool get isManuallyClosed => _isManuallyClosed;
  SyncState syncState;
  SyncWebSocketClient(
      {required this.transactionBox,
      required this.discoveredWordBox,
      this.syncState = SyncState.idle});
  Future<void> updateSyncSettings(String newSyncCode, String url) async {
    await connect(url);
    _syncCode = newSyncCode;
    _sendUseSyncCode();
    notifyListeners();
  }

  Future<void> updateSyncSettingsFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final storedSyncCode = prefs.getString('syncCode');
    final storedUrl = prefs.getString('syncServerUrl') ??
        'wss://memofante-sync-backend.fly.dev';
    if (storedSyncCode == null) {
      await connect(storedUrl);
      return;
    }
    await updateSyncSettings(storedSyncCode, storedUrl);
  }

  Future<void> connect(String url) async {
    print("Connecting to " + url);
    if (_isManuallyClosed || url != _url) {
      this.close();
      _url = url;
    }
    _isManuallyClosed = false;
    notifyListeners();
    try {
      final socket = await WebSocket.connect(_url);
      _socket = socket;
      // Listen with inline onDone and onError that attempt reconnection.
      _socket?.listen(
        (data) {
          if (socket == _socket) {
            _handleMessage(data);
          } else {
            // Close dangling connection
            socket.close();
          }
        },
        onDone: () {
          print("Connection closed $socket");
          _handleDone();
          if (!_isManuallyClosed && socket == _socket) {
            _attemptReconnect();
          }
          syncState = SyncState.idle;
        },
        onError: (error) {
          print("Connection closed (error) $socket");
          _handleError(error);
          if (!_isManuallyClosed && socket == _socket) {
            _attemptReconnect();
          }
          syncState = SyncState.idle;
        },
      );
      _sendUseSyncCode();
    } catch (e) {
      _handleError(e);
      if (!_isManuallyClosed) {
        _attemptReconnect();
      }
    }
  }

  Future<void> _attemptReconnect() async {
    print("Attempting to reconnect");
    await Future.delayed(_reconnectDelay);
    try {
      await connect(_url);
      print("Reconnected to $_url");
    } catch (e) {
      print("Reconnection failed: $e");
      await _attemptReconnect();
    }
  }

  void _sendUseSyncCode() {
    final packet = {"type": "use_sync_code", "syncCode": _syncCode!};
    _socket?.add(jsonEncode(packet));
    canSync = true;
    notifyListeners();
  }

  void requestSync() {
    syncState = SyncState.requestedSync;
    canSync = false;
    this.notifyListeners();
    final packet = {"type": "request_sync"};
    _socket?.add(jsonEncode(packet));
  }

  void sendLocalState() {
    syncState = SyncState.sendingData;
    this.notifyListeners();
    final payload = getSyncJson(transactionBox, discoveredWordBox);
    _socket?.add(jsonEncode(payload));
  }

  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data);
      switch (message['type']) {
        case "request_local_state":
          // Respond to server's request by sending local state.
          sendLocalState();
          canSync = false;
          break;
        case "sync_complete":
          // Clear local discovered words and transactions.
          discoveredWordBox.removeAll();
          transactionBox.removeAll();
          // Save the discovered words state received from the server.
          List<Map<String, dynamic>> finalWords =
              (message['finalWords'] as List<dynamic>)
                  .map((el) => el as Map<String, dynamic>)
                  .toList();
          discoveredWordBox
              .putMany(finalWords.map(DiscoveredWord.fromJson).toList());
          syncState = SyncState.idle;
          canSync = true;
          notifyListeners();

          break;
        default:
          // Unknown packet type.
          break;
      }
    } catch (e) {
      // Handle decoding error.
      print("Failed to decode message: $e");
    }
  }

  void _handleDone() {
    print("Connection closed.");
    syncState = SyncState.idle;
    canSync = false;
    this.notifyListeners();
  }

  void _handleError(dynamic error) {
    print("WebSocket error: $error");
    syncState = SyncState.idle;
    canSync = false;
    this.notifyListeners();
  }

  void close() {
    _isManuallyClosed = true;
    try {
      _socket?.close();
    } catch (e) {
      print("Warning: Failed to close sync websocket connection: $e");
    }
    syncState = SyncState.idle;
    this.notifyListeners();
  }
}
