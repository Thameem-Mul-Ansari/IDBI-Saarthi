import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const SaarthiApp());
}

class SaarthiApp extends StatelessWidget {
  const SaarthiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saarthi AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF0F7D77),
        scaffoldBackgroundColor: const Color(0xFFF3F6F5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F7D77)),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToChat();
  }

  Future<void> _goToChat() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AvatarChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/idbi_logo.png',
              height: 90,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F7D77).withOpacity(0.1),
                ),
                child: const Icon(Icons.account_balance,
                    size: 44, color: Color(0xFF0F7D77)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'IDBI Saarthi',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F7D77),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your virtual banking assistant',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF0F7D77),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, DateTime? time})
      : time = time ?? DateTime.now();
}

class AvatarChatScreen extends StatefulWidget {
  const AvatarChatScreen({super.key});

  @override
  State<AvatarChatScreen> createState() => _AvatarChatScreenState();
}

class _AvatarChatScreenState extends State<AvatarChatScreen> {
  InAppWebViewController? _webViewController;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(text: "Hello, how can I help you manage your wealth today?", isUser: false),
  ];

  bool _avatarReady = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _interimText = '';

  late final String _cogSvcRegion;
  late final String _cogSvcSubKey;
  late final String _avatarCharacter;
  late final String _avatarStyle;
  late final String _ttsVoice;
  late final String _sttLocales;
  late final String _systemPrompt;

  late final String _aoaiApiKey;
  late final String _aoaiEndpoint;
  late final String _aoaiApiVersion;
  late final String _aoaiDeployment;

  @override
  void initState() {
    super.initState();
    _cogSvcRegion = dotenv.env['cogSvcRegion'] ?? '';
    _cogSvcSubKey = dotenv.env['cogSvcSubKey'] ?? '';
    _avatarCharacter = dotenv.env['talkingAvatarCharacter'] ?? 'lisa';
    _avatarStyle = dotenv.env['talkingAvatarStyle'] ?? 'casual-sitting';
    _ttsVoice = dotenv.env['ttsVoice'] ?? 'en-US-AvaMultilingualNeural';
    _sttLocales = dotenv.env['sttLocales'] ?? 'en-US,hi-IN';

    // UPDATED: Instruct the LLM to write out numbers and be multilingual
    _systemPrompt = dotenv.env['systemPrompt'] ??
        'You are a helpful multilingual assistant. Always respond in the same language the user speaks. When mentioning large numbers, especially Indian currency, write them out in words (e.g., say "5 lakhs" instead of "500000" or "5,00,000") so they are pronounced naturally by the text-to-speech engine.';

    _aoaiApiKey = dotenv.env['AZURE_OPENAI_API_KEY'] ?? '';
    _aoaiEndpoint = dotenv.env['AZURE_OPENAI_ENDPOINT'] ?? '';
    _aoaiApiVersion = dotenv.env['AZURE_OPENAI_API_VERSION'] ?? '2023-05-15';
    _aoaiDeployment = dotenv.env['AZURE_OPENAI_DEPLOYMENT_NAME'] ?? 'gpt-4o';
  }

  @override
  void dispose() {
    _webViewController?.evaluateJavascript(source: "closeAvatarSession();");
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    _webViewController = controller;

    controller.addJavaScriptHandler(
      handlerName: 'avatarStatus',
      callback: (args) {
        final status = args.isNotEmpty ? args[0].toString() : '';
        if (status.startsWith('error:')) {
          debugPrint('Avatar error: $status');
          return;
        }
        setState(() {
          _avatarReady = status == 'ready';
          // UPDATED: Make the avatar speak automatically as soon as it's ready
          if (_avatarReady && _messages.length == 1) {
            _speak(_messages.first.text);
          }
        });
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'sttStatus',
      callback: (args) {
        final status = args.isNotEmpty ? args[0].toString() : '';
        setState(() => _isListening = status == 'listening');
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'sttInterim',
      callback: (args) {
        final text = args.isNotEmpty ? args[0].toString() : '';
        setState(() => _interimText = text);
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'sttResult',
      callback: (args) {
        final text = args.isNotEmpty ? args[0].toString() : '';
        setState(() => _interimText = '');
        if (text.trim().isNotEmpty) {
          _sendMessage(text);
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'speakingStateChanged',
      callback: (args) {
        final state = args.isNotEmpty ? args[0].toString() : '';
        setState(() => _isSpeaking = state == 'speaking');
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'speakError',
      callback: (args) {
        final message = args.isNotEmpty ? args[0].toString() : 'Unknown error';
        debugPrint('WebView JS Error/Warning: $message');
        if (mounted) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
          );
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'avatarEvent',
      callback: (args) {
        debugPrint('Avatar event: ${args.isNotEmpty ? args[0] : ''}');
      },
    );
  }

  Future<void> _onLoadStop(InAppWebViewController controller, Uri? url) async {
    final js = "initAvatar("
        "${jsonEncode(_cogSvcRegion)}, "
        "${jsonEncode(_cogSvcSubKey)}, "
        "${jsonEncode(_avatarCharacter)}, "
        "${jsonEncode(_avatarStyle)}, "
        "${jsonEncode(_ttsVoice)}"
        ");";
    await controller.evaluateJavascript(source: js);
  }

  Future<void> _speak(String text) async {
    if (_webViewController == null) return;
    await _webViewController!
        .evaluateJavascript(source: "speak(${jsonEncode(text)});");
  }

  Future<void> _toggleMic() async {
    if (_webViewController == null || !_avatarReady) return;

    if (_isListening) {
      await _webViewController!.evaluateJavascript(source: "stopRecognition();");
      setState(() => _isListening = false);
    } else {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                micStatus.isPermanentlyDenied
                    ? 'Microphone permission is denied. Enable it in Settings to use voice input.'
                    : 'Microphone permission is required for voice input.',
              ),
              action: micStatus.isPermanentlyDenied
                  ? SnackBarAction(label: 'Settings', onPressed: openAppSettings)
                  : null,
            ),
          );
        }
        return;
      }

      if (_isSpeaking) {
        await _webViewController!.evaluateJavascript(source: "stopSpeaking();");
        await Future.delayed(const Duration(milliseconds: 300));
      }

      setState(() => _interimText = '');

      final js = "startRecognition("
          "${jsonEncode(_cogSvcRegion)}, "
          "${jsonEncode(_cogSvcSubKey)}, "
          "${jsonEncode(_sttLocales)}"
          ");";
      await _webViewController!.evaluateJavascript(source: js);
      setState(() => _isListening = true);
    }
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = (overrideText ?? _inputController.text).trim();
    if (text.isEmpty) return;

    if (_isListening) {
      await _webViewController?.evaluateJavascript(source: "stopRecognition();");
      setState(() => _isListening = false);
    }

    setState(() => _messages.add(ChatMessage(text: text, isUser: true)));
    _inputController.clear();
    _scrollToBottom();

    final reply = await _getBotReply(text);

    setState(() => _messages.add(ChatMessage(text: reply, isUser: false)));
    _scrollToBottom();

    await _speak(reply);
  }

  Future<String> _getBotReply(String userText) async {
    if (_aoaiEndpoint.trim().isEmpty || _aoaiApiKey.trim().isEmpty) {
      return "Azure OpenAI isn't configured yet — add AZURE_OPENAI_ENDPOINT and AZURE_OPENAI_API_KEY to your .env.";
    }

    final endpoint = _aoaiEndpoint.trim().endsWith('/')
        ? _aoaiEndpoint.trim().substring(0, _aoaiEndpoint.trim().length - 1)
        : _aoaiEndpoint.trim();

    final uri = Uri.parse(
      '$endpoint/openai/deployments/$_aoaiDeployment/chat/completions?api-version=$_aoaiApiVersion',
    );

    final history = _messages.length > 12
        ? _messages.sublist(_messages.length - 12)
        : _messages;

    final apiMessages = [
      {'role': 'system', 'content': _systemPrompt},
      for (final m in history)
        {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
    ];

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'api-key': _aoaiApiKey,
        },
        body: jsonEncode({
          'messages': apiMessages,
          'max_tokens': 400,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Azure OpenAI error ${response.statusCode}: ${response.body}');
        return "Sorry, I ran into a problem reaching the assistant service.";
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return "Sorry, I didn't get a response. Please try again.";
      }
      final content = choices.first['message']?['content'] as String?;
      final trimmed = (content ?? '').trim();
      return trimmed.isEmpty
          ? "Sorry, I didn't get a response. Please try again."
          : trimmed;
    } catch (e) {
      debugPrint('Azure OpenAI call failed: $e');
      return "Sorry, something went wrong talking to the assistant.";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildAvatarArea(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) =>
                    _buildMessageBubble(_messages[index]),
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F7D77)),
            onPressed: () => Navigator.maybePop(context),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF5821F), width: 2),
            ),
            child: const Icon(Icons.person, color: Color(0xFFF5821F), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'IDBI Saarthi',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.black87),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _avatarReady ? 'online' : 'connecting…',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF0F7D77)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarArea() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.42,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFF0F7D77)),
          InAppWebView(
            initialFile: "assets/avatar_webview.html",
            initialSettings: InAppWebViewSettings(
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              useHybridComposition: true,
              transparentBackground: true,
            ),
            onWebViewCreated: _onWebViewCreated,
            onLoadStop: _onLoadStop,
            onPermissionRequest: (controller, request) async {
              return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              );
            },
            onConsoleMessage: (controller, message) {
              debugPrint('Avatar WebView Console: ${message.message}');
            },
          ),
          if (!_avatarReady)
            Container(
              color: const Color(0xFF0F7D77).withOpacity(0.85),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text('Connecting to avatar…',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          if (_avatarReady && (_isListening || _isSpeaking))
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isListening
                        ? (_interimText.isNotEmpty ? 'Listening: $_interimText' : 'Listening…')
                        : 'Speaking…',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final time = TimeOfDay.fromDateTime(message.time).format(context);

    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(message.text,
                  style: const TextStyle(fontSize: 15, color: Colors.black87)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all,
                      size: 14, color: Color(0xFF0F7D77)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, right: 6),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFDDEFEC),
              child: Icon(Icons.person, size: 16, color: Color(0xFF0F7D77)),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7),
            decoration: BoxDecoration(
              color: const Color(0xFFDCF3EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.text,
                    style:
                    const TextStyle(fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(time,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _toggleMic,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: _isListening ? Colors.red : const Color(0xFFF5821F),
                child: Icon(_isListening ? Icons.stop : Icons.mic_none,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF0F7D77),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}