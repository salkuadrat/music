# Music Player

The easy way to play music in Flutter.

<img src="https://github.com/salkuadrat/music/raw/master/screenshot.png" alt="universe" width="360">

## Getting Started

Add dependency to your flutter project:

```
$ flutter pub add music
```

or

```yaml
dependencies:
  music: ^1.0.0
```

Then run `flutter pub get`.

## Permissions

For android, set `minSdkVersion` at your `android/app/build.gradle` to 21. Then add permissions to your AndroidManifest.xml.

```xml
<manifest xmlns:android...>
  ...
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.WAKE_LOCK" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
      android:maxSdkVersion="28"
      tools:ignore="ScopedStorage"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <application ...
</manifest>
```

Add service and receiver to AndroidManifest.xml.

```xml
<manifest xmlns:android...>
  ...
  <application ...>
    <service 
      android:name="com.salkuadrat.music.MusicPlayerService" 
      android:enabled="true"
      android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON"/>
      </intent-filter>
    </service>
    <receiver android:name="androidx.media.session.MediaButtonReceiver">
      <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON"/>
      </intent-filter>
    </receiver>
  </application>
</manifest>
```

## Usage 

```dart
import 'package:music/music.dart';
```

Initialize the player and music item.

```dart
MusicPlayer player = MusicPlayer(
  onLoading: _onLoading,
  onPlaying: _onPlaying,
  onPaused: _onPaused,
  onStopped: _onStopped,
  onCompleted: _onCompleted,
  onDuration: _onDuration,
  onPosition: _onPosition,
  onError: _onError,
);

Music music = Music(
  id: '_KzHGbpxMOY',
  artist: '88rising',
  title: 'Rich Brian, NIKI, & Warren Hue - California',
  image: 'https://i.ytimg.com/vi/_KzHGbpxMOY/mqdefault.jpg',
  url: 'https://media1.vocaroo.com/mp3/1ga9focwkrUs',
  duration: Duration(seconds: 230),
);
```

Start playing.

```dart
player.play(music);
```

Pause the music.

```dart
player.pause();
```

Resume the current playing music.

```dart
player.resume();
```

Stop playing.

```dart
player.stop();
```

## Example 

Learn more from example project [here](example). Also, you can learn the code while running the example application on device: [music.apk](music.apk).
