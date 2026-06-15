import 'dart:collection';

class CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  CacheEntry(this.data, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class DataCache {
  static final DataCache _instance = DataCache._();
  static DataCache get instance => _instance;

  DataCache._();

  final _cache = HashMap<String, CacheEntry<dynamic>>();

  static const _ttls = <String, Duration>{
    'agents': Duration(seconds: 30),
    'providers': Duration(seconds: 30),
    'apps': Duration(seconds: 30),
    'stats': Duration(seconds: 60),
    'runtimes': Duration(seconds: 10),
    'security': Duration(seconds: 60),
    'context': Duration(seconds: 10),
    'time_config': Duration(seconds: 30),
    'notes': Duration(seconds: 15),
    'alarms': Duration(seconds: 15),
    'diary': Duration(seconds: 15),
  };

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T;
  }

  void set<T>(String key, T data, {String? group}) {
    final ttl = group != null && _ttls.containsKey(group)
        ? _ttls[group]!
        : const Duration(seconds: 30);
    _cache[key] = CacheEntry(data, DateTime.now().add(ttl));
  }

  void invalidate(String key) {
    _cache.remove(key);
  }

  void invalidateGroup(String group) {
    final prefix = '$group:';
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  void invalidateAll() {
    _cache.clear();
  }

  T? getOrSet<T>(String key, T Function() fetcher, {String? group}) {
    final cached = get<T>(key);
    if (cached != null) return cached;
    final data = fetcher();
    set(key, data, group: group);
    return data;
  }
}
