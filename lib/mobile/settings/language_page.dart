import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/locale_provider.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    double s(double size) => size * MediaQuery.of(context).size.width / 390;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectLanguage),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1620), Color(0xFF0E1618)],
          ),
        ),
        child: AnimatedBuilder(
          animation: localeProvider,
          builder: (context, _) {
            final currentLocale = localeProvider.locale;
            return ListView(
              padding: EdgeInsets.all(s(16)),
              children: [
                _LanguageTile(
                  scale: s,
                  title: 'English',
                  selected: currentLocale.languageCode == 'en',
                  onTap: () => localeProvider.setLocale(const Locale('en')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Español',
                  selected: currentLocale.languageCode == 'es',
                  onTap: () => localeProvider.setLocale(const Locale('es')),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final double Function(double) scale;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.scale,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(scale(18)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: scale(20),
          vertical: scale(16),
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(scale(18)),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: scale(16),
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.white70,
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, color: Colors.white, size: scale(20)),
          ],
        ),
      ),
    );
  }
}
