import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';

import 'package:decimal/decimal.dart';
import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';

import 'package:elastic_dashboard/services/nt4_client.dart';
import 'package:elastic_dashboard/services/nt_connection.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_text_input.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

import 'package:audioplayers/audioplayers.dart';

class SimpleSoundModel extends SingleTopicNTWidgetModel {
  @override
  String type = SimpleSound.widgetType;

  final AudioPlayer player = AudioPlayer();

  final TextEditingController controller = TextEditingController();

  Object? previousValue;

  String? _filePath;

  String? get filePath => _filePath;

  set filePath(value) {
    _filePath = value;
    refresh();
  }

  SimpleSoundModel({
    required super.topic,
    String? filePath,
    super.dataType,
    super.period,
  })  : _filePath = filePath,
        super();

  SimpleSoundModel.fromJson({required Map<String, dynamic> jsonData})
      : super.fromJson(jsonData: jsonData) {
    _filePath =
        tryCast(jsonData['file_path']);
  }

  @override
  List<Widget> getEditProperties(BuildContext context) {
    return [
      DialogTextInput(
        label: 'File Path',
        initialText: filePath,
        onSubmit: (value) {
          filePath = value;
        },
      ),
    ];
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'file_path': _filePath,
    };
  }

  void publishData(String value) {
    bool publishTopic =
        ntTopic == null || !ntConnection.isTopicPublished(ntTopic!);

    createTopicIfNull();

    if (ntTopic == null) {
      return;
    }

    late Object? formattedData;

    String dataType = ntTopic!.type;
    switch (dataType) {
      case NT4TypeStr.kBool:
        formattedData = bool.tryParse(value);
        break;
      case NT4TypeStr.kFloat32:
      case NT4TypeStr.kFloat64:
        formattedData = double.tryParse(value);
        break;
      case NT4TypeStr.kInt:
        formattedData = int.tryParse(value);
        break;
      case NT4TypeStr.kString:
        formattedData = value;
        break;
      case NT4TypeStr.kFloat32Arr:
      case NT4TypeStr.kFloat64Arr:
        formattedData = tryCast<List<dynamic>>(jsonDecode(value))
            ?.whereType<num>()
            .toList();
        break;
      case NT4TypeStr.kIntArr:
        formattedData = tryCast<List<dynamic>>(jsonDecode(value))
            ?.whereType<num>()
            .toList();
        break;
      case NT4TypeStr.kBoolArr:
        formattedData = tryCast<List<dynamic>>(jsonDecode(value))
            ?.whereType<bool>()
            .toList();
        break;
      case NT4TypeStr.kStringArr:
        formattedData = tryCast<List<dynamic>>(jsonDecode(value))
            ?.whereType<String>()
            .toList();
        break;
      default:
        break;
    }

    if (publishTopic) {
      ntConnection.nt4Client.publishTopic(ntTopic!);
    }

    if (formattedData != null) {
      ntConnection.updateDataFromTopic(ntTopic!, formattedData);
    }

    previousValue = value;
  }

  void playSound() async {
    
    // var directory = await getDownloadsDirectory();

    // if (directory != null) {
    //   print(directory.path);
    //   var userDirectory = directory.parent.path;
    // }

    // print("Current Filepath: $filePath");

    try {
      // Any sound currently playing will be stopped (we can change this later if we want)
      await player.stop();
      await player.play(DeviceFileSource(_filePath ?? ""));
    }
    // The file path is incorrect
    //on PlatformException catch(_) {}
    //on AudioPlayerException catch(_) {}
    catch(e) {
      //rethrow;
    }
  }
}

class SimpleSound extends NTWidget {
  static const String widgetType = 'Simple Sound';

  const SimpleSound({super.key});

  @override
  Widget build(BuildContext context) {
    SimpleSoundModel model = cast(context.watch<NTWidgetModel>());

    return StreamBuilder(
      stream: model.subscription?.periodicStream(),
      initialData: ntConnection.getLastAnnouncedValue(model.topic),
      builder: (context, snapshot) {
        Object? data = snapshot.data;

        if (data?.toString() != model.previousValue?.toString() &&
            data != null) {
          // Needed to prevent errors
          Future(() async {
            String displayString = data.toString();
            if (data is double) {
              if (cast<double>(data).abs() > 1e-10) {
                displayString = Decimal.parse(data.toString()).toString();
              } else {
                data = 0.0 * cast<double>(data).sign;
                displayString = data.toString();
              }
            }
            model.controller.text = displayString;

            // This stops sound from playing when a connection is established
            if (model.previousValue != null){
              model.playSound();
            }

            model.previousValue = data;
          });
        }

        return Row(
          children: [
            Flexible(
              child: TextField(
                controller: model.controller,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.bottom,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 0.0, vertical: 10.0),
                  isDense: true,
                ),
                onTap: () {
                  model.playSound();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
