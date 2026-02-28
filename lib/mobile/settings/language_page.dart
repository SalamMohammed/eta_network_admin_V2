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
                  title: '繁體中文',
                  selected:
                      currentLocale.languageCode == 'zh' &&
                      currentLocale.scriptCode == 'Hant',
                  onTap: () => localeProvider.setLocale(
                    const Locale.fromSubtags(
                      languageCode: 'zh',
                      scriptCode: 'Hant',
                    ),
                  ),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: '简体中文',
                  selected:
                      currentLocale.languageCode == 'zh' &&
                      currentLocale.scriptCode != 'Hant',
                  onTap: () => localeProvider.setLocale(const Locale('zh')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'हिंदी',
                  selected: currentLocale.languageCode == 'hi',
                  onTap: () => localeProvider.setLocale(const Locale('hi')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Tiếng Việt',
                  selected: currentLocale.languageCode == 'vi',
                  onTap: () => localeProvider.setLocale(const Locale('vi')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Bahasa Melayu',
                  selected: currentLocale.languageCode == 'ms',
                  onTap: () => localeProvider.setLocale(const Locale('ms')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: '한국어',
                  selected: currentLocale.languageCode == 'ko',
                  onTap: () => localeProvider.setLocale(const Locale('ko')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Española',
                  selected: currentLocale.languageCode == 'es',
                  onTap: () => localeProvider.setLocale(const Locale('es')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Türk',
                  selected: currentLocale.languageCode == 'tr',
                  onTap: () => localeProvider.setLocale(const Locale('tr')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Português',
                  selected: currentLocale.languageCode == 'pt',
                  onTap: () => localeProvider.setLocale(const Locale('pt')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'العربية',
                  selected: currentLocale.languageCode == 'ar',
                  onTap: () => localeProvider.setLocale(const Locale('ar')),
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
