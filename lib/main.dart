import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_meetup_webrtc/input_dialog.dart';
import 'package:flutter_meetup_webrtc/signaling.dart';
import 'package:flutter_meetup_webrtc/video_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_webrtc_flutter/stream_webrtc_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebRTC Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CallPage(),
    );
  }
}

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final signaling = Signaling();

  @override
  void initState() {
    super.initState();
    _requestPermissions().then((_) {
      signaling.initPeerConnection();
    });
  }

  Future<void> _requestPermissions() async {
    final camera = await Permission.camera.request();
    final microphone = await Permission.microphone.request();
    if (camera.isDenied || microphone.isDenied) {
      return;
    }
  }

  @override
  void dispose() {
    signaling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: signaling,
      builder: (context, child) {
        if (!signaling.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(child: MyView(signaling: signaling)),
            Expanded(child: OtherView(signaling: signaling)),
          ],
        );
      },
    );
  }
}

class MyView extends StatelessWidget {
  const MyView({super.key, required this.signaling});
  final Signaling signaling;

  List<RTCIceCandidate> get iceCandidates => signaling.iceCandidates;
  String get sdpType => signaling.sdpType;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        VideoWidget(signaling.localStream!),
        Align(
          alignment: Alignment.bottomRight,
          child: ElevatedButton(
            onPressed: () async {
              var description = await signaling.getOrCreateLocalDescription();
              copyToClipboard(jsonEncode(description.toMap()));
            },
            child: Text('SDP ($sdpType)'),
          ),
        ),
        if (iceCandidates.isNotEmpty)
          Align(
            alignment: Alignment.bottomLeft,
            child: ElevatedButton(
              onPressed: () async {
                final jsonIceCandidates =
                    iceCandidates.map((e) => e.toMap()).toList();
                copyToClipboard(jsonEncode(jsonIceCandidates));
              },
              child: Text('ICE (${iceCandidates.length})'),
            ),
          ),
      ],
    );
  }
}

class OtherView extends StatelessWidget {
  const OtherView({super.key, required this.signaling});
  final Signaling signaling;

  @override
  Widget build(BuildContext context) {
    final remoteStreams = signaling.peerConnection?.getRemoteStreams() ?? [];

    return Stack(
      children: [
        if (remoteStreams.isEmpty)
          Placeholder()
        else
          VideoWidget(remoteStreams.first!),

        Align(
          alignment: Alignment.bottomRight,
          child: ElevatedButton(
            onPressed: () async {
              final result = await displayTextInputDialog(
                context,
                title: 'SDP',
              );
              signaling.onRemoteDescriptionReceived(result);
            },
            child: Text('SDP'),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: ElevatedButton(
            onPressed: () async {
              final result = await displayTextInputDialog(
                context,
                title: 'ICE',
              );
              signaling.onRemoteIceCandidatesReceived(result);
            },
            child: Text('ICE'),
          ),
        ),
      ],
    );
  }
}
