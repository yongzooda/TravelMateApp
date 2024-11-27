import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 이메일과 비밀번호로 로그인
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('로그인 실패: $e');
      return null;
    }
  }

  // 이메일과 비밀번호로 회원가입
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('회원가입 실패: $e');
      return null;
    }
  }

  // 이메일 인증 요청
  Future<void> sendEmailVerification(User? user) async {
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        print('이메일 인증 요청을 보냈습니다.');
      } catch (e) {
        print('이메일 인증 요청 실패: $e');
      }
    }
  }
}
