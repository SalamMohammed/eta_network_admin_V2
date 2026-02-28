import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/mining_state_service.dart';
import '../../services/user_service.dart';
import 'my_coin_block.dart';

import '../../l10n/generated/app_localizations.dart';

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  final _miningService = MiningStateService();
  DateTime? _lastUiUpdate;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _miningService.addListener(_handleServiceUpdate);
    // MiningService is auto-initialized by Auth listener
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      unawaited(UserService().getUser(uid));
    }
  }

  @override
  void dispose() {
    _miningService.removeListener(_handleServiceUpdate);
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleServiceUpdate() {
    if (!mounted) return;
    final now = DateTime.now();
    final last = _lastUiUpdate;
    if (last == null || now.difference(last) >= const Duration(seconds: 1)) {
      _lastUiUpdate = now;
      setState(() {});
      return;
    }
    _debounceTimer ??= Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _lastUiUpdate = DateTime.now();
      _debounceTimer = null;
      setState(() {});
    });
  }

  Widget _walletSummaryCard(BuildContext context) {
    const cardBg = Color(0xFF1B2632);
    const cardBg2 = Color(0xFF141E28);
    const buttonBlue = Color(0xFF1677FF);

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 380).clamp(0.78, 1.0);
        double s(double v) => v * scale;
        final total = _miningService.displayTotal;
        final maxAmountWidth = constraints.maxWidth * 0.75;

        return Container(
          padding: EdgeInsets.all(s(18)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(s(22)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardBg, cardBg2],
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.totalBalance,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: s(16),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: s(10)),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxAmountWidth),
                          child: SizedBox(
                            height: s(46),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final text = total.toStringAsFixed(3);
                                      double size = 40.0;
                                      if (text.length > 9) {
                                        size = 40.0 * (9.0 / text.length);
                                        if (size < 15.0) size = 15.0;
                                      }
                                      return Text(
                                        text,
                                        style: TextStyle(
                                          fontSize: s(size),
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.0,
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(width: s(10)),
                                  Padding(
                                    padding: EdgeInsets.only(bottom: s(6)),
                                    child: Text(
                                      'ETA',
                                      style: TextStyle(
                                        fontSize: s(20),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: s(10)),
                  Container(
                    width: s(56),
                    height: s(56),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: buttonBlue,
                      size: s(26),
                    ),
                  ),
                ],
              ),
              SizedBox(height: s(18)),
              Container(height: 1, color: Colors.white12),
              SizedBox(height: s(16)),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: s(46),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(s(14)),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Transfer',
                          style: TextStyle(
                            fontSize: s(16),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: s(12)),
                  Expanded(
                    child: SizedBox(
                      height: s(46),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.10),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(s(14)),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Receive',
                          style: TextStyle(
                            fontSize: s(16),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = (size.width * 0.04).clamp(12.0, 16.0);
    final vPad = (size.width * 0.03).clamp(8.0, 12.0);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppLocalizations.of(context)!.balanceTitle),
        actions: const [SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: vPad),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
              child: _walletSummaryCard(context),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: MyCoinBlock(variant: MyCoinBlockVariant.home),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
