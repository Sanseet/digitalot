import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

const String backendUrl = 'https://iot-server-opc9.onrender.com';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late stt.SpeechToText _speech;
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  String _lastCommand = '';
  Timer? _dataFetchTimer;
  Map<String, dynamic> sensorData = {
    'temperature': '0°C',
    'humidity': '0%',
    'accX': '0',
    'accY': '0',
    'accZ': '0',
    'pir': false,
    'relays': {
      'relay1': false, // Added relay1
      'relay2': false,
      'relay3': false,
      'relay4': false,
    }
  };

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeechRecognition();
    _initializeTextToSpeech();
    fetchData();
    _dataFetchTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) => fetchData());
  }

  @override
  void dispose() {
    _dataFetchTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initializeSpeechRecognition() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => print('Speech recognition error: $error'),
    );
    if (!available) {
      debugPrint('Speech recognition not available');
    }
  }

  Future<void> _initializeTextToSpeech() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _listen() async {
    if (!_isListening) {
      // First time initializing
      if (!_speech.isAvailable) {
        var available = await _speech.initialize(
          onStatus: (status) {
            print('Speech recognition status: $status');
            if (status == 'notListening') {
              setState(() => _isListening = false);
            }
          },
          onError: (error) => print('Speech recognition error: $error'),
        );

        if (!available) {
          _speak("Speech recognition is not available on this device");
          return;
        }
      }

      // Start listening
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _lastCommand = result.recognizedWords.toLowerCase();
            if (result.finalResult) {
              _processVoiceCommand(_lastCommand);
            }
          });
        },
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        partialResults: true,
      );
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  void _processVoiceCommand(String command) {
    debugPrint('Command received: $command');

    if (command.contains('temperature')) {
      _speak('The temperature is ${sensorData['temperature']}');
    } else if (command.contains('humidity')) {
      _speak('The humidity is ${sensorData['humidity']}');
    } else if (command.contains('motion') || command.contains('movement')) {
      _speak(
          'Motion detection is ${sensorData['pir'] ? 'active' : 'inactive'}');
    } else if (command.contains('turn on relay 1') ||
        command.contains('turn on relay one')) {
      _updateRelay('relay1', true);
      _speak('Turning on relay 1');
    } else if (command.contains('turn off relay 1') ||
        command.contains('turn off relay one')) {
      _updateRelay('relay1', false);
      _speak('Turning off relay 1');
    } else if (command.contains('turn on relay 2') ||
        command.contains('turn on relay two')) {
      _updateRelay('relay2', true);
      _speak('Turning on relay 2');
    } else if (command.contains('turn off relay 2') ||
        command.contains('turn off relay two')) {
      _updateRelay('relay2', false);
      _speak('Turning off relay 2');
    } else if (command.contains('turn on relay 3') ||
        command.contains('turn on relay three')) {
      _updateRelay('relay3', true);
      _speak('Turning on relay 3');
    } else if (command.contains('turn off relay 3') ||
        command.contains('turn off relay three')) {
      _updateRelay('relay3', false);
      _speak('Turning off relay 3');
    } else if (command.contains('turn on relay 4') ||
        command.contains('turn on relay four')) {
      _updateRelay('relay4', true);
      _speak('Turning on relay 4');
    } else if (command.contains('turn off relay 4') ||
        command.contains('turn off relay four')) {
      _updateRelay('relay4', false);
      _speak('Turning off relay 4');
    } else {
      _speak('Command not recognized. Please try again.');
    }
  }

  Future<void> _updateRelay(String relay, bool state) async {
    try {
      final updatedRelays = Map<String, bool>.from(sensorData['relays']);
      updatedRelays[relay] = state;

      final response = await http.post(
        Uri.parse('$backendUrl/relays'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedRelays),
      );

      if (response.statusCode == 200) {
        setState(() {
          sensorData['relays'] = updatedRelays;
        });
      } else {
        _speak('Failed to update $relay');
      }
    } catch (e) {
      debugPrint("Error updating relay: $e");
      _speak('Error updating $relay');
    }
  }

  Future<void> fetchData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$backendUrl/dht/latest')),
        http.get(Uri.parse('$backendUrl/mpu6050/latest')),
        http.get(Uri.parse('$backendUrl/pir')),
        http.get(Uri.parse('$backendUrl/relays')),
      ]);

      if (responses.every((response) => response.statusCode == 200)) {
        final dhtData = jsonDecode(responses[0].body);
        final mpuData = jsonDecode(responses[1].body);
        final pirData = jsonDecode(responses[2].body);
        final relaysData = jsonDecode(responses[3].body);

        setState(() {
          sensorData['temperature'] = "${dhtData['temperature'] ?? '0'}°C";
          sensorData['humidity'] = "${dhtData['humidity'] ?? '0'}%";
          sensorData['accX'] = mpuData['accX']?.toString() ?? '0';
          sensorData['accY'] = mpuData['accY']?.toString() ?? '0';
          sensorData['accZ'] = mpuData['accZ']?.toString() ?? '0';
          sensorData['pir'] = pirData == true;

          sensorData['relays'] = {
            'relay1':
                relaysData['relay1'] ?? false, // Ensuring relay1 is fetched
            'relay2': relaysData['relay2'] ?? false,
            'relay3': relaysData['relay3'] ?? false,
            'relay4': relaysData['relay4'] ?? false,
          };
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  Future<void> toggleRelay(String relay) async {
    try {
      final updatedRelays = Map<String, bool>.from(sensorData['relays']);
      updatedRelays[relay] = !updatedRelays[relay]!;

      final response = await http.post(
        Uri.parse('$backendUrl/relays'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedRelays),
      );

      if (response.statusCode == 200) {
        setState(() {
          sensorData['relays'] = updatedRelays;
        });
      }
    } catch (e) {
      debugPrint("Error updating relay: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
            )),
        title: Center(
            child: const Text(
          "IoT Dashboard",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        )),
        backgroundColor: Color.fromARGB(255, 122, 131, 252),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(
                  255, 132, 140, 254), // Light blue (from 0% in the image)
              Color(0xFF53589B), // Muted blue (25%)
              Color(0xFF343763), // Darker blue (50%)
              Color(0xFF292D5B), // Deep blue (75%)
              Color(0xFF262955), // Near black-blue (100%)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello User123",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Welcome back home !",
                          style: TextStyle(
                            color: Color.fromARGB(255, 236, 236, 236),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                          "https://img.freepik.com/free-vector/blue-circle-with-white-user_78370-4707.jpg?t=st=1743101238~exp=1743104838~hmac=110f2c9160f2d98cf2379874a29ba9051491c083d1f5f4a729522c8409572a3d&w=826"),
                      radius: 23,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      _deviceCard(
                          "Temperature",
                          sensorData['temperature'],
                          Icons.thermostat,
                          const Color.fromARGB(255, 255, 218, 51)),
                      Spacer(),
                      _deviceCard(
                          "Humidity",
                          sensorData['humidity'],
                          Icons.water_drop,
                          const Color.fromARGB(255, 77, 151, 255)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      _deviceCard(
                          "Motion Detected",
                          sensorData['pir'] ? 'Yes' : 'No',
                          Icons.directions_run,
                          sensorData['pir'] ? Colors.green : Colors.red),
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Control Relays",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      _isListening
                          ? _buildPulsingMicButton()
                          : _buildMicButton(),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      ...sensorData['relays']
                          .keys
                          .map((relay) => _relayCard(relay)),
                    ],
                  )
                ],
              )
              // Expanded(
              //   child: GridView.count(
              //     crossAxisCount: 2,
              //     crossAxisSpacing: 12,
              //     mainAxisSpacing: 12,
              //     children: [
              //       _deviceCard("Temperature", sensorData['temperature'],
              //           Icons.thermostat, Colors.orangeAccent),
              //       _deviceCard("Humidity", sensorData['humidity'],
              //           Icons.water_drop, Colors.lightBlueAccent),
              //       _deviceCard(
              //           "Motion Detected",
              //           sensorData['pir'] ? 'Yes' : 'No',
              //           Icons.directions_run,
              //           sensorData['pir'] ? Colors.green : Colors.red),
              //       ...sensorData['relays']
              //           .keys
              //           .map((relay) => _relayCard(relay)),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deviceCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2.15,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 10),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(title,
                  style: const TextStyle(
                      color: Color.fromARGB(217, 255, 255, 255), fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _relayCard(String relay) {
    bool isActive = sensorData['relays'][relay] ?? false;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: GestureDetector(
        onTap: () => toggleRelay(relay), // Directly toggle relay state
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? const Color.fromARGB(255, 49, 230, 55).withOpacity(0.8)
                : const Color.fromARGB(255, 243, 33, 33)
                    .withOpacity(0.8), // Change color based on state
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                relay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isActive ? "ON" : "OFF",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return InkWell(
      onTap: _listen,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mic,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildPulsingMicButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: InkWell(
            onTap: _listen,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mic,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }
}
