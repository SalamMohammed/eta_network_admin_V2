import 'package:flutter_test/flutter_test.dart';
import 'package:eta_network_admin/services/earnings_engine.dart';

void main() {
  group('Rate source logic', () {
    test('no mining, null userRate -> use base and write', () {
      final r = EarningsEngine.decideInitialRate(
        userRate: null,
        miningActive: false,
        baseRate: 0.2,
      );
      expect(r['rate'], 0.2);
      expect(r['write'], true);
    });

    test('no mining, userRate set -> use user without write', () {
      final r = EarningsEngine.decideInitialRate(
        userRate: 1.5,
        miningActive: false,
        baseRate: 0.2,
      );
      expect(r['rate'], 1.5);
      expect(r['write'], false);
    });

    test('mining active, null userRate -> use base and write', () {
      final r = EarningsEngine.decideInitialRate(
        userRate: null,
        miningActive: true,
        baseRate: 0.3,
      );
      expect(r['rate'], 0.3);
      expect(r['write'], true);
    });
  });
}
