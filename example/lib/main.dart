import 'package:colour/colour.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:music/music.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => PlayerState(),
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  PlayerState get state => Provider.of<PlayerState>(context, listen: false);

  MusicPlayer? player;

  Music music = Music(
    id: '_KzHGbpxMOY',
    artist: '88rising',
    title: 'Rich Brian, NIKI, & Warren Hue - California',
    image: 'https://i.ytimg.com/vi/_KzHGbpxMOY/mqdefault.jpg',
    url: 'https://media1.vocaroo.com/mp3/1ga9focwkrUs',
    duration: Duration(seconds: 230),
  );

  @override
  void initState() {
    super.initState();
    player = MusicPlayer(
      onLoading: _onLoading,
      onPlaying: _onPlaying,
      onPaused: _onPaused,
      onStopped: _onStopped,
      onCompleted: _onCompleted,
      onDuration: _onDuration,
      onPosition: _onPosition,
      onError: _onError,
    );

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      player?.play(music);
    });
  }

  @override
  void dispose() {
    player?.dispose();
    super.dispose();
  }

  _onLoading() {
    print('Music player is loading...');
    state.startLoading();
  }

  _onPlaying() {
    print('Music player is playing');
    state.stopLoading();
    state.play();
  }

  _onPaused() {
    print('Music player is paused');
    state.pause();
  }

  _onStopped() {
    print('Music player is stopped');
    state.stop();
  }

  _onCompleted() {
    print('Music playing is ended');
    player?.pause();
  }

  _onDuration(Duration duration) {
    print('Music duration: ${duration.inMilliseconds} ms');
    state.duration = duration;
  }

  _onPosition(Duration position) {
    print('Current position: ${position.inMilliseconds} ms');
    state.position = position;
  }

  _onError(String message) {
    print('Music player error: $message');
  }

  Widget get _loading => SizedBox(
        width: 64,
        height: 64,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.white54),
        ),
      );

  Widget get _control => Container(
        width: 64,
        height: 64,
        margin: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(width: 2, color: Colors.white24),
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
        child: state.isLoading
            ? _loading
            : state.isPlaying
                ? IconButton(
                    icon: Icon(Icons.pause, color: Colors.white),
                    iconSize: 40,
                    onPressed: player?.pause,
                  )
                : IconButton(
                    icon: Icon(Icons.play_arrow_outlined, color: Colors.white),
                    iconSize: 40,
                    onPressed: player?.resume,
                  ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 1.0],
          colors: [Colour('1D6DBD'), Colour('43CEA2')],
        )),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Consumer<PlayerState>(
              builder: (_, state, __) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ExtendedImage.network(music.image, width: 120),
                  Gap(10),
                  Text(music.title, style: TextStyle(color: Colors.white)),
                  Gap(20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(durationStr(state.position),
                          style: TextStyle(color: Colors.white)),
                      _control,
                      Text(durationStr(state.duration),
                          style: TextStyle(color: Colors.white)),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerState extends ChangeNotifier {
  Duration _duration = Duration(milliseconds: 0);
  Duration _position = Duration(milliseconds: 0);
  bool _isPlaying = false;
  bool _isLoading = false;

  Duration get duration => _duration;
  Duration get position => _position;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;

  startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  play() {
    _isPlaying = true;
    notifyListeners();
  }

  pause() {
    _isPlaying = false;
    notifyListeners();
  }

  stop() {
    _isPlaying = false;
    notifyListeners();
  }

  set duration(Duration value) {
    _duration = value;
    notifyListeners();
  }

  set position(Duration value) {
    _position = value;
    notifyListeners();
  }
}

String durationStr(Duration dur) {
  String two(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  int hour = dur.inHours;
  int minute = dur.inMinutes.remainder(60);
  int second = dur.inSeconds.remainder(60);

  if (hour > 0) {
    return '${two(hour)}:${two(minute)}:${two(second)}';
  }

  return '${two(minute)}:${two(second)}';
}
