import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  String email = '';
  String password = '';
  bool loading = false;

  void _toggleForm() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => loading = true);
    try {
      if (isLogin) {
        await authService.signInWithEmail(email, password);
      } else {
        await authService.signUpWithEmail(email, password);
      }
      // Navigue vers le dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.toString()}")),
      );
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de l'application
              Image.asset(
                'assets/icon/app_icon.png',
                height: 100,
              ),
              SizedBox(height: 24),
              Text(
                isLogin ? "Connexion" : "Inscription",
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (val) => email = val!.trim(),
                      validator: (val) => val != null && val.contains('@')
                          ? null
                          : "Email invalide",
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      onSaved: (val) => password = val!.trim(),
                      validator: (val) => val != null && val.length >= 6
                          ? null
                          : "6 caractères minimum",
                    ),
                    SizedBox(height: 24),
                    loading
                        ? CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              child:
                                  Text(isLogin ? "Se connecter" : "S'inscrire"),
                            ),
                          ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: _toggleForm,
                child: Text(isLogin
                    ? "Pas de compte ? S'inscrire"
                    : "Déjà un compte ? Se connecter"),
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Text("Ou"),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    icon: Image.asset(
                      'assets/icon/google.png', // Ajoute un logo Google dans tes assets
                      height: 24,
                    ),
                    label: Text("Continuer avec Google"),
                    onPressed: () async {
                      setState(() => loading = true);
                      print("Début connexion Google");
                      try {
                        final userCredential =
                            await authService.signInWithGoogle();
                        print("Résultat Google: $userCredential");
                        if (userCredential != null) {
                          Navigator.pushReplacementNamed(context, '/dashboard');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Connexion annulée ou échouée")),
                          );
                        }
                      } catch (e) {
                        print("Erreur Google sign-in: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erreur Google: $e")),
                        );
                      }
                      setState(() => loading = false);
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
