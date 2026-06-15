import 'dart:async';

class CancelToken {
  bool _cancelled = false;
  final List<void Function()> _onCancel = [];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final cb in _onCancel) {
      cb();
    }
    _onCancel.clear();
  }

  void addCancelCallback(void Function() cb) {
    if (_cancelled) {
      cb();
      return;
    }
    _onCancel.add(cb);
  }
}

class CancellableRequest<T> {
  final Future<T> Function() _request;
  final CancelToken _token;

  CancellableRequest(this._request, this._token);

  Future<T> fetch() async {
    final completer = Completer<T>();
    final timer = Timer(const Duration(seconds: 1), () {});

    _token.addCancelCallback(() {
      if (!completer.isCompleted) {
        completer.completeError(CancelledException());
      }
      timer.cancel();
    });

    try {
      final result = await _request();
      if (!_token.isCancelled && !completer.isCompleted) {
        completer.complete(result);
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    return completer.future;
  }
}

class CancelledException implements Exception {
  @override
  String toString() => 'Request cancelled';
}
