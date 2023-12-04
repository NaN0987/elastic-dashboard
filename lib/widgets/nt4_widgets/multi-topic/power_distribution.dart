import 'package:dot_cast/dot_cast.dart';
import 'package:elastic_dashboard/services/nt4_connection.dart';
import 'package:elastic_dashboard/widgets/nt4_widgets/nt4_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PowerDistribution extends NT4Widget {
  static const String widgetType = 'PowerDistribution';
  @override
  String type = widgetType;

  static int numberOfChannels = 23;

  List<String> channelTopics = [];

  late String voltageTopic;
  late String currentTopic;

  PowerDistribution({super.key, required super.topic, super.period}) : super();

  PowerDistribution.fromJson({super.key, required super.jsonData})
      : super.fromJson();

  @override
  void init() {
    super.init();

    for (int channel = 0; channel <= numberOfChannels; channel++) {
      channelTopics.add('$topic/Chan$channel');
    }

    voltageTopic = '$topic/Voltage';
    currentTopic = '$topic/TotalCurrent';
  }

  @override
  void resetSubscription() {
    channelTopics.clear();

    for (int channel = 0; channel <= numberOfChannels; channel++) {
      channelTopics.add('$topic/Chan$channel');
    }

    voltageTopic = '$topic/Voltage';
    currentTopic = '$topic/TotalCurrent';

    super.resetSubscription();
  }

  Widget _getChannelsColumn(BuildContext context, int start, int end) {
    List<Widget> channels = [];

    for (int channel = start; channel <= end; channel++) {
      double current = tryCast(
              nt4Connection.getLastAnnouncedValue(channelTopics[channel])) ??
          0.0;

      channels.add(
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
              child: Text('${current.toStringAsFixed(2).padLeft(5, '0')} A',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            const SizedBox(width: 10),
            Text('Ch. ${channel.toString().padRight(2)}'),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [...channels],
    );
  }

  Widget _getReversedChannelsColumn(BuildContext context, int start, int end) {
    List<Widget> channels = [];

    for (int channel = start; channel >= end; channel--) {
      double current = tryCast(
              nt4Connection.getLastAnnouncedValue(channelTopics[channel])) ??
          0.0;

      channels.add(
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ch. $channel'),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
              child: Text('${current.toStringAsFixed(2).padLeft(5, '0')} A',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [...channels],
    );
  }

  @override
  Widget build(BuildContext context) {
    notifier = context.watch<NT4WidgetNotifier?>();

    return StreamBuilder(
      stream: subscription?.periodicStream(),
      builder: (context, snapshot) {
        double voltage =
            tryCast(nt4Connection.getLastAnnouncedValue(voltageTopic)) ?? 0.0;
        double totalCurrent =
            tryCast(nt4Connection.getLastAnnouncedValue(currentTopic)) ?? 0.0;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Voltage
                Column(
                  children: [
                    const Text('Voltage'),
                    const SizedBox(height: 2.5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '${voltage.toStringAsFixed(2).padLeft(5, '0')} V',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                // Current
                Column(
                  children: [
                    const Text('Total Current'),
                    const SizedBox(height: 2.5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '${totalCurrent.toStringAsFixed(2).padLeft(5, '0')} A',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Channel current
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // First 12 channels
                  _getChannelsColumn(context, 0, 11),
                  _getReversedChannelsColumn(context, 23, 12),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
