import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stream_webrtc_flutter/stream_webrtc_flutter.dart';

const offerOptions = {
  'iceRestart': true,
  'offerToReceiveAudio': true,
  'offerToReceiveVideo': true,
};

const iceServers = [
  {
    'urls': ['stun:stun.1.google.com:19302'],
  },
];

class Signaling extends ChangeNotifier {
  MediaStream? localStream;
  RTCPeerConnection? peerConnection;
  RTCSessionDescription? localDescription;
  final List<RTCIceCandidate> iceCandidates = [];

  bool get isInitialized => peerConnection != null && localStream != null;
  String get sdpType => localDescription?.type ?? 'offer';

  Future<void> initPeerConnection() async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    final peerConnection = await createPeerConnection({
      'iceServers': iceServers,
    });

    for (final track in stream.getTracks()) {
      await peerConnection.addTrack(track, stream);
    }

    this.peerConnection = peerConnection;
    localStream = stream;
    notifyListeners();

    peerConnection.onIceCandidate = (candidate) {
      iceCandidates.add(candidate);
      notifyListeners();
    };
  }

  Future<RTCSessionDescription> getOrCreateLocalDescription() async {
    if (localDescription == null) {
      final offer = await peerConnection!.createOffer(offerOptions);
      await peerConnection!.setLocalDescription(offer);
      localDescription = offer;
      notifyListeners();
    }
    return localDescription!;
  }

  Future<void> onRemoteDescriptionReceived(String? encodedDescription) async {
    if (encodedDescription == null) return;
    final remoteDescription = jsonDecode(encodedDescription);

    final type = remoteDescription['type'];
    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(remoteDescription['sdp'], type),
    );

    RTCSessionDescription? answer;
    if (type == 'offer') {
      answer = await peerConnection!.createAnswer(offerOptions);
      await peerConnection!.setLocalDescription(answer);
      localDescription = answer;
    }
    notifyListeners();
  }

  Future<void> onRemoteIceCandidatesReceived(String? encodedCandidates) async {
    if (encodedCandidates == null) return;
    final iceCandidates = jsonDecode(encodedCandidates) as List<dynamic>?;
    if (iceCandidates == null || iceCandidates.isEmpty) return;
    for (final iceCandidate in iceCandidates) {
      await peerConnection!.addCandidate(
        RTCIceCandidate(
          iceCandidate['candidate'],
          iceCandidate['sdpMid'],
          iceCandidate['sdpMLineIndex'],
        ),
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    peerConnection?.close();
    peerConnection = null;
    localStream = null;
    localDescription = null;
    iceCandidates.clear();
    super.dispose();
  }
}
