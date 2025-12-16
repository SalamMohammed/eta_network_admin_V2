import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/theme/colors.dart';
import '../../shared/firestore_constants.dart';
import 'my_coin_block.dart';

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Your ETA Balance'),
      ),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(12), child: MyCoinBlock()),
          Builder(
            builder: (context) {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) {
                return const SizedBox.shrink();
              }
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection(FirestoreConstants.users)
                    .doc(uid)
                    .snapshots(),
                builder: (context, snap) {
                  final d = snap.data?.data() ?? {};
                  final total =
                      (d[FirestoreUserFields.totalPoints] as num?)
                          ?.toDouble() ??
                      0.0;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          total.toStringAsFixed(3),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('ETA total'),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'History'),
              Tab(text: 'Daily Summary'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [_history(), _summary()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _history() {
    return const Center(child: Text('Moved to Home page'));
  }

  Widget _summary() {
    return const Center(child: Text('Moved to Home page'));
  }

  // deprecated
  // ignore: unused_element
  Widget _card(String title, String value) {
    return const SizedBox.shrink();
  }

  // sections moved to Home page
}
