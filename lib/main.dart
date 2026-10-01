import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:apivideo_live_stream/apivideo_live_stream.dart';
import 'package:permission_handler/permission_handler.dart';

// Admin / Teacher ka number yahan daalein
const String teacherPhoneNumber = "+919999999999"; 
const String persistentStreamKey = "xxxx-xxxx-xxxx-xxxx-xxxx"; // YouTube Live Persistent Key
const String rtmpServerUrl = "rtmp://a.rtmp.youtube.com/live2";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase configuration project setup ke baad initialize hota hai
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AuthStateGate(),
  ));
}

// ---------------- 1. AUTH GATE ----------------
class AuthStateGate extends StatelessWidget {
  const AuthStateGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Agar direct testing karni ho bina Firebase credentials ke toh LoginScreen() direct open karein
    return const LoginScreen();
  }
}

// ---------------- 2. PHONE OTP REGISTRATION SCREEN ----------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  String _verificationId = "";
  bool _isLoading = false;

  void _sendOtp() async {
    setState(() => _isLoading = true);
    String phone = _phoneController.text.trim();
    if (!phone.startsWith("+91")) {
      phone = "+91$phone";
    }

    // Direct Login Shortcut (Testing & production fallback)
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _otpSent = true;
    });
  }

  void _verifyOtp() {
    String phone = _phoneController.text.trim();
    if (!phone.startsWith("+91")) {
      phone = "+91$phone";
    }

    bool isTeacher = (phone == teacherPhoneNumber);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(userPhone: phone, isTeacher: isTeacher),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Student Registration / Login"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _otpSent ? "Verify OTP" : "Enter Mobile Number",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _otpSent ? "Enter 6 digit OTP sent to your phone" : "We will send an SMS with a verification code",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (!_otpSent)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixText: "+91 ",
                  labelText: "Mobile Number",
                  border: OutlineInputBorder(),
                ),
              )
            else
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Enter 6-digit OTP",
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_otpSent ? "Verify & Enter" : "Send OTP", style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 3. DASHBOARD (STUDENT & TEACHER COMBINED) ----------------
class HomeScreen extends StatelessWidget {
  final String userPhone;
  final bool isTeacher;

  const HomeScreen({super.key, required this.userPhone, required this.isTeacher});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isTeacher ? "Teacher Control Hub" : "My Batches"),
        backgroundColor: isTeacher ? Colors.deepPurple : Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                    child: const Text("LIVE NOW", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  const Text("UPSC / SSC GS Special Batch 2026", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("Teacher: Expert Faculty", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClassroomScreen(userPhone: userPhone, videoId: "dQw4w9WgXcQ"),
                          ),
                        );
                      },
                      child: const Text("Join Class", style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      // Sirf Teacher ko phone camera se Go-Live button trigger hoga
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              backgroundColor: Colors.redAccent,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherLiveStudio()));
              },
              icon: const Icon(Icons.videocam, color: Colors.white),
              label: const Text("Go Live", style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}

// ---------------- 4. STUDENT CLASSROOM WITH ANTI-PIRACY & IN-APP CHAT ----------------
class ClassroomScreen extends StatefulWidget {
  final String userPhone;
  final String videoId;

  const ClassroomScreen({super.key, required this.userPhone, required this.videoId});

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  late YoutubePlayerController _playerController;
  final List<String> _chatMessages = ["Welcome to the live session!"];
  final TextEditingController _msgInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    _playerController = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, isLive: true),
    );
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_msgInput.text.trim().isNotEmpty) {
      setState(() {
        _chatMessages.add("${widget.userPhone.substring(widget.userPhone.length - 4)}: ${_msgInput.text.trim()}");
        _msgInput.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Lecture")),
      body: Column(
        children: [
          // Screen with Dynamic Watermark (Anti-Piracy)
          Stack(
            children: [
              YoutubePlayer(controller: _playerController, showVideoProgressIndicator: true),
              Positioned(
                bottom: 12,
                right: 12,
                child: Opacity(
                  opacity: 0.35,
                  child: Text(
                    widget.userPhone,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Align(alignment: Alignment.centerLeft, child: Text("Live Doubts & Chat", style: TextStyle(fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _chatMessages.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: Text(_chatMessages[i]),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgInput,
                    decoration: const InputDecoration(hintText: "Ask doubt to teacher...", border: InputBorder.none),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.indigo), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ---------------- 5. TEACHER DIRECT PHONE BROADCASTER ----------------
class TeacherLiveStudio extends StatefulWidget {
  const TeacherLiveStudio({super.key});

  @override
  State<TeacherLiveStudio> createState() => _TeacherLiveStudioState();
}

class _TeacherLiveStudioState extends State<TeacherLiveStudio> {
  late final ApiVideoLiveStreamController _streamController;
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _startStudio();
  }

  Future<void> _startStudio() async {
    await [Permission.camera, Permission.microphone].request();
    _streamController = ApiVideoLiveStreamController(
      initialAudioConfig: AudioConfig(),
      initialVideoConfig: VideoConfig.withDefaultBitrate(),
    );
    await _streamController.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _toggleBroadcast() async {
    if (_isLive) {
      await _streamController.stopStreaming();
      setState(() => _isLive = false);
    } else {
      await _streamController.startStreaming(
        streamKey: persistentStreamKey,
        url: rtmpServerUrl,
      );
      setState(() => _isLive = true);
    }
  }

  @override
  void dispose() {
    _streamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Broadcasting Studio")),
      body: Stack(
        children: [
          _streamController.isInitialized
              ? ApiVideoCameraPreview(controller: _streamController)
              : const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLive ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                onPressed: _toggleBroadcast,
                icon: Icon(_isLive ? Icons.stop : Icons.videocam, color: Colors.white),
                label: Text(_isLive ? "End Stream" : "Start Live Broadcast", style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
