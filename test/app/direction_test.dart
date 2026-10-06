import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// DsApp lays Arabic out right to left without flutter_localizations.
void main() {
  Future<TextDirection> directionFor(WidgetTester tester, Locale locale) async {
    late TextDirection seen;
    await tester.pumpWidget(
      DsApp(
        locale: locale,
        home: Builder(
          builder: (context) {
            seen = Directionality.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return seen;
  }

  testWidgets('Arabic is right to left, others left to right', (tester) async {
    expect(await directionFor(tester, const Locale('ar')), TextDirection.rtl);
    expect(await directionFor(tester, const Locale('tr')), TextDirection.ltr);
    expect(await directionFor(tester, const Locale('en')), TextDirection.ltr);
  });

  testWidgets('a delegate the app passes wins', (tester) async {
    late TextDirection seen;
    await tester.pumpWidget(
      DsApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [_Ltr()],
        home: Builder(
          builder: (context) {
            seen = Directionality.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, TextDirection.ltr);
  });
}

class _Ltr extends LocalizationsDelegate<WidgetsLocalizations> {
  const _Ltr();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      DefaultWidgetsLocalizations.load(locale);

  @override
  bool shouldReload(_Ltr old) => false;
}
