import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslationScreen extends StatefulWidget {
  final String initialText;
  const TranslationScreen({super.key, this.initialText = ""});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController textController = TextEditingController();
  String translatedText = "";
  String targetLanguage = "ur";
  String detectedLanguage = "Detecting...";
  FlutterTts flutterTts = FlutterTts();
  final translator = GoogleTranslator();
  bool _isTranslating = false;
  bool _isSpeaking = false;

  // Available languages for translation
  final Map<String, String> languageOptions = {
    "ur": "Urdu", // National language
    "es": "Spanish",
    "fr": "French",
    "de": "German",
    "hi": "Hindi",
    "zh-cn": "Chinese (Simplified)",
    "en": "English",
    "it": "Italian",
    "ru": "Russian",
    "ja": "Japanese",
    "ko": "Korean",
    "pt": "Portuguese",
    "tr": "Turkish",
    "pl": "Polish",
    "nl": "Dutch",
    "sv": "Swedish",
    "id": "Indonesian",
    "th": "Thai",
    "vi": "Vietnamese",
    "ms": "Malay",
    "bn": "Bengali",
    "ta": "Tamil",
    "ml": "Malayalam",
    "ne": "Nepali",
    "si": "Sinhala",
    "iw": "Hebrew",
    "el": "Greek",
    "cs": "Czech",
    "sk": "Slovak",
    "hr": "Croatian",
    "ro": "Romanian",
    "sr": "Serbian",
    "hu": "Hungarian",
    "uk": "Ukrainian",
    "fa": "Persian",
    "no": "Norwegian",
    "da": "Danish",
    "fi": "Finnish",
    "sw": "Swahili",
    "af": "Afrikaans",
    "sq": "Albanian",
    "bs": "Bosnian",
    "et": "Estonian",
    "la": "Latin",
    "tl": "Tagalog",
    "km": "Khmer",
    "my": "Burmese",
    "lo": "Lao",
    "ka": "Georgian",
    "hy": "Armenian",
    "mr": "Marathi",
    "pa": "Punjabi",
    "gu": "Gujarati",
    "te": "Telugu",
    "or": "Odia",
    "kn": "Kannada",
    "as": "Assamese",
    "bho": "Bhojpuri",
    "rw": "Kinyarwanda",
    "su": "Sundanese",
    "xh": "Xhosa",
    "zu": "Zulu",
    "st": "Sesotho",
    "ts": "Tswana",
    "so": "Somali",
    "uz": "Uzbek",
    "mn": "Mongolian",
    "sd": "Sindhi",
    "ps": "Pashto",
    "bal": "Balochi",
    "skr": "Saraiki",
    "hnd": "Hindko",
    "ks": "Kashmiri",
    "brh": "Brahui",
    "shn": "Shina",
    "ctr": "Chitrali",
    "mkr": "Makrani",
    "wkh": "Wakhi",
    "hzr": "Hazaragi",
    "khw": "Khowar",
    "ar": "Arabic",
    "prs": "Dari",
    "mwr": "Marwari",
  };

  // Detect Language API key
  final String apiKey = "";

  @override
  void initState() {
    super.initState();
    textController.text = widget.initialText;
    textController.addListener(_detectLanguage);
  }

  @override
  void dispose() {
    textController.removeListener(_detectLanguage);
    super.dispose();
  }

  Future<void> _detectLanguage() async {
    if (textController.text.isEmpty) {
      setState(() {
        detectedLanguage = "";
      });
      return;
    }

    try {
      final detectedLang = await detectLanguage(textController.text);
      setState(() {
        detectedLanguage = detectedLang;
      });
    } catch (e) {
      setState(() {
        detectedLanguage = "Error detecting language";
      });
    }
  }

  Future<String> detectLanguage(String text) async {
    final url = Uri.parse("https://ws.detectlanguage.com/0.2/detect");
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "q": text,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final languageCode = data["data"]["detections"][0]["language"];
      // Map the language code to the full language name
      return languageOptions[languageCode] ?? "Unknown Language";
    } else {
      throw Exception("Failed to detect language");
    }
  }

  Future<void> translateText() async {
    if (textController.text.isEmpty) return;
    setState(() {
      _isTranslating = true;
    });
    try {
      final translation = await translator.translate(textController.text, to: targetLanguage);
      setState(() {
        translatedText = translation.text;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Translation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  Future<void> speakTranslatedText() async {
    if (_isSpeaking) {
      await flutterTts.stop(); // Stop speech
      setState(() {
        _isSpeaking = false;
      });
    } else {
      if (translatedText.isNotEmpty) {
        await flutterTts.setLanguage(targetLanguage);
        await flutterTts.speak(translatedText);
        setState(() {
          _isSpeaking = true;
        });

        // Listen for completion
        flutterTts.setCompletionHandler(() {
          setState(() {
            _isSpeaking = false;
          });
        });
      }
    }
  }

  void clearText() {
    textController.clear();
    setState(() {
      translatedText = "";
      detectedLanguage = "Detecting...";
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Hides keyboard on tap outside
      child: Scaffold(
          appBar: AppBar(
            title:
                Text('Text Translator', style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white )),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF2A2A72)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body:
          SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width, // Full screen width
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF2A2A72)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Icon(Icons.translate, size: 80, color: Colors.white,),
                    SizedBox(height: 10,),
                    // Input Text Field with Clear Button
                    Stack(
                      children: [
                        _buildTextField(textController, Icons.text_fields, 'Enter text to translate'),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: clearText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Detected Language Display
                    Text(
                      "Detected Language: $detectedLanguage",
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    // Language Dropdown
                    _buildLanguageDropdown(),
                    const SizedBox(height: 15),

                    // Translate Button
                    _isTranslating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                      onPressed: translateText,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 60),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Translate',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Translated Text Output with Speak Button
                    Container(
                      height: 250, // Fixed height for the output container
                      width: MediaQuery.of(context).size.width, // 90% of screen width
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Scrollable Translated Text
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              translatedText.isEmpty ? "Translation will appear here..." : translatedText,
                              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // Speak Button at Top-Right
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up, color: Colors.white),
                              onPressed: speakTranslatedText,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          )

      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, String label) {
    return TextField(
      controller: controller,
      maxLines: 6,
      style: const TextStyle(color: Colors.white, fontSize: 18,),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: targetLanguage,
          dropdownColor: Colors.blueGrey,
          onChanged: (newValue) {
            setState(() {
              targetLanguage = newValue!;
            });
          },
          items: languageOptions.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
