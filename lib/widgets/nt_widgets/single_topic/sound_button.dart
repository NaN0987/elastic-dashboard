import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:elastic_dashboard/services/nt_connection.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

import 'package:audioplayers/audioplayers.dart';

class SoundButton extends NTWidget {
  static const String widgetType = 'Sound Button';
  final AudioPlayer _player = AudioPlayer(); // NOTE: One audioplayer means that the sound can only be played once at a time

  SoundButton({super.key}) : super();

  @override
  Widget build(BuildContext context) {
    NTWidgetModel model = context.watch<NTWidgetModel>();

    return StreamBuilder(
        stream: model.subscription?.periodicStream(yieldAll: false),
        initialData: ntConnection.getLastAnnouncedValue(model.topic),
        builder: (context, snapshot) {
          // bool value = tryCast(snapshot.data) ?? false;

          String buttonText =
              model.topic.substring(model.topic.lastIndexOf('/') + 1);

          Size buttonSize = MediaQuery.of(context).size;

          ThemeData theme = Theme.of(context);

          return GestureDetector(
            onTapUp: (_) {
              //Checks if the topic needs to be published
              bool publishTopic = model.ntTopic == null ||
                  !ntConnection.isTopicPublished(model.ntTopic);

              model.createTopicIfNull();

              if (model.ntTopic == null) {
                return;
              }

              if (publishTopic) {
                ntConnection.nt4Client.publishTopic(model.ntTopic!);
              }

              // ntConnection.updateDataFromTopic(model.ntTopic!, !value);

              // Play sound when clicked
              _player.play(AssetSource('audio/one_minute_remaining.mp3'));
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: buttonSize.width * 0.01,
                  vertical: buttonSize.height * 0.01),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 10),
                width: buttonSize.width,
                height: buttonSize.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(2, 2),
                      blurRadius: 10.0,
                      spreadRadius: -5,
                      color: Colors.black,
                    ),
                  ],
                  color: const Color.fromARGB(255, 50, 50, 50),
                ),
                child: Center(
                    child: Text(
                  buttonText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                )),
              ),
            ),
          );
        });
  }
}
