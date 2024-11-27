import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  // 회원가입 로직
  void _register() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    // 비밀번호 길이 검사
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호는 최소 8자 이상이어야 합니다.')),
      );
      return;
    }

    var user = await _authService.registerWithEmail(email, password);
    if (user != null) {
      print('회원가입 성공: ${user.email}');
      await _authService.sendEmailVerification(user); // 이메일 인증 요청
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일 인증 링크가 발송되었습니다. 인증 후 로그인해주세요.')),
      );
      Navigator.pop(context); // 로그인 화면으로 이동
    } else {
      print('회원가입 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: '이메일'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
