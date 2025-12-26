import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/livekit_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  Room? _room;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isMuted = false;

  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  late AnimationController _pulseController;

  String _roomName = 'voice-chat-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _requestPermissions();

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  Future<void> _connectToLiveKit() async {
    if (_isConnecting) return;

    setState(() => _isConnecting = true);

    try {
      final credentials = await LiveKitService.getToken(
        roomName: _roomName,
        participantName: 'User',
      );

      _room = Room();
      _room!.addListener(_onRoomUpdate);

      _room!.createListener().on<RoomEvent>((event) {
        if (event is TrackSubscribedEvent) {
          if (event.track is RemoteAudioTrack) {
            (event.track as RemoteAudioTrack).start();
          }
        } else if (event is ParticipantConnectedEvent) {
          _addSystemMessage('🤖 VoxAI joined the call');
        } else if (event is ParticipantDisconnectedEvent) {
          _addSystemMessage('🤖 VoxAI left the call');
        }
      });

      await _room!.connect(
        credentials['url']!,
        credentials['token']!,
        connectOptions: const ConnectOptions(autoSubscribe: true),
        roomOptions: const RoomOptions(
          defaultAudioCaptureOptions: AudioCaptureOptions(
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
          ),
        ),
      );

      await _room!.localParticipant?.setMicrophoneEnabled(true);

      setState(() {
        _isConnected = true;
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
      });
      _addSystemMessage('❌ Connection failed');
    }
  }

  void _onRoomUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleMicrophone() async {
    if (_room?.localParticipant != null) {
      final newMuted = !_isMuted;
      await _room!.localParticipant!.setMicrophoneEnabled(!newMuted);
      setState(() => _isMuted = newMuted);
    }
  }

  Future<void> _disconnect() async {
    if (_room != null) {
      await _room!.disconnect();
      _room!.removeListener(_onRoomUpdate);
      await _room!.dispose();
      _room = null;
    }

    setState(() {
      _isConnected = false;
      _isMuted = false;
    });

    _addSystemMessage('👋 Call ended');
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        sender: 'System',
        text: text,
        timestamp: DateTime.now(),
        isSystem: true,
      ));
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _disconnect();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF050816),
        title: const Text(
          'VoxAI',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Animated background circles
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.withOpacity(0.1 * _pulseController.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.green
                            .withOpacity(0.08 * (1 - _pulseController.value)),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content
          Column(
            children: [
              // Top avatar + compact status
              Container(
                padding:
                const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22C55E), Color(0xFF0EA5E9)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(
                                    0.4 * (0.5 + 0.5 * _pulseController.value)),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: Icon(
                              Icons.waves_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isConnected
                          ? 'On call with VoxAI'
                          : _isConnecting
                          ? 'Connecting...'
                          : 'Ready for a voice call',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isConnected
                              ? Icons.circle
                              : Icons.circle_outlined,
                          color:
                          _isConnected ? Colors.greenAccent : Colors.grey,
                          size: 10,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isConnecting
                              ? 'Connecting'
                              : _isConnected
                              ? 'Connected'
                              : 'Idle',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617).withOpacity(0.6),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: _messages.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.headset_mic_rounded,
                          size: 64,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Call updates appear here',
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return MessageBubble(message: msg);
                    },
                  ),
                ),
              ),

              // Bottom controls
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.transparent,
                  child: _isConnected
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleMicrophone,
                        icon: Icon(
                          _isMuted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          size: 20,
                        ),
                        label: Text(
                          _isMuted ? 'Unmute' : 'Mute',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isMuted
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _disconnect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                          shape: const CircleBorder(),
                        ),
                        child: const Icon(Icons.call_end_rounded),
                      ),
                    ],
                  )
                      : Center(
                    child: SizedBox(
                      width: 160,
                      child: ElevatedButton.icon(
                        onPressed:
                        _isConnecting ? null : _connectToLiveKit,
                        icon: _isConnecting
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.call_rounded, size: 20),
                        label: Text(
                          _isConnecting ? 'Calling...' : 'Start Call',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;
  final bool isSystem;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isSystem = false,
  });
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
