enum AppLocale {
  en('en', 'English'),
  zhTW('zh-TW', '繁體中文');

  final String code;
  final String displayName;
  const AppLocale(this.code, this.displayName);
}
