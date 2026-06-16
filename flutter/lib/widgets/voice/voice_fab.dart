import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/ai_voice_parser.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceFab extends StatelessWidget {
  const VoiceFab({super.key});

  static void showVoiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceRecordingModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showVoiceSheet(context),
      elevation: 4,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.mic_rounded, size: 28, color: Colors.white),
    );
  }
}

enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final bool isRecording;

  ChatMessage({
    required this.text,
    required this.sender,
    this.isRecording = false,
  });
}

class VoiceRecordingModal extends StatefulWidget {
  const VoiceRecordingModal({super.key});

  @override
  State<VoiceRecordingModal> createState() => _VoiceRecordingModalState();
}

class _VoiceRecordingModalState extends State<VoiceRecordingModal> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isProcessing = false;
  List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: "Halo! Silakan tekan tombol mikrofon di bawah dan sebutkan transaksi Anda (misalnya: 'Beli makan siang 50 ribu').",
      sender: MessageSender.ai,
    ));
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
             if (_isListening) {
                _stopListening();
             }
          }
        },
        onError: (val) {
          _addMessage("Error Mic: ${val.errorMsg}", MessageSender.ai);
          setState(() => _isListening = false);
        },
      );
    } catch (e) {
      _addMessage("Error inisialisasi: $e", MessageSender.ai);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addMessage(String text, MessageSender sender, {bool isRecording = false}) {
    setState(() {
      _messages.removeWhere((m) => m.isRecording);
      _messages.add(ChatMessage(text: text, sender: sender, isRecording: isRecording));
    });
    _scrollToBottom();
  }

  void _toggleListening() async {
    if (_isProcessing) return;

    if (_isListening) {
      _stopListening();
    } else {
      setState(() => _isListening = true);
      _addMessage("Mendengarkan...", MessageSender.user, isRecording: true);
      _speech.listen(
        onResult: (val) {
          if (val.recognizedWords.isNotEmpty) {
            _addMessage(val.recognizedWords, MessageSender.user, isRecording: true);
          }
        },
        localeId: 'id_ID',
      );
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    _speech.stop();
    setState(() => _isListening = false);

    String finalText = "";
    final recordingIndex = _messages.lastIndexWhere((m) => m.isRecording);
    if (recordingIndex != -1) {
      finalText = _messages[recordingIndex].text;
      if (finalText == "Mendengarkan...") finalText = "";
      
      setState(() {
        _messages.removeAt(recordingIndex);
        if (finalText.isNotEmpty) {
          _messages.add(ChatMessage(text: finalText, sender: MessageSender.user));
        }
      });
    }

    if (finalText.isEmpty) {
      _addMessage("Tidak ada suara yang terdeteksi.", MessageSender.ai);
      return;
    }

    setState(() => _isProcessing = true);
    _addMessage("Memproses Transaksi...", MessageSender.ai, isRecording: true);

    try {
      final parsedData = await AIVoiceParser.parseTransaction(finalText);

      if (!mounted) return;
      
      setState(() {
        _messages.removeWhere((m) => m.isRecording);
        _isProcessing = false;
        _messages.add(ChatMessage(
          text: "Selesai! Membuka halaman transaksi...",
          sender: MessageSender.ai,
        ));
      });
      _scrollToBottom();

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pop(context); // Close recording modal
          if (parsedData != null) {
            Navigator.pushNamed(context, '/add-transaction', arguments: parsedData);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.isRecording);
        _isProcessing = false;
        _messages.add(ChatMessage(
          text: "Gagal memproses: ${e.toString().replaceAll('Exception: ', '')}",
          sender: MessageSender.ai,
        ));
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Asisten Suara KUSKAS',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.sender == MessageSender.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        fontStyle: msg.isRecording ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? AppColors.error : AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? AppColors.error : AppColors.primary).withValues(alpha: 0.3),
                          blurRadius: _isListening ? 16 : 8,
                          spreadRadius: _isListening ? 4 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
