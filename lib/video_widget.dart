import 'package:flutter/material.dart';
import 'package:stream_webrtc_flutter/stream_webrtc_flutter.dart';

class VideoWidget extends StatefulWidget {
  const VideoWidget(this.mediaStream, {super.key});
  final MediaStream mediaStream;

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  final _videoRenderer = RTCVideoRenderer();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideoRenderer();
  }

  @override
  void didUpdateWidget(covariant VideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mediaStream != oldWidget.mediaStream) {
      _videoRenderer.srcObject = widget.mediaStream;
      if (mounted) setState(() {});
    }
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    if (_isInitialized) _videoRenderer.srcObject = null;
    await _videoRenderer.dispose();
  }

  Future<void> _initVideoRenderer() async {
    await _videoRenderer.initialize();
    _videoRenderer.srcObject = widget.mediaStream;
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return RTCVideoView(_videoRenderer);
  }
}
