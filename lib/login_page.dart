import 'package:flutter/material.dart';
import 'product_app.dart';
import 'shared_service.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _username = '', _password = '';
  String? _error;
  bool _loading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);

    await Future.delayed(Duration(milliseconds: 300));

    // 🔐 Change your custom credentials here:
    if (_username == 'emilys' && _password == 'emilyspass') {
      await SharedService.saveLoginTime(); // optional
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProductApp()),
      );
    } else {
      setState(() {
        _error = 'Invalid username or password';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Login", style: TextStyle(fontSize: 24)),
                TextFormField(
                  decoration: InputDecoration(labelText: "Username"),
                  onSaved: (val) => _username = val!,
                  validator: (val) => val!.isEmpty ? 'Enter username' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: "Password"),
                  obscureText: true,
                  onSaved: (val) => _password = val!,
                  validator: (val) => val!.isEmpty ? 'Enter password' : null,
                ),
                SizedBox(height: 10),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: Colors.red)),
                SizedBox(height: 10),
                _loading
                    ? CircularProgressIndicator()
                    : ElevatedButton(onPressed: _login, child: Text("Login")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
