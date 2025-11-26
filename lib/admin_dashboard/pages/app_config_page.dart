import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class AppConfigPage extends StatelessWidget {
  const AppConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    final baseRateCtrl = TextEditingController(text: '0.2');
    final maxDailyCtrl = TextEditingController(text: '0');
    final invBonusCtrl = TextEditingController(text: '10');
    final inviteeBonusCtrl = TextEditingController(text: '0');
    final maxRefBonusCtrl = TextEditingController(text: '100');
    bool enableReferral = true;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Earning Configuration (app_config)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _panel(
          title: 'Base Rate & Limits',
          child: Row(children: [
            _field('Base rate per hour', baseRateCtrl),
            const SizedBox(width: 12),
            _field('Max daily earning', maxDailyCtrl),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: () {}, child: const Text('Save changes')),
          ]),
        ),
        const SizedBox(height: 16),
        _panel(
          title: 'Referral Bonus Settings',
          child: Column(children: [
            Row(children: [
              _field('Inviter bonus', invBonusCtrl),
              const SizedBox(width: 12),
              _field('Invitee bonus', inviteeBonusCtrl),
              const SizedBox(width: 12),
              _field('MaxReferralBonus per user', maxRefBonusCtrl),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Checkbox(value: enableReferral, onChanged: (_) {}),
              const Text('Enable referral bonuses'),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        _panel(
          title: 'Streak Bonus Settings',
          child: Column(children: [
            _streakRow('1–3 days', '+0%'),
            _streakRow('4–7 days', '+5%'),
            _streakRow('8–15 days', '+10%'),
            const SizedBox(height: 8),
            Row(children: [
              ElevatedButton(onPressed: () {}, child: const Text('Add Rule')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () {}, child: const Text('Save')),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        _panel(
          title: 'Rank Rules',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(columns: const [
              DataColumn(label: Text('Rank')),
              DataColumn(label: Text('Required active invited')),
              DataColumn(label: Text('Required streakDays')),
            ], rows: const [
              DataRow(cells: [DataCell(Text('Explorer')), DataCell(Text('0')), DataCell(Text('0'))]),
              DataRow(cells: [DataCell(Text('Builder')), DataCell(Text('5')), DataCell(Text('4'))]),
              DataRow(cells: [DataCell(Text('Guardian')), DataCell(Text('10')), DataCell(Text('8'))]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primaryBackground, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Expanded(child: TextField(controller: controller, decoration: InputDecoration(labelText: label)));
  }

  Widget _streakRow(String range, String bonus) {
    return Row(children: [Expanded(child: Text(range)), Expanded(child: Text(bonus)), ElevatedButton(onPressed: () {}, child: const Text('Edit'))]);
  }
}
