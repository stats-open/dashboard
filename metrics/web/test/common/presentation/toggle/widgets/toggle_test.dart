import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_theme_data.dart';
import 'package:metrics/common/presentation/toggle/theme/theme_data/toggle_theme_data.dart';
import 'package:metrics/common/presentation/toggle/widgets/toggle.dart';

import '../../../../test_utils/metrics_themed_testbed.dart';

void main() {
  group("Toggle", () {
    const inactiveColor = Colors.red;
    const activeColor = Colors.blue;
    const activeHoverColor = Colors.green;
    const inactiveHoverColor = Colors.yellow;
    const metricsTheme = MetricsThemeData(
      toggleTheme: ToggleThemeData(
        inactiveColor: inactiveColor,
        activeColor: activeColor,
        activeHoverColor: activeHoverColor,
        inactiveHoverColor: inactiveHoverColor,
      ),
    );
    final flutterSwitchFinder = find.byType(FlutterSwitch);
    final mouseRegionFinder = find.ancestor(
      of: flutterSwitchFinder,
      matching: find.byType(MouseRegion),
    );

    testWidgets(
      "throws an AssertionError if a value is null",
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const _ToggleTestbed(
            value: null,
          ),
        );

        expect(tester.takeException(), isAssertionError);
      },
    );

    testWidgets(
      "applies the given value to the flutter switch widget",
      (WidgetTester tester) async {
        const value = true;

        await tester.pumpWidget(const _ToggleTestbed(
          value: value,
        ));

        final switchWidget = tester.widget<FlutterSwitch>(flutterSwitchFinder);

        expect(switchWidget.value, equals(value));
      },
    );

    testWidgets(
      "applies the inactive color from the metrics theme",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ToggleTestbed(
          metricsThemeData: metricsTheme,
        ));

        final switchWidget = tester.widget<FlutterSwitch>(flutterSwitchFinder);

        expect(switchWidget.inactiveColor, equals(inactiveColor));
      },
    );

    testWidgets(
      "applies the active color from the metrics theme",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ToggleTestbed(
          metricsThemeData: metricsTheme,
        ));

        final switchWidget = tester.widget<FlutterSwitch>(flutterSwitchFinder);

        expect(switchWidget.activeColor, equals(activeColor));
      },
    );

    testWidgets(
      "applies the inactive hover color from the metrics theme when the toggle is hovered",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ToggleTestbed(
          metricsThemeData: metricsTheme,
        ));

        final mouseRegion = tester.widget<MouseRegion>(mouseRegionFinder);
        const pointerEnterEvent = PointerEnterEvent();
        mouseRegion.onEnter(pointerEnterEvent);

        await tester.pump();

        final switchWidget = tester.widget<FlutterSwitch>(flutterSwitchFinder);

        expect(switchWidget.inactiveColor, equals(inactiveHoverColor));
      },
    );

    testWidgets(
      "applies the active hover color from the metrics theme when the toggle is hovered",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ToggleTestbed(
          metricsThemeData: metricsTheme,
        ));

        final mouseRegion = tester.widget<MouseRegion>(mouseRegionFinder);
        const pointerEnterEvent = PointerEnterEvent();
        mouseRegion.onEnter(pointerEnterEvent);

        await tester.pump();

        final switchWidget = tester.widget<FlutterSwitch>(flutterSwitchFinder);

        expect(switchWidget.activeColor, equals(activeHoverColor));
      },
    );

    testWidgets(
      "calls the given on toggle callback once the value changed",
      (WidgetTester tester) async {
        const initialValue = true;
        bool value = initialValue;

        await tester.pumpWidget(
          _ToggleTestbed(
            value: value,
            onToggle: (newValue) => value = newValue,
          ),
        );

        await tester.tap(find.byType(Toggle));
        await tester.pumpAndSettle();

        expect(value, isNot(initialValue));
      },
    );
  });
}

/// A testbed class required to test the [Toggle] widget.
class _ToggleTestbed extends StatelessWidget {
  /// Indicates whether the [Toggle] is enabled or not.
  final bool value;

  /// A [MetricsThemeData] to use in tests.
  final MetricsThemeData metricsThemeData;

  /// A [ValueChanged] callback used to notify about [value] changed.
  final ValueChanged<bool> onToggle;

  /// Creates a new instance of the [_ToggleTestbed].
  ///
  /// The [value] defaults to `false`.
  /// The [metricsThemeData] defaults to an empty [MetricsThemeData] instance.
  const _ToggleTestbed({
    Key key,
    this.value = false,
    this.metricsThemeData = const MetricsThemeData(),
    this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MetricsThemedTestbed(
      metricsThemeData: metricsThemeData,
      body: Toggle(
        value: value,
        onToggle: onToggle,
      ),
    );
  }
}