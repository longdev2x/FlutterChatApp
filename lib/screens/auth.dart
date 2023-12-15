import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredUsername = '';
  File? _selectedImage;
  var _isAuthenticating = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (!_isLogin && _selectedImage == null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn cần thêm ảnh'),
          ),
        );
        return;
      }

      _formKey.currentState!.save();
      try {
        setState(() {
          _isAuthenticating = true;
        });
        if (_isLogin == true) {
          final _userCredentials = await _firebase.signInWithEmailAndPassword(
              email: _enteredEmail, password: _enteredPassword);
        } else {
          final _userCredentials =
              await _firebase.createUserWithEmailAndPassword(
                  email: _enteredEmail, password: _enteredPassword);

          // upload ảnh lên firebasestorage
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('User_images')
              .child('${_userCredentials.user!.uid}.jpg');
          await storageRef.putFile(_selectedImage!);
          final imageUrl = await storageRef.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userCredentials.user!.uid)
              .set({
            'username': _enteredUsername,
            'email': _enteredEmail,
            'image_url': imageUrl,
          });
        }
      } on FirebaseException catch (error) {
        if (!context.mounted) {
          return;
        }
        String errorMessage = 'Thông tin đăng nhập không hợp lệ';

        if (error.code == 'INVALID_LOGIN_CREDENTIALS') {
          errorMessage = 'Tài khoản hoặc mật khẩu không đúng';
        } else if (error.code == 'email-already-in-use') {
          errorMessage = 'Email đã được sử dụng.';
        } else if (error.code == 'invalid-email') {
          errorMessage = 'Email không hợp lệ';
        } else if (error.code == 'too-many-requests') {
          errorMessage = 'Chậm lại';
        }

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(errorMessage),
          ),
        );
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                margin: const EdgeInsets.only(
                  top: 30,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            UserImagePicker(onPickImage: (imageFile) {
                              _selectedImage = imageFile;
                            }),
                          TextFormField(
                              decoration: const InputDecoration(
                                label: Text('Email'),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    !value.contains('@')) {
                                  return 'Kiểm tra lại email!';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                _enteredEmail = newValue!;
                              }),
                          if (!_isLogin)
                            TextFormField(
                                decoration: const InputDecoration(
                                  label: Text('Username'),
                                ),
                                enableSuggestions: false,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      value.trim().length <= 4) {
                                    return 'Username cần dài hơn 4 ký tự';
                                  }
                                  return null;
                                },
                                onSaved: (newValue) {
                                  _enteredUsername = newValue!;
                                }),
                          TextFormField(
                            decoration: const InputDecoration(
                              label: Text('Mật khẩu'),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Mật khẩu cần lớn hơn 6 ký tự';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _enteredPassword = newValue!;
                            },
                          ),
                          const SizedBox(height: 20),
                          if (_isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!_isAuthenticating)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              child: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
                            ),
                          const SizedBox(height: 6),
                          if (!_isAuthenticating)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(_isLogin
                                  ? 'Tạo tài khoản mới'
                                  : 'Tôi đã có tài khoản'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
