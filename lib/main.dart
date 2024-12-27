import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_application_1/signup_page.dart'; // Importation de la page d'inscription

void main() {
  runApp(MaterialApp(
    home: LoginPage(),
    theme: ThemeData(
      primarySwatch: Colors.teal,
      fontFamily: 'Arial',
    ),
  ));
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginKey = GlobalKey<FormState>();

  String _authMessage = "";

  // Fonction pour la connexion (Login)
  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5001/login'), // URL de ton API Flask
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Sauvegarder le token JWT pour une utilisation future
      String token = data['access_token'];

      setState(() {
        _authMessage = "Connexion réussie!";
      });
      Fluttertoast.showToast(msg: "Connexion réussie. Token: $token");

      // Naviguer vers la page d'OCR après la connexion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OcrScreen(token: token)),
      );
    } else {
      setState(() {
        _authMessage = "Erreur de connexion!";
      });
      Fluttertoast.showToast(msg: "Erreur de connexion");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Connexion"),
        backgroundColor: Colors.teal[700],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal[700]!, Colors.teal[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _loginKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_open,
                  size: 100,
                  color: Colors.white,
                ),
                SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.email, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email obligatoire';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.lock, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mot de passe obligatoire';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    if (_loginKey.currentState?.validate() ?? false) {
                      _login();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[400],
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'Créer un compte',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  _authMessage,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OcrScreen extends StatefulWidget {
  final String token;

  OcrScreen({required this.token});

  @override
  _OcrScreenState createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  String _extractedText = "";
  Uint8List? _imageBytes; // Make it nullable
  String _imagePath = ""; // Initialize with an empty string

  // Fonction pour choisir une image avec le file picker
  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*'; // Accepter uniquement les images
    uploadInput.click(); // Simule un clic pour ouvrir le sélecteur de fichiers

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      final reader = html.FileReader();
      reader.readAsArrayBuffer(files[0]!);

      reader.onLoadEnd.listen((e) {
        setState(() {
          _imagePath = files[0]!.name; // Nom du fichier
          _imageBytes = reader.result as Uint8List; // Contenu du fichier
        });
      });
    });
  }

  // Fonction pour envoyer l'image et récupérer le texte OCR
  Future<void> _uploadImage(String endpoint) async {
    if (_imageBytes == null || _imagePath.isEmpty) {
      return; // Assurez-vous que _imageBytes n'est pas nul avant de continuer
    }

    // Créer un FormData pour envoyer l'image
    final formData = html.FormData();
    final blob = html.Blob([_imageBytes!]);
    formData.appendBlob('image', blob, _imagePath);

    // Choisir le bon endpoint pour l'upload
    String url = 'http://192.168.1.102:5000/$endpoint'; // URL de ton API Flask

    // Envoyer la requête POST avec l'image vers le backend Flask
    try {
      final response = await html.HttpRequest.request(
        url,
        method: 'POST',
        sendData: formData,
        requestHeaders: {
          'Authorization':
              'Bearer ${widget.token}' // Ajouter le token JWT dans l'entête
        },
      );

      if (response.status == 200) {
        final data = json.decode(response.responseText!);
        setState(() {
          if (endpoint == 'upload') {
            _extractedText = data['data']; // Réponse en anglais
          } else if (endpoint == 'upload_arabic') {
            _extractedText = data['data_arabic']; // Réponse en arabe
          } else {
            _extractedText =
                data['data_combined']; // Réponse combinée (arabe + anglais)
          }
        });
      } else {
        setState(() {
          _extractedText = "Erreur lors du téléchargement de l'image";
        });
      }
    } catch (e) {
      setState(() {
        _extractedText = "Échec de la communication avec le serveur : $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[700],
        title: Text("OCR Scanner", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _imageBytes == null
                ? Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                  )
                : Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.teal, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                elevation: 5,
              ),
              child: Text("Sélectionner une image", style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _uploadImage('upload_combined'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                backgroundColor: Colors.teal[800],
                foregroundColor: Colors.white,
                elevation: 5,
              ),
              child: Text("Télécharger et extraire le texte (Anglais)", style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _uploadImage('upload_arabic'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                elevation: 5,
              ),
              child: Text("Télécharger et extraire le texte (Arabe)", style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
            Text(
              _extractedText.isEmpty
                  ? "Le résultat OCR apparaîtra ici"
                  : _extractedText,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal[800]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
