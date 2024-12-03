import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_form.dart';
import 'registration_form.dart';

class IDFormScreen extends StatelessWidget {
  IDFormScreen({Key? key}) : super(key: key);

  final TextEditingController _userIdController = TextEditingController();

  Future<void> _checkUserId(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('userId');

    if (storedUserId != null && storedUserId == _userIdController.text) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginFormScreen(userId: storedUserId),
        ),
      );
    } else {
      try {
        final response = await http.post(
          Uri.parse(
              'http://192.168.1.104/attendance_system/api1_check_user.php'),
          body: jsonEncode({'user_id': _userIdController.text}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['error'] != null && data['error'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'])),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RegistrationFormScreen(userId: _userIdController.text),
              ),
            );
          } else {
            prefs.setString('userName', data['user_name']);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LoginFormScreen(userId: _userIdController.text),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Server error. Please try again.")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Network error. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Color.fromARGB(255, 68, 18, 185)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.1, 0.5],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const SizedBox(height: 100),
                const Center(
                  child: Image(
                    image: AssetImage('assets/fu_icon.png'),
                    width: 150,
                    height: 150,
                  ),
                ),
                const SizedBox(height: 50),
                const Text(
                  "ATTENDANCE\nSEEKER",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 80),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "User ID (Student or Employee ID)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter User ID',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_userIdController.text.isNotEmpty) {
                        _checkUserId(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Please enter a User ID.")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      "Submit",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
