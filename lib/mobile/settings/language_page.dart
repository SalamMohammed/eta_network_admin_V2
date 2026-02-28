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
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Bahasa Indonesia',
                  selected: currentLocale.languageCode == 'id',
                  onTap: () => localeProvider.setLocale(const Locale('id')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Français',
                  selected: currentLocale.languageCode == 'fr',
                  onTap: () => localeProvider.setLocale(const Locale('fr')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Deutsch',
                  selected: currentLocale.languageCode == 'de',
                  onTap: () => localeProvider.setLocale(const Locale('de')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'ဗမာ',
                  selected: currentLocale.languageCode == 'my',
                  onTap: () => localeProvider.setLocale(const Locale('my')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'తెలుగు',
                  selected: currentLocale.languageCode == 'te',
                  onTap: () => localeProvider.setLocale(const Locale('te')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'नेपाली',
                  selected: currentLocale.languageCode == 'ne',
                  onTap: () => localeProvider.setLocale(const Locale('ne')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'বাংলা',
                  selected: currentLocale.languageCode == 'bn',
                  onTap: () => localeProvider.setLocale(const Locale('bn')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'मराठी',
                  selected: currentLocale.languageCode == 'mr',
                  onTap: () => localeProvider.setLocale(const Locale('mr')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'தமிழ்',
                  selected: currentLocale.languageCode == 'ta',
                  onTap: () => localeProvider.setLocale(const Locale('ta')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'ਪੰਜਾਬੀ',
                  selected: currentLocale.languageCode == 'pa',
                  onTap: () => localeProvider.setLocale(const Locale('pa')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'اردو',
                  selected: currentLocale.languageCode == 'ur',
                  onTap: () => localeProvider.setLocale(const Locale('ur')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'ไทย',
                  selected: currentLocale.languageCode == 'th',
                  onTap: () => localeProvider.setLocale(const Locale('th')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Русский',
                  selected: currentLocale.languageCode == 'ru',
                  onTap: () => localeProvider.setLocale(const Locale('ru')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Italiano',
                  selected: currentLocale.languageCode == 'it',
                  onTap: () => localeProvider.setLocale(const Locale('it')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Tagalog',
                  selected: currentLocale.languageCode == 'tl',
                  onTap: () => localeProvider.setLocale(const Locale('tl')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: '日本語',
                  selected: currentLocale.languageCode == 'ja',
                  onTap: () => localeProvider.setLocale(const Locale('ja')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'پښتو',
                  selected: currentLocale.languageCode == 'ps',
                  onTap: () => localeProvider.setLocale(const Locale('ps')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Yorùbá',
                  selected: currentLocale.languageCode == 'yo',
                  onTap: () => localeProvider.setLocale(const Locale('yo')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Fulfulde',
                  selected: currentLocale.languageCode == 'ff',
                  onTap: () => localeProvider.setLocale(const Locale('ff')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Hausa',
                  selected: currentLocale.languageCode == 'ha',
                  onTap: () => localeProvider.setLocale(const Locale('ha')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Igbo',
                  selected: currentLocale.languageCode == 'ig',
                  onTap: () => localeProvider.setLocale(const Locale('ig')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'فارسی',
                  selected: currentLocale.languageCode == 'fa',
                  onTap: () => localeProvider.setLocale(const Locale('fa')),
                ),
                SizedBox(height: s(12)),
                _LanguageTile(
                  scale: s,
                  title: 'Naijá',
                  selected: currentLocale.languageCode == 'pcm',
                  onTap: () => localeProvider.setLocale(const Locale('pcm')),
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
