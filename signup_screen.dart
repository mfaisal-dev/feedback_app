import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _secondNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedRole = 'Student';
  bool _isLoading = false;
  int _currentStep = 0;

  void _nextStep() {
    bool isValid = false;

    // Validate fields based on the current step
    if (_currentStep == 0) {
      if (_firstNameController.text.trim().isEmpty ||
          _secondNameController.text.trim().isEmpty) {
        _showSnackBar("Please enter all the details to continue.");
      } else {
        isValid = true;
      }
    } else if (_currentStep == 1) {
      // Validate the form explicitly
      if (_formKey.currentState!.validate()) {
        isValid = true;
      }
    } else {
      isValid = true;
    }

    // Move to the next step only if valid
    if (isValid) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
        _pageController.animateToPage(_currentStep,
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        _signup();
      }
    }
  }

  bool _validateEmail(String email) {
    // Email validation regex
    return RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _signup() async {
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstNameController.text.trim(),
        'secondName': _secondNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'role': _selectedRole.toLowerCase(),
      });

      Navigator.pushReplacementNamed(context, _selectedRole == 'Admin' ? '/admin' : '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign Up failed: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Dismiss the keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF2A2A72)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add, size: 80, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Create an Account',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),

                    // PageView for step-by-step form
                    SizedBox(
                      height: 250, // Adjusted height to accommodate keyboard
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1(),
                          _buildStep2(),
                          _buildStep3(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Navigation Buttons
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentStep > 0)
                              ElevatedButton(
                                onPressed: _previousStep,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue[900],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : ElevatedButton(
                              onPressed: _nextStep,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue[900],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(_currentStep == 2 ? 'Submit' : 'Next',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text(
                            'Already have an account? Login',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Step 1: Personal Information
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildTextField(_firstNameController, Icons.person, 'First Name'),
          const SizedBox(height: 16),
          _buildTextField(_secondNameController, Icons.person_outline, 'Second Name'),
          const SizedBox(height: 16),
          _buildDropdown(
            value: _selectedGender,
            label: 'Gender',
            icon: Icons.people,
            items: ['Male', 'Female', 'Other'],
            onChanged: (newValue) => setState(() => _selectedGender = newValue!),
          ),
        ],
      ),
    );
  }

  // Step 2: Account Details
  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildTextField(_emailController, Icons.email, 'Email', isEmail: true),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, Icons.lock, 'Password', isPassword: true),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, Icons.phone, 'Phone (Optional)', isOptional: true),
            ],
          ),
        ),
      ),
    );
  }

  // Step 3: Role Selection & Review
  Widget _buildStep3() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDropdown(
          value: _selectedRole,
          label: 'Role',
          icon: Icons.admin_panel_settings,
          items: ['Student', 'Admin'],
          onChanged: (newValue) => setState(() => _selectedRole = newValue!),
        ),
        const SizedBox(height: 16),
        const Text("Review your details before submitting.",
            style: TextStyle(fontSize: 16, color: Colors.white70)),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, IconData icon, String label,
      {bool isPassword = false, bool isOptional = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
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
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Please enter your $label';
        }
        if (isEmail && value != null && value.isNotEmpty) {
          bool emailValid = RegExp(
              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
              .hasMatch(value);
          if (!emailValid) {
            return 'Enter a valid email address';
          }
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({required String value, required String label, required IconData icon, required List<String> items, required Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: const Color(0xFF2A2A72),
      style: const TextStyle(color: Colors.white),
      items: items.map((String item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }
}
