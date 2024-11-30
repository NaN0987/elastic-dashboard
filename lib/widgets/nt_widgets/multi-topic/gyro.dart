import 'package:elastic_dashboard/widgets/nt_widgets/single_topic/graph.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/single_topic/match_time.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/single_topic/number_bar.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/single_topic/number_slider.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/single_topic/radial_gauge.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/single_topic/text_display.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/single_topic/voltage_view.dart';
import 'package:flutter/material.dart';

import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import 'package:elastic_dashboard/services/nt4_client.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_toggle_switch.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

class GyroModel extends MultiTopicNTWidgetModel {
  @override
  String type = Gyro.widgetType;

  String get valueTopic => '$topic/Value';

  late NT4Subscription valueSubscription;
  late NT4Subscription doubleSubscription;

  @override
  List<NT4Subscription> get subscriptions => [valueSubscription, doubleSubscription];

  bool _counterClockwisePositive = false;

  get counterClockwisePositive => _counterClockwisePositive;

  set counterClockwisePositive(value) {
    _counterClockwisePositive = value;
    refresh();
  }

  GyroModel({
    required super.ntConnection,
    required super.preferences,
    required super.topic,
    bool counterClockwisePositive = false,
    super.dataType,
    super.period,
  })  : _counterClockwisePositive = counterClockwisePositive,
        super();

  GyroModel.fromJson({
    required super.ntConnection,
    required super.preferences,
    required Map<String, dynamic> jsonData,
  }) : super.fromJson(jsonData: jsonData) {
    _counterClockwisePositive =
        tryCast(jsonData['counter_clockwise_positive']) ?? false;
  }

  @override
  void initializeSubscriptions() {
    valueSubscription = ntConnection.subscribe(valueTopic, super.period);
    doubleSubscription = ntConnection.subscribe(topic, super.period);
  }

  @override
  List<String> getAvailableDisplayTypes() {
    if (doubleSubscription.value != null) {
      return [
          TextDisplay.widgetType,
          NumberBar.widgetType,
          NumberSlider.widgetType,
          VoltageView.widgetType,
          RadialGauge.widgetType,
          Gyro.widgetType,
          GraphWidget.widgetType,
          MatchTimeWidget.widgetType,
        ];
    }

    return [type];
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'counter_clockwise_positive': _counterClockwisePositive,
    };
  }

  @override
  List<Widget> getEditProperties(BuildContext context) {
    return [
      Center(
        child: DialogToggleSwitch(
          initialValue: _counterClockwisePositive,
          label: 'Counter Clockwise Positive',
          onToggle: (value) {
            counterClockwisePositive = value;
          },
        ),
      ),
    ];
  }
}

class Gyro extends NTWidget {
  static const String widgetType = 'Gyro';

  const Gyro({super.key}) : super();

  double _wrapAngle(double angle) {
    if (angle < 0) {
      return ((angle % 360) + 360) % 360;
    } else {
      return angle % 360;
    }
  }

  @override
  Widget build(BuildContext context) {
    GyroModel model = cast(context.watch<NTWidgetModel>());

    return ListenableBuilder(
      listenable: Listenable.merge(model.subscriptions),
      builder: (context, child) {
        double value = tryCast(model.valueSubscription.value) ?? tryCast(model.doubleSubscription.value) ?? 0.0;

        if (model.counterClockwisePositive) {
          value *= -1;
        }

        double angle = _wrapAngle(value);

        return Column(
          children: [
            Flexible(
              child: SfRadialGauge(
                axes: [
                  RadialAxis(
                    pointers: [
                      NeedlePointer(
                        value: angle,
                        needleColor: Colors.red,
                        needleEndWidth: 5,
                        needleStartWidth: 1,
                        needleLength: 0.7,
                        knobStyle: const KnobStyle(
                          borderColor: Colors.grey,
                          borderWidth: 0.025,
                        ),
                      )
                    ],
                    axisLineStyle: const AxisLineStyle(
                      thickness: 5,
                    ),
                    axisLabelStyle: const GaugeTextStyle(
                      fontSize: 14,
                    ),
                    ticksPosition: ElementsPosition.outside,
                    labelsPosition: ElementsPosition.outside,
                    showTicks: true,
                    minorTicksPerInterval: 8,
                    interval: 45,
                    minimum: 0,
                    maximum: 360,
                    startAngle: 270,
                    endAngle: 270,
                  )
                ],
              ),
            ),
            Text(angle.toStringAsFixed(2),
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        );
      },
    );
  }
}
