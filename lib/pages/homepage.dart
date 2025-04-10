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
  Timer? _autoModeTimer;
  bool _isAutoMode = false;

  // Initialize autoModeSettings directly in the sensorData map
  Map<String, dynamic> sensorData = {
    'temperature': '0°C',
    'humidity': '0%',
    'accX': '0',
    'accY': '0',
    'accZ': '0',
    'pir': false,
    'relays': {
      'relay1': false,
      'relay2': false,
      'relay3': false,
      'relay4': false,
    }
  };

  // Separate map for auto mode settings to avoid null issues
  Map<String, dynamic> autoModeSettings = {
    'temperatureThreshold': 30, // Temperature in °C to trigger relay1
    'humidityThreshold': 70, // Humidity % to trigger relay2
    'motionEnabled': true, // Enable motion detection for relay3
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
    _autoModeTimer?.cancel();
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

  void _toggleAutoMode() {
    setState(() {
      _isAutoMode = !_isAutoMode;
    });

    if (_isAutoMode) {
      _speak('Auto mode activated');
      // Start auto mode checking every 10 seconds
      _autoModeTimer = Timer.periodic(
          const Duration(seconds: 10), (timer) => _runAutoMode());
    } else {
      _speak('Manual mode activated');
      _autoModeTimer?.cancel();
    }
  }

  void _runAutoMode() {
    try {
      // Extract numeric values from sensor data strings
      double temperature = double.tryParse(
              sensorData['temperature'].toString().replaceAll('°C', '')) ??
          0;
      double humidity = double.tryParse(
              sensorData['humidity'].toString().replaceAll('%', '')) ??
          0;
      bool motionDetected = sensorData['pir'] == true;

      // Apply auto rules based on sensor data and settings
      Map<String, bool> updatedRelays =
          Map<String, bool>.from(sensorData['relays']);

      // Rule 1: Control relay1 based on temperature
      if (temperature > autoModeSettings['temperatureThreshold']) {
        updatedRelays['relay1'] = true; // Turn on relay1 (e.g., for cooling)
      } else {
        updatedRelays['relay1'] = false;
      }

      // Rule 2: Control relay2 based on humidity
      if (humidity > autoModeSettings['humidityThreshold']) {
        updatedRelays['relay2'] =
            true; // Turn on relay2 (e.g., for dehumidifier)
      } else {
        updatedRelays['relay2'] = false;
      }

      // Rule 3: Control relay3 based on motion if enabled
      if (autoModeSettings['motionEnabled'] && motionDetected) {
        updatedRelays['relay3'] = true; // Turn on relay3 when motion detected
      } else if (autoModeSettings['motionEnabled'] && !motionDetected) {
        updatedRelays['relay3'] = false; // Turn off when no motion
      }

      // Only update if there are changes to avoid unnecessary API calls
      if (!mapEquals(updatedRelays, sensorData['relays'])) {
        _updateAllRelays(updatedRelays);
      }
    } catch (e) {
      debugPrint("Error in auto mode: $e");
    }
  }

  bool mapEquals(Map<String, bool> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
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
    } else if (command.contains('activate auto mode') ||
        command.contains('enable auto mode') ||
        command.contains('turn on auto mode')) {
      if (!_isAutoMode) {
        _toggleAutoMode();
      } else {
        _speak('Auto mode is already active');
      }
    } else if (command.contains('activate manual mode') ||
        command.contains('enable manual mode') ||
        command.contains('turn on manual mode')) {
      if (_isAutoMode) {
        _toggleAutoMode();
      } else {
        _speak('Manual mode is already active');
      }
    } else if (command.contains('turn on relay 1') ||
        command.contains('turn on relay one')) {
      if (!_isAutoMode) {
        _updateRelay('relay1', true);
        _speak('Turning on relay 1');
      } else {
        _speak(
            'Cannot control relays in auto mode. Please switch to manual mode first');
      }
    } else if (command.contains('turn off relay 1') ||
        command.contains('turn off relay one')) {
      if (!_isAutoMode) {
        _updateRelay('relay1', false);
        _speak('Turning off relay 1');
      } else {
        _speak(
            'Cannot control relays in auto mode. Please switch to manual mode first');
      }
    } else if (command.contains('turn on relay 2') ||
        command.contains('turn on relay two')) {
      if (!_isAutoMode) {
        _updateRelay('relay2', true);
        _speak('Turning on relay 2');
      } else {
        _speak(
            'Cannot control relays in auto mode. Please switch to manual mode first');
      }
    } else if (command.contains('turn off relay 2') ||
        command.contains('turn off relay two')) {
      if (!_isAutoMode) {
        _updateRelay('relay2', false);
        _speak('Turning off relay 2');
      } else {
        _speak(
            'Cannot control relays in auto mode. Please switch to manual mode first');
      }
    } else if (command.contains('turn on relay 3') ||
        command.contains('turn on relay three')) {
      if (!_isAutoMode) {
        _updateRelay('relay3', true);
        _speak('Turning on relay 3');
      } else {
        _speak(
            'Cannot control relays in auto mode. Please switch to manual mode first');
      }
    } else if (command.contains('turn off relay 3') ||
        command.contains('turn off relay three')) {
      if (!_isAutoMode) {
        _updateRelay('relay3', false);
        _speak('Turning off relay 3');
      } else {
        _speak(
            'Cannot control relays in auto mode. Please switch to manual mode first');
      }
    } else if (command.contains('turn on relay 4') ||
        command.contains('turn on relay four')) {
      if (!_isAutoMode) {
        _updateRelay('relay4', true);
        _speak('Turning on relay 4');
      } else {
        _speak(
            'Cannot control relays in auto mode. Please switch to manual mode first');
      }
    } else if (command.contains('turn off relay 4') ||
        command.contains('turn off relay four')) {
      if (!_isAutoMode) {
        _updateRelay('relay4', false);
        _speak('Turning off relay 4');
      } else {
        _speak(
            'Cannot control relays in auto mode. Please switch to manual mode first');
      }
    } else {
      _speak('Command not recognized. Please try again.');
    }
  }

  Future<void> _updateRelay(String relay, bool state) async {
    if (_isAutoMode) {
      _speak('Cannot manually control relays in auto mode');
      return;
    }

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

  Future<void> _updateAllRelays(Map<String, bool> relayStates) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/relays'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(relayStates),
      );

      if (response.statusCode == 200) {
        setState(() {
          sensorData['relays'] = relayStates;
        });
      } else {
        debugPrint("Error updating relays: Status code ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error updating relays: $e");
    }
  }

  void _updateAutoModeSettings({
    int? temperatureThreshold,
    int? humidityThreshold,
    bool? motionEnabled,
  }) {
    setState(() {
      if (temperatureThreshold != null) {
        autoModeSettings['temperatureThreshold'] = temperatureThreshold;
      }
      if (humidityThreshold != null) {
        autoModeSettings['humidityThreshold'] = humidityThreshold;
      }
      if (motionEnabled != null) {
        autoModeSettings['motionEnabled'] = motionEnabled;
      }
    });

    // Run auto mode with new settings
    if (_isAutoMode) {
      _runAutoMode();
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

          // Handle different possible PIR response formats
          bool pirStatus = false;
          if (pirData is bool) {
            pirStatus = pirData;
          } else if (pirData is Map) {
            pirStatus = pirData['status'] == true ||
                pirData['value'] == true ||
                pirData['pir'] == true;
          } else if (pirData is num) {
            pirStatus = pirData > 0;
          } else if (pirData is String) {
            pirStatus = pirData.toLowerCase() == 'true' || pirData == '1';
          }

          sensorData['pir'] = pirStatus;

          sensorData['relays'] = {
            'relay1': relaysData['relay1'] ?? false,
            'relay2': relaysData['relay2'] ?? false,
            'relay3': relaysData['relay3'] ?? false,
            'relay4': relaysData['relay4'] ?? false,
          };
        });

        // If in auto mode, check if we need to adjust relays based on new sensor readings
        if (_isAutoMode) {
          _runAutoMode();
        }
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  Future<void> toggleRelay(String relay) async {
    if (_isAutoMode) {
      _speak('Cannot manually control relays in auto mode');
      return;
    }

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
            icon: const Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
            )),
        title: const Center(
            child: Text(
          "IoT Dashboard",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        )),
        backgroundColor: const Color.fromARGB(255, 122, 131, 252),
        automaticallyImplyLeading: false,
      ),
      // Apply gradient to the entire body background
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 132, 140, 254),
              Color(0xFF53589B),
              Color(0xFF343763),
              Color(0xFF292D5B),
              Color(0xFF262955),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // Use SafeArea to avoid overlapping with system UI
        child: SafeArea(
          // Use LayoutBuilder to get the constraint values
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                // Fix overflow by ensuring content doesn't exceed screen boundaries
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                        // Mode Switch
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Control Mode",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Switch(
                                value: _isAutoMode,
                                onChanged: (value) => _toggleAutoMode(),
                                activeColor: Colors.green,
                                activeTrackColor: Colors.green.withOpacity(0.5),
                                inactiveThumbColor: Colors.blue,
                                inactiveTrackColor:
                                    Colors.blue.withOpacity(0.5),
                              ),
                              Text(
                                _isAutoMode ? "Auto" : "Manual",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              _isListening
                                  ? _buildPulsingMicButton()
                                  : _buildMicButton(),
                            ],
                          ),
                        ),

                        // If auto mode is on, show the configuration options
                        if (_isAutoMode) _buildAutoModeSettings(),

                        // Wrap cards in a column with proper spacing
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Use Flex and Flexible for better responsiveness
                            Row(
                              children: [
                                Expanded(
                                  child: _deviceCard(
                                      "Temperature",
                                      sensorData['temperature'],
                                      Icons.thermostat,
                                      const Color.fromARGB(255, 255, 218, 51)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _deviceCard(
                                      "Humidity",
                                      sensorData['humidity'],
                                      Icons.water_drop,
                                      const Color.fromARGB(255, 77, 151, 255)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _deviceCard(
                                "Motion Detected",
                                sensorData['pir'] ? 'Yes' : 'No',
                                Icons.directions_run,
                                sensorData['pir'] ? Colors.green : Colors.red),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Text(
                                  "Control Relays",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (_isAutoMode)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Text(
                                      "(Controlled by Auto Mode)",
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Use GridView for responsive relay cards
                            GridView.count(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: sensorData['relays']
                                  .keys
                                  .map<Widget>((relay) => _relayCard(relay))
                                  .toList(),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAutoModeSettings() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Auto Mode Settings",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Temperature Threshold",
                style: TextStyle(color: Colors.white),
              ),
              Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.remove, color: Colors.white, size: 18),
                    onPressed: () => _updateAutoModeSettings(
                      temperatureThreshold:
                          autoModeSettings['temperatureThreshold'] - 1,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    "${autoModeSettings['temperatureThreshold']}°C",
                    style: const TextStyle(color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    onPressed: () => _updateAutoModeSettings(
                      temperatureThreshold:
                          autoModeSettings['temperatureThreshold'] + 1,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Humidity Threshold",
                style: TextStyle(color: Colors.white),
              ),
              Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.remove, color: Colors.white, size: 18),
                    onPressed: () => _updateAutoModeSettings(
                      humidityThreshold:
                          autoModeSettings['humidityThreshold'] - 5,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    "${autoModeSettings['humidityThreshold']}%",
                    style: const TextStyle(color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    onPressed: () => _updateAutoModeSettings(
                      humidityThreshold:
                          autoModeSettings['humidityThreshold'] + 5,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Control Relay3 with Motion",
                style: TextStyle(color: Colors.white),
              ),
              Switch(
                value: autoModeSettings['motionEnabled'],
                onChanged: (value) => _updateAutoModeSettings(
                  motionEnabled: value,
                ),
                activeColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deviceCard(String title, String value, IconData icon, Color color) {
    return Card(
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
    );
  }

  Widget _relayCard(String relay) {
    bool isActive = sensorData['relays'][relay] ?? false;

    return GestureDetector(
      onTap: () => _isAutoMode ? null : toggleRelay(relay),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? const Color.fromARGB(255, 49, 230, 55).withOpacity(0.8)
                : const Color.fromARGB(255, 243, 33, 33).withOpacity(0.8),
            border: _isAutoMode
                ? Border.all(color: Colors.white.withOpacity(0.5), width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                relay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isActive ? "ON" : "OFF",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
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
