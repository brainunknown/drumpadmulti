import 'dart:async';
import 'package:intl/intl.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drumpad/main.dart';

enum PlayerState { stopped, playing, paused }

class PlayerWidget extends StatefulWidget {
  final String url;
  final bool isLocal;
  final PlayerMode mode;
  final String value;
  final ValueChanged<String> childAction;

  PlayerWidget(
      {Key key,
      @required this.url,
      this.isLocal = false,
      this.mode = PlayerMode.MEDIA_PLAYER,
      this.value,
      this.childAction})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PlayerWidgetState(url, isLocal, mode);
  }
}

class _PlayerWidgetState extends State<PlayerWidget> {
  bool isFirstTime = true;
  String value = "0";
  int callTimeStamp = 0;
  bool audioLoaded = false;

  bool playerSink = true;

  String url;
  bool isLocal;
  PlayerMode mode;

  AudioPlayer _audioPlayer;
  AudioPlayerState _audioPlayerState;
  Duration _duration;
  Duration _position;

  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription _durationSubscription;
  StreamSubscription _positionSubscription;
  StreamSubscription _playerCompleteSubscription;
  StreamSubscription _playerErrorSubscription;
  StreamSubscription _playerStateSubscription;

  get _isPlaying => _playerState == PlayerState.playing;
  get _isPaused => _playerState == PlayerState.paused;
  get _durationText => _duration?.toString()?.split('.')?.first ?? '';
  get _positionText => _position?.toString()?.split('.')?.first ?? '';

  _PlayerWidgetState(this.url, this.isLocal, this.mode);

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerErrorSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  onStateChange() {
    //print("callTimeStamp $callTimeStamp");
    if (value == "load") {
      //print('play song $_isPlaying');
      if (!_isPlaying) {
        _play();
      }
    }
    if (value == "play") {
      //print('play song $_isPlaying');
      if (!_isPlaying) {
        _play();
      }
    }
    if (value == "pause") {
      _pause();
    }

    if (value != "load" && value != "play" && value != "pause") {
      _audioPlayer.seek(Duration(milliseconds: int.parse(value)));
    }

    print("changes $value");
  }

  void sendToParent(String val) {
    widget.childAction(val);
  }

