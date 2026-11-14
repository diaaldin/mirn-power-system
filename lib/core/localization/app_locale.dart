enum AppLanguage {
  arabic('ar', 'العربية', true),
  hebrew('he', 'עברית', true),
  english('en', 'English', false);

  final String code;
  final String label;
  final bool isRtl;

  const AppLanguage(this.code, this.label, this.isRtl);
}
