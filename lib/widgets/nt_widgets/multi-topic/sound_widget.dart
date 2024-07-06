
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_text_input.dart';
import 'package:flutter/material.dart';

import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';

import 'package:elastic_dashboard/services/nt_connection.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

import 'package:path/path.dart' as path;
import 'dart:io';

//import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundWidgetModel extends NTWidgetModel {
  @override
  String type = SoundWidget.widgetType;

  final AudioPlayer player = AudioPlayer();

  String get soundToPlayTopic => '$topic/audio';
  String get incrementorTopic => '$topic/incrementor';
  String get loopingTopic => '$topic/loop';

  Object? previousIncrement;
  Object? previousLoop;

  String? directoryPath;

  SoundWidgetModel({required super.topic, super.dataType, super.period}) : super();

  @override
  SoundWidgetModel.fromJson({required Map<String, dynamic> jsonData})
      : super.fromJson(jsonData: jsonData) {
    directoryPath = tryCast(jsonData['directory_path']);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'directory_path': directoryPath,
    };
  }

  @override
  List<Object> getCurrentData() {
    String play =
        tryCast(ntConnection.getLastAnnouncedValue(soundToPlayTopic)) ?? "";
    double increment =
        tryCast(ntConnection.getLastAnnouncedValue(incrementorTopic)) ?? 0;
    bool loop = 
        tryCast(ntConnection.getLastAnnouncedValue(loopingTopic)) ?? false;
      return [play, increment, loop];
  }
  
  @override
  List<Widget> getEditProperties(BuildContext context) {
    return [
      DialogTextInput(
        label: 'Directory Path',
        initialText: directoryPath,
        onSubmit: (value) {
          directoryPath = value;
        },
      ),
    ];
  }

  void playSound(String toPlay, bool isLooping) async {
    
    // TODO: Find an os-compatible equivalent to %USERPROFILE%
    // var directory = await getDownloadsDirectory();

    if (isLooping) {
      player.setReleaseMode(ReleaseMode.loop);
    }
    else {
      player.setReleaseMode(ReleaseMode.stop);
    }
    
    // Any sound currently playing will be stopped (we can change this later if we want)
    await player.stop();

    if(directoryPath != null){
      String fullPath = path.join(path.normalize(directoryPath!), toPlay);
      if (await File(fullPath).exists()) {
        await player.play(DeviceFileSource(fullPath));
      } 
    }
  }
}


class SoundWidget extends NTWidget {
  static const String widgetType = 'Complex Sound';

  const SoundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    SoundWidgetModel model = cast(context.watch<NTWidgetModel>());

    return StreamBuilder(
      stream: model.subscription?.periodicStream(),
      initialData: ntConnection.getLastAnnouncedValue(model.topic),
      builder: (context, snapshot) {
        double? increment = tryCast(ntConnection.getLastAnnouncedValue(model.incrementorTopic));
        String toPlay = tryCast(ntConnection.getLastAnnouncedValue(model.soundToPlayTopic)) ?? "";
        bool isLooping = tryCast(ntConnection.getLastAnnouncedValue(model.loopingTopic)) ?? false;

        if (increment != tryCast(model.previousIncrement) &&
            increment != null && 
            model.previousIncrement != null) {

          // Needed to prevent errors
          Future(() async {
            // This stops sound from playing when a connection is established
            if (model.previousIncrement != null) {
              model.playSound(toPlay, isLooping);
            }
          });
        }

        else if (isLooping != tryCast(model.previousLoop)){
          Future(() async {
            // Stop looping audio
            model.player.setReleaseMode(ReleaseMode.stop);
            model.player.stop();
          });
        }


        model.previousIncrement = increment;
        model.previousLoop = isLooping; 

        return Row(
          children: [
            Flexible(
              child: TextField(
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.bottom,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 0.0, vertical: 10.0),
                  isDense: true,
                ),
                onTap: () {
                  model.playSound(toPlay, false);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
