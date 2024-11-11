import 'package:server/models/memory_store.dart';
import 'package:test/test.dart';

void main() {
  group('MemoryRateLimitStore Tests', () {
    late MemoryRateLimitStore rateLimitStore;

    setUp(() {
      rateLimitStore = MemoryRateLimitStore();
    });

    test('should allow requests within rate limit', () async {
      final key = 'testKey';
      final maxRequests = 3;
      final window = Duration(seconds: 10);

      expect(await rateLimitStore.increment(key, maxRequests, window), true);
      expect(await rateLimitStore.increment(key, maxRequests, window), true);
      expect(await rateLimitStore.increment(key, maxRequests, window), true);
    });

    test('should block requests beyond the rate limit', () async {
      final key = 'testKey';
      final maxRequests = 3;
      final window = Duration(seconds: 10);

      expect(await rateLimitStore.increment(key, maxRequests, window), true);
      expect(await rateLimitStore.increment(key, maxRequests, window), true);
      expect(await rateLimitStore.increment(key, maxRequests, window), true);

      expect(await rateLimitStore.increment(key, maxRequests, window), false);
    });

    test('should reset the rate limit for a key', () async {
      final key = 'testKey';
      final maxRequests = 3;
      final window = Duration(seconds: 10);

      expect(await rateLimitStore.increment(key, maxRequests, window), true);
      expect(await rateLimitStore.increment(key, maxRequests, window), true);
      expect(await rateLimitStore.increment(key, maxRequests, window), true);

      await rateLimitStore.reset(key);

      expect(await rateLimitStore.increment(key, maxRequests, window), true);
    });

    test('should not allow requests outside of the time window', () async {
      final key = 'testKey';
      final maxRequests = 3;
      final window = Duration(seconds: 5);

      expect(await rateLimitStore.increment(key, maxRequests, window), true);
      await Future.delayed(Duration(seconds: 1));
      expect(await rateLimitStore.increment(key, maxRequests, window), true);
      await Future.delayed(Duration(seconds: 1));
      expect(await rateLimitStore.increment(key, maxRequests, window), true);

      await Future.delayed(Duration(seconds: 5));

      expect(await rateLimitStore.increment(key, maxRequests, window), true);
    });
  });
}
