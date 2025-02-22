import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'location_picker_page.dart';

class IssuePage extends StatefulWidget {
  const IssuePage({Key? key}) : super(key: key);

  @override
  State<IssuePage> createState() => _IssuePageState();
}

class _IssuePageState extends State<IssuePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _manualLocationController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  String? _selectedCategory;
  String? _selectedUrgency;

  final List<String> _categories = ['Electrical', 'Plumbing', 'IT Support', 'Maintenance', 'Other'];
  final List<String> _urgencyLevels = ['Low', 'Medium', 'High'];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      setState(() => _isUploading = true);

      final url = "https://api.cloudinary.com/v1_1/ddwiftlk3/image/upload";
      final request = http.MultipartRequest("POST", Uri.parse(url))
        ..fields['upload_preset'] = "feedback_app"
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      setState(() => _isUploading = false);
      return jsonResponse['secure_url'];
    } catch (e) {
      setState(() => _isUploading = false);
      return null;
    }
  }

  Future<void> _submitIssue() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) return;
    setState(() => _isUploading = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToCloudinary(_selectedImage!);
      }
      await _firestore.collection('issues').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory ?? 'Other',
        'urgency': _selectedUrgency ?? 'Medium',
        'status': 'open',
        'studentId': user.uid,
        'imageUrl': imageUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'manualLocation': _manualLocationController.text.trim(),
        'latitude': _selectedLocation?.latitude,
        'longitude': _selectedLocation?.longitude,
        'address': _selectedAddress ?? '',
      });

      setState(() {
        _titleController.clear();
        _descriptionController.clear();
        _manualLocationController.clear();
        _selectedImage = null;
        _selectedLocation = null;
        _selectedAddress = null;
        _selectedCategory = null;
        _selectedUrgency = null;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue submitted successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  void _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationPickerPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedLocation = LatLng(result['latitude'], result['longitude']);
        _selectedAddress = result['name'] ?? 'Unknown Location';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF2A2A72)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.report_problem, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Report an Issue',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(_titleController, Icons.title, 'Issue Title'),
                  const SizedBox(height: 16),
                  _buildTextField(_descriptionController, Icons.description, 'Issue Description', maxLines: 4),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  _buildDropdown('Select Category', _categories, _selectedCategory, (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }),
                  const SizedBox(height: 16),

                  // Urgency Dropdown
                  _buildDropdown('Select Urgency', _urgencyLevels, _selectedUrgency, (value) {
                    setState(() {
                      _selectedUrgency = value;
                    });
                  }),
                  const SizedBox(height: 16),

                  // Manual Location Field
                  _buildTextField(_manualLocationController, Icons.location_on, 'Manual Location (Optional)'),
                  const SizedBox(height: 16),

                  // Image Preview
                  _selectedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(_selectedImage!, height: 150),
                  )
                      : Container(),
                  const SizedBox(height: 10),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildIconButton(Icons.image, 'Attach Image', _pickImage),
                      _buildIconButton(Icons.map, _selectedLocation != null ? 'Change Location' : 'Pick Location', _pickLocation),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton(
                    onPressed: _submitIssue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const SizedBox(
                      width: double.infinity,
                      child: Center(
                        child: Text('Submit Issue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
    );
  }
}

Widget _buildDropdown(String hint, List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(30),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedValue,
        hint: Text(hint, style: const TextStyle(color: Colors.white70)),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        dropdownColor: Colors.blue[900],
        isExpanded: true,
        style: const TextStyle(color: Colors.white),
        onChanged: onChanged,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
      ),
    ),
  );
}
