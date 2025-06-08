import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:sayfa_yonlendirme/db/database_helper.dart';
import 'package:sayfa_yonlendirme/models/user.dart';
import 'package:sayfa_yonlendirme/screens/login_page.dart';
import 'package:sayfa_yonlendirme/screens/profile_screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  void _tryRegister() async {
    final username = _usernameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;

    // Validasyonlar
    if (username.isEmpty || email.isEmpty || password.isEmpty || passwordConfirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen tüm alanları doldurun!')),
      );
      return;
    }
    
    if (password != passwordConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifreler eşleşmiyor!')),
      );
      return;
    }

    final passwordHash = sha256.convert(utf8.encode(password)).toString();

    final newUser = User(
      username: username,
      email: email,
      passwordHash: passwordHash,
    );

    final result = await DatabaseHelper.instance.registerUser(newUser);

    if (result == -1) {
      print("\n***\n❗Bu kullanıcı adı ya da e-posta zaten kayıtlı!\n***\n");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu kullanıcı adı ya da e-posta zaten kayıtlı!')),
      );
    } else {
      print("✅ Kayıt başarılı! User ID: $result");
      
      // Profil ekranına yönlendirme - result değişkeni user ID'dir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: result),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF404040),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25), // Kenarlara boşluk ekledik
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                // log in text
                Text(
                  "Create New",
                  style: TextStyle(
                    fontFamily: "CodecPro",
                    fontWeight: FontWeight.w600,
                    fontSize: 38,
                    letterSpacing: 0.8,
                    height: 0.8,
                    color: Color(0xFFFFFFFF), // Beyaz
                  ),
                ),
                Text(
                  "Account",
                  style: TextStyle(
                    fontFamily: "CodecPro",
                    fontWeight: FontWeight.w600,
                    fontSize: 38,
                    letterSpacing: 0.8,
                    height: 0.8,
                    color: Color(0xFFFFFFFF), // Beyaz
                  ),
                ),
                
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                // name text
                Text("NAME", 
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.4,
                  color: Color(0xFF3d8dff), // Mavi
                ),
                ),
              
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),

                // name textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFececec),
                      border: Border.all(color: Color.fromARGB(255, 203, 203, 203)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    height: MediaQuery.of(context).size.height * 0.055,
                    child: TextField(
                      controller: _usernameController,
                      textAlign: TextAlign.center,
                      obscureText: false,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Selin Çolak",
                        hintStyle: TextStyle(
                          fontSize: 18,
                          letterSpacing: 1.4,
                          color: const Color.fromARGB(255, 115, 115, 115),
                        ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
                ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                // email text
                Text(
                  "EMAIL", 
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.4,
                    color: Color(0xFF3d8dff),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.01),

                // email textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFececec),
                      border: Border.all(color: Color.fromARGB(255, 115, 115, 115)),
                      borderRadius: BorderRadius.circular(12),
                    ),                      
                    height: MediaQuery.of(context).size.height * 0.055,
                    child: TextField(
                      controller: _emailController,
                      textAlign: TextAlign.center,
                      obscureText: false,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "mail@gmail.com",
                        hintStyle: TextStyle(
                          fontSize: 18,
                          letterSpacing: 1.4,
                          color: const Color.fromARGB(255, 115, 115, 115),
                        ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
                ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                // password text
                Text(
                  "PASSWORD", 
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.4,
                      color: Color(0xFF3d8dff),
                    ),
                ),
              
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),

                // password textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFececec),
                      border: Border.all(color: Color.fromARGB(255, 115, 115, 115)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    height: MediaQuery.of(context).size.height * 0.055,
                    child: TextField(
                      controller: _passwordController,
                      textAlign: TextAlign.center,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "*****",
                        hintStyle: TextStyle(
                          fontSize: 18,
                          letterSpacing: 1.4,
                          color: const Color.fromARGB(255, 115, 115, 115),
                        ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
                ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                // password control text
                Text(
                  "PASSWORD CONTROL", 
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.4,
                      color: Color(0xFF3d8dff),
                    ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.01),

                // password control textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFececec),
                      border: Border.all(color: Color.fromARGB(255, 115, 115, 115)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    height: MediaQuery.of(context).size.height * 0.055,
                    child: TextField(
                      controller: _passwordConfirmController,
                      textAlign: TextAlign.center,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "*****",
                        hintStyle: TextStyle(
                          fontSize: 18,
                          letterSpacing: 1.4,
                          color: const Color.fromARGB(255, 115, 115, 115),
                        ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.06),

                // sign up button
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _tryRegister();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF984fff), // Mor renk
                      padding: EdgeInsets.all(18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.white, // Yazı rengi beyaz
                            fontWeight: FontWeight.w700,
                            fontSize: 30,
                            letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                // log in now
                Column(
                  children: [
                    Text(
                      "Already registered?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // yonlendirme
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LogInPage()),
                        );
                      },
                      child: Text(
                        "Log in here!",
                        style: TextStyle(
                          color: Color(0xFF3d8dff),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