  bool volMute = false;
  Widget widgetVol() {
    if (!volMute) {
      return IconButton(
          onPressed: () {
            volMute = true;
            _audioPlayer.setVolume(0.0);
          },
          iconSize: 32.0,
          icon: Icon(Icons.volume_up),
          color: Colors.cyan);
    } else {
      return IconButton(
          onPressed: () {
            volMute = false;
            _audioPlayer.setVolume(1.0);
          },
          iconSize: 32.0,
          icon: Icon(Icons.volume_off),
          color: Colors.cyan);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (value != ParentProvider.of(context).value) {
      value = ParentProvider.of(context).value;
      //callTimeStamp = ParentProvider.of(context).callTimeStamp;
      if (isFirstTime) {
        isFirstTime = false;
      } else {
        onStateChange();
      }
    }
    if (callTimeStamp != ParentProvider.of(context).callTimeStamp) {
      callTimeStamp = ParentProvider.of(context).callTimeStamp;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    onPressed: _isPlaying ? null : () => _play(),
                    iconSize: 32.0,
                    icon: Icon(Icons.play_arrow),
                    color: Colors.cyan),
                IconButton(
                    onPressed: _isPlaying ? () => _pause() : null,
                    iconSize: 32.0,
                    icon: Icon(Icons.pause),
                    color: Colors.cyan),
                /*IconButton(
                    onPressed: _isPlaying || _isPaused ? () => _stop() : null,
                    iconSize: 32.0,
                    icon: Icon(Icons.stop),
                    color: Colors.cyan),*/
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Stack(
                children: [
                  Slider(
                    onChanged: (v) {
                      final Position = v * _duration.inMilliseconds;
                      _audioPlayer
                          .seek(Duration(milliseconds: Position.round()));
                      if (playerSink) {
                        sendToParent(Position.round().toString());
                      }
                    },
                    value: (_position != null &&
                            _duration != null &&
                            _position.inMilliseconds > 0 &&
                            _position.inMilliseconds < _duration.inMilliseconds)
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0.0,
                  ),
                ],
              ),
            ),
            widgetVol(),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _position != null
                  ? '${_positionText ?? ''} / ${_durationText ?? ''}'
                  : _duration != null ? _durationText : '',
              style: TextStyle(fontSize: 12.0),
            ),
          ],
        ),
      ],
    );
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer(mode: mode);

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);

      // TODO implemented for iOS, waiting for android impl
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        // set atleast title to see the notification bar on ios.
        /*_audioPlayer.setNotification(
            title: 'App Name',
            artist: 'Artist or blank',
            albumTitle: 'Name or blank',
            imageUrl: 'url or blank',
            forwardSkipInterval: const Duration(seconds: 30), // default is 30s
            backwardSkipInterval: const Duration(seconds: 30), // default is 30s
            duration: duration,
            elapsedTime: Duration(seconds: 0));*/
      }
    });

    _positionSubscription =
        _audioPlayer.onAudioPositionChanged.listen((p) => setState(() {
              _position = p;
              if (!audioLoaded) {
                _pause();
                audioLoaded = true;
                sendToParent("loaded");
                _audioPlayer.seek(Duration(milliseconds: 0));
              }
              //print("start playing position changed");
            }));

    _playerCompleteSubscription =
        _audioPlayer.onPlayerCompletion.listen((event) {
      _onComplete();
      setState(() {
        _position = _duration;
      });
    });

    _playerErrorSubscription = _audioPlayer.onPlayerError.listen((msg) {
      print('audioPlayer error : $msg');
      setState(() {
        _playerState = PlayerState.stopped;
        _duration = Duration(seconds: 0);
        _position = Duration(seconds: 0);
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _audioPlayerState = state;
      });
    });
  }

  Future<int> _play() async {
    var now = new DateTime.now();
    //print(new DateFormat("dd-MM-yyyy hh:mm:ss").format(now)); // => 21-04-2019 02:40:25
    print("callTimeStamp $callTimeStamp");
    print("_play() ${new DateTime.now().millisecondsSinceEpoch}");
    //var date = new DateTime.fromMillisecondsSinceEpoch(callTimeStamp* 1000);
    //print("result ${new DateTime.now().difference(DateTime.parse(callTimeStamp.toString())).inMilliseconds}");
    final playPosition = (_position != null &&
            _duration != null &&
            _position.inMilliseconds > 0 &&
            _position.inMilliseconds < _duration.inMilliseconds)
        ? _position
        : null;
    final result =
        await _audioPlayer.play(url, isLocal: isLocal, position: playPosition);
    if (result == 1) setState(() => _playerState = PlayerState.playing);

    // TODO implemented for iOS, waiting for android impl
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // default playback rate is 1.0
      // this should be called after _audioPlayer.play() or _audioPlayer.resume()
      // this can also be called everytime the user wants to change playback rate in the UI
      //_audioPlayer.setPlaybackRate(playbackRate: 1.0);
    }

    print("play position ${_position.inMilliseconds}");

    return result;
  }

  Future<int> _pause() async {
    print("_pause() ${new DateTime.now().millisecond}");
    final result = await _audioPlayer.pause();
    if (result == 1) setState(() => _playerState = PlayerState.paused);
    print("pause position ${_position.inMilliseconds}");
    return result;
  }

  Future<int> _stop() async {
    final result = await _audioPlayer.stop();
    if (result == 1) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration();
      });
    }
    return result;
  }

  void _onComplete() {
    //isFirstTime = true;
    setState(() => _playerState = PlayerState.stopped);
  }
}
