import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:consistify/db/database_helper.dart';
import 'package:consistify/screens/profile_screen.dart';
import 'package:consistify/screens/signup_page.dart';
import 'package:consistify/screens/todo_screen.dart';
import 'package:consistify/services/auth_service.dart';
import 'package:consistify/utils/app_routes.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  void _tryLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    final hash = sha256.convert(utf8.encode(password)).toString();

    print("Giriş yapılan email: $email, hash: $hash");

    final user = await DatabaseHelper.instance.loginUser(email, hash);

    if (user != null) {
      print("\n***\nHoş geldin ${user.username} 🧜‍♀️\nusername: ${user.username}\nemail: ${user.email}\nhash: ${user.passwordHash}\n***\n");

      // Giriş durumunu kaydediyoruz.
      await AuthService.saveLoginState(
        userId: user.id!,
        username: user.username,
        email: user.email,
      );

      await DatabaseHelper.instance.generateDailyTasksForUser(user.id!);

      // MarketSection yerine ProfileScreen'e yönlendir ve userId gönder:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TodoScreen(userId: user.id!), // userId'yi ProfileScreen'e gönder
        ),
      );
      
    } else {
      print("\n***\n❌ Giriş başarısız!\n***\n");
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giriş başarısız! Email veya şifre hatalı.'),
          backgroundColor: Colors.red,
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
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
              // Giriş başlığı
              Text(
                "Sign In to",
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
                "Your Account",
                style: TextStyle(
                  fontFamily: "CodecPro",
                  fontWeight: FontWeight.w600,
                  fontSize: 40,
                  letterSpacing: 0.8,
                  height: 0.8,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).size.height * 0.16),

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
                    border: Border.all(color: Color.fromARGB(255, 203, 203, 203)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  height: MediaQuery.of(context).size.height * 0.055,
                  child: TextField(
                    controller: _emailController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "yourmail@gmail.com",
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
                        color: const Color(0xFFececec),
                        border: Border.all(color: const Color.fromARGB(255, 115, 115, 115)),
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

                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),

                  // // forgot password
                  // Center(
                  //   child: InkWell(
                  //     onTap: () async {
                  //       await generateTestData(1);
                  //     },
                  //     child:
                  //      Text(
                  //       "Forgot password?",
                  //       style: TextStyle(
                  //         color: Color(0xFF984fff),
                  //         fontSize: 14,
                  //         fontWeight: FontWeight.bold,
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.18),


                  // sign in button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: ElevatedButton(
                      onPressed: () {
                       _tryLogin();  // Burada _tryLogin fonksiyonunu çağırıyoruz,
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
                          "Sign in",
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

                  // register now
                  Column(
                    children: [
                      Text(
                        "You don't have an account?",
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
                            AppRoutes.createRoute(
                              SignUpPage(),
                              type: RouteType.fade,
                            ),
                          );
                        },
                        child: Text(
                          "Sign up here!",
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
    );
  }

}
