// Voice Input Widget - Reusable widget for voice-to-text input
// Provides microphone button and recording dialog

import 'package:flutter/material.dart';
import '../services/speech_service.dart';

class VoiceInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String fieldName; // 'title' or 'content'
  final VoidCallback? onStart;
  final VoidCallback? onComplete;

  const VoiceInputWidget({
    super.key,
    required this.controller,
    required this.fieldName,
    this.onStart,
    this.onComplete,
  });

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with SingleTickerProviderStateMixin {
  final SpeechService _speechService = SpeechService.instance;
  bool _isListening = false;
  String _recognizedText = '';
  String _errorMessage = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _recognizedText = '';
      _errorMessage = '';
    });

    widget.onStart?.call();

    await _speechService.startListening(
      onResult: (text) {
        setState(() {
          _recognizedText = text;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = error;
          _isListening = false;
        });
        _animationController.stop();
      },
    );
  }

  Future<void> _stopListening() async {
    await _speechService.stopListening();

    setState(() {
      _isListening = false;
    });

    _animationController.stop();

    // Insert recognized text into controller
    if (_recognizedText.isNotEmpty) {
      final currentText = widget.controller.text;
      final newText = currentText.isEmpty
          ? _recognizedText
          : '$currentText $_recognizedText';
      widget.controller.text = newText;
    }

    widget.onComplete?.call();
  }

  void _showRecordingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Icon(
                  Icons.mic,
                  color: Colors.red.withOpacity(0.5 + _animationController.value * 0.5),
                  size: 32,
                );
              },
            ),
            const SizedBox(width: 12),
            Text('Listening to ${widget.fieldName}...'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_recognizedText.isNotEmpty) ...[
              const Text(
                'Recognized:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _recognizedText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ] else ...[
              const Center(
                child: Text(
                  'Start speaking...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_errorMessage.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _errorMessage = '';
                });
                _startListening();
                _showRecordingDialog();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () {
              _stopListening();
              Navigator.pop(context);
            },
            child: Text(_errorMessage.isNotEmpty ? 'Cancel' : 'Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isListening ? Icons.mic : Icons.mic_none,
        color: _isListening ? Colors.red : Colors.grey[700],
      ),
      tooltip: 'Voice input for ${widget.fieldName}',
      onPressed: () async {
        if (_isListening) {
          await _stopListening();
        } else {
          await _startListening();
          _showRecordingDialog();
        }
      },
    );
  }
}
