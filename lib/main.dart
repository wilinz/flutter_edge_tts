import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dart_extensions/dart_extensions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_edge_tts/data/model/voices_list.dart';
import 'package:http/http.dart' as http;
import 'package:http_proxy/http_proxy.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'data/shared_preferences_helper.dart';

extension Uint8ListExtension on Uint8List {
  int indexOfSubList(List list, {int start = 0}) {
    if (list.isEmpty) {
      return -1;
    }
    if (start < 0) {
      start = 0;
    }
    for (var i = start; i < this.length - list.length + 1; i++) {
      if (this[i] == list[0]) {
        var match = true;
        for (var j = 1; j < list.length; j++) {
          if (this[i + j] != list[j]) {
            match = false;
            break;
          }
        }
        if (match) {
          return i;
        }
      }
    }
    return -1;
  }
}

class ProxiedHttpOverrides extends HttpOverrides {
  int port;
  String? host;

  ProxiedHttpOverrides({this.host = null, this.port = -1});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      // set proxy
      ..findProxy = (uri) {
        return host != null ? "PROXY $host:$port;" : 'DIRECT';
      };
  }
}

String getISOTime(DateTime date) {
  final formatter = DateFormat('EEE MMM dd yyyy HH:mm:ss \'GMT\'');
  final formattedDate = formatter.format(date.toUtc());
  return formattedDate;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // HttpOverrides.global = ProxiedHttpOverrides("127.0.0.1", 18888);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        ///打开 useMaterial3 样式
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Text-to-Speech')),
        body: TextToSpeech(),
      ),
    );
  }
}

class TextToSpeech extends StatefulWidget {
  @override
  _TextToSpeechState createState() => _TextToSpeechState();
}

class _TextToSpeechState extends State<TextToSpeech> {
  String _selectedLanguage = 'zh-CN';
  int _selectedVoice = 0;
  int _pitch = 0;
  int _rate = 0;
  String savePath = "";

  SharedPreferences? sharedPreferences;

  save<T>(String k, T v) async {
    final sp = sharedPreferences ??= await SharedPreferences.getInstance();
  }

  List<String> _languageList = [];
  Map<String, List<VoicesList>> _voiceList = {};

  TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initAsync();
    _fetchVoiceList();
  }

  initAsync() async {
    await _loadSharedPreferences();
    if (savePath.isNotEmpty) return;
    final dir = await getDownloadsDirectory();
    if (dir != null) {
      setState(() {
        savePath = join(dir.path, "tts.mp3");
      });
    }
  }

  Future<void> _loadSharedPreferences() async {
    _selectedLanguage = await SharedPreferencesHelper.getSelectedLanguage();
    _selectedVoice = await SharedPreferencesHelper.getSelectedVoice();
    _pitch = await SharedPreferencesHelper.getPitch();
    _rate = await SharedPreferencesHelper.getRate();
    savePath = await SharedPreferencesHelper.getSavePath();
    setState(() {});
  }

  String getGuid() => Uuid().v4().toString().replaceAll("-", "");

  Future<void> _fetchVoiceList() async {
    final response = await http.get(Uri.parse(
        'https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list?trustedclienttoken=6A5AA1D4EAFF4E9FB37E23D68491D6F4'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      final voiceList1 = voicesListListFormJson(
          data.map((e) => e as Map<String, dynamic>).toList());

      List<String> languageList =
          voiceList1.map((e) => e.locale).distinctBy((selector) => selector);
      Map<String, List<VoicesList>> voiceList =
          voiceList1.groupBy((it) => it.locale);

      setState(() {
        _voiceList = voiceList;
        _languageList = languageList;
      });
    } else {
      throw Exception('Failed to fetch voice list');
    }
  }

  String _numToString(int num) {
    return num >= 0 ? '+$num' : '$num';
  }

  String buildMessage(String header, String body) =>
      (header + "\n\n" + body).replaceAll("\n", "\r\n");

  Stream<Uint8List> _getAudio() {
    if (_textController.text.isEmpty) {
      throw Exception('Please enter text');
    }

    final audioConfig = buildMessage(
        """X-Timestamp:${getISOTime(DateTime.now())}
Content-Type:application/json; charset=utf-8
Path:speech.config""",
        jsonEncode({
          "context": {
            "synthesis": {
              "audio": {
                "metadataoptions": {
                  "sentenceBoundaryEnabled": "false",
                  "wordBoundaryEnabled": "true"
                },
                "outputFormat": "audio-24khz-48kbitrate-mono-mp3"
              }
            }
          }
        }));

    final ssmlText = buildMessage("""X-RequestId:${getGuid()}
Content-Type:application/ssml+xml
X-Timestamp:${getISOTime(DateTime.now())}
Path:ssml""",
        """<speak xmlns:mstts='https://www.w3.org/2001/mstts' version='1.0'
    xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='${_selectedLanguage}'>
    <voice name='${_voiceList[_selectedLanguage]![_selectedVoice].shortName}'>
        <prosody pitch='${_numToString(_pitch)}Hz' rate='${_numToString(_rate)}%' volume='+0%'>${_textController.text}</prosody>
    </voice>
</speak>""");

    final webSocketUrl =
        'wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1?TrustedClientToken=6A5AA1D4EAFF4E9FB37E23D68491D6F4&ConnectionId=' +
            getGuid();

    final channel =
        IOWebSocketChannel.connect(Uri.parse(webSocketUrl), headers: {
      "Accept-Encoding": "gzip, deflate, br",
      "Origin": "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold",
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.66 Safari/537.36 Edg/103.0.1264.44"
    });

    final streamController = StreamController<Uint8List>();
    final stream = streamController.stream;

    final audioSeparator = utf8.encode("Path:audio");

    channel.stream.listen((data) async {
      if (data is Uint8List) {
        Uint8List view = data;
        final index = view.indexOfSubList(audioSeparator);
        final dataBytes = view.sublist(index + 12);
        streamController.add(dataBytes);
      } else if (data is String) {
        if (data.contains("Path:turn.end")) {
          streamController.close();
        }
      }
    }, onError: (error) {
      streamController.addError(error);
    }, onDone: () {});

    channel.sink.add(audioConfig);
    channel.sink.add(ssmlText);

    return stream;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            labelText: 'Text',
            border: OutlineInputBorder(),
          ),
          maxLines: 15,
          onChanged: (text) {
            // Save the text to SharedPreferences
          },
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedLanguage,
          onChanged: (value) {
            setState(() {
              _selectedLanguage = value!;
              _selectedVoice = 0;
            });
            // Save the selected language to SharedPreferences
            SharedPreferencesHelper.setSelectedLanguage(value!);
          },
          items: _languageList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: 'Language',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: _selectedVoice,
          onChanged: (value) {
            setState(() {
              _selectedVoice = value!;
            });
            // Save the selected voice to SharedPreferences
            SharedPreferencesHelper.setSelectedVoice(value!);
          },
          items: _voiceList[_selectedLanguage]
              ?.asMap()
              .entries
              .map((entry) => DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value.shortName),
                  ))
              .toList(),
          decoration: InputDecoration(
            labelText: 'Voice',
            border: OutlineInputBorder(),
          ),
        ),
        Slider(
          value: _pitch.toDouble(),
          onChanged: (newValue) {
            setState(() {
              _pitch = newValue.round();
            });
            // Save the pitch to SharedPreferences
            SharedPreferencesHelper.setPitch(newValue.round());
          },
          min: -1200,
          max: 1200,
          divisions: 24,
          label: 'Pitch: ${_numToString(_pitch)}Hz',
        ),
        Slider(
          value: _rate.toDouble(),
          onChanged: (newValue) {
            setState(() {
              _rate = newValue.round();
            });
            // Save the rate to SharedPreferences
            SharedPreferencesHelper.setRate(newValue.round());
          },
          min: -50,
          max: 100,
          divisions: 15,
          label: 'Rate: ${_numToString(_rate)}%',
        ),
        FileSelector(
          onFileSelected: (path) {
            setState(() {
              savePath = path;
            });
            // Save the save path to SharedPreferences
            SharedPreferencesHelper.setSavePath(path);
          },
          defaultSavePath: savePath,
          defaultFileName: "tts.mp3",
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            start(context);
          },
          child: Text('开始'),
        ),
      ],
    );
  }

  start(BuildContext context) async {
    try {
      BuildContext? dialogContext = null;
      final file = File(savePath);
      final audioSink = _getAudio();
      final sink = file.openWrite();
      final sub = audioSink.listen((data) {
        sink.add(data);
      }, onError: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }, onDone: () {
        sink.close();
        if (dialogContext != null) {
          Navigator.of(dialogContext!).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("完成")),
        );
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context;
          return AlertDialog(
            title: Text("请稍候"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Center(child: CircularProgressIndicator()),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("取消"))
            ],
          );
        },
      ).then((o) {
        sub.cancel();
        dialogContext = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

bool isDesktop() =>
    (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

class FileSelector extends StatefulWidget {
  final String defaultFileName;
  final String defaultSavePath;
  final Function(String) onFileSelected;

  FileSelector({
    this.defaultFileName = '',
    this.defaultSavePath = '',
    required this.onFileSelected,
  });

  @override
  _FileSelectorState createState() => _FileSelectorState();
}

class _FileSelectorState extends State<FileSelector> {
  late String _fileName;
  late String _savePath;
  late TextEditingController _textEditingController;

  Future<void> _pickSavePath() async {
    if (isDesktop()) {
      final result = await FilePicker.platform.saveFile(
          dialogTitle: "保存文件",
          fileName: _fileName,
          initialDirectory: _savePath,
          type: FileType.audio,
          lockParentWindow: true);
      if (result != null) {
        setState(() {
          _savePath = result;
          _textEditingController.text = _savePath;
          widget.onFileSelected(result); // 回调函数
        });
      }
    } else {

    }
  }

  @override
  void initState() {
    super.initState();
    _fileName = widget.defaultFileName;
    _savePath = widget.defaultSavePath;
    _textEditingController = TextEditingController(text: _savePath);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textEditingController,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: '选择保存目录',
        suffixIcon: IconButton(
          onPressed: _pickSavePath,
          icon: Icon(Icons.folder_open_outlined),
        ),
      ),
    );
  }
}
