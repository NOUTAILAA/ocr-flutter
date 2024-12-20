import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MaterialApp(
    home: OcrScreen(),
    theme: ThemeData(
      primarySwatch: Colors.teal,
      fontFamily: 'Arial',
    ),
  ));
}

class OcrScreen extends StatefulWidget {
  @override
  _OcrScreenState createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  String _extractedText = "";
  Uint8List? _imageBytes; // Make it nullable
  String _imagePath = ""; // Initialize with an empty string

  // Fonction pour choisir une image avec le file picker
  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';  // Accepter uniquement les images
    uploadInput.click();  // Simule un clic pour ouvrir le sélecteur de fichiers

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

  // Fonction pour envoyer l'image et récupérer le texte OCR en combiné (arabe et anglais)
  Future<void> _uploadImage() async {
    if (_imageBytes == null || _imagePath.isEmpty) {
      return; // Assurez-vous que _imageBytes n'est pas nul avant de continuer
    }

    // Créer un FormData pour envoyer l'image
    final formData = html.FormData();
    final blob = html.Blob([_imageBytes!]);
    formData.appendBlob('image', blob, _imagePath);

    // Envoyer la requête POST avec l'image vers le backend Flask pour extraction combinée
    try {
      final response = await html.HttpRequest.request(
        'http://192.168.1.50:5000/upload_combined', // URL de votre API Flask
        method: 'POST',
        sendData: formData,
      );

      if (response.status == 200) {
        final data = json.decode(response.responseText!);
        setState(() {
          _extractedText = data['data_combined']; // Réponse combinée (arabe + anglais)
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

  // Fonction pour envoyer l'image et récupérer le texte OCR en arabe
  Future<void> _uploadImageArabic() async {
    if (_imageBytes == null || _imagePath.isEmpty) {
      return; // Assurez-vous que _imageBytes n'est pas nul avant de continuer
    }

    // Créer un FormData pour envoyer l'image
    final formData = html.FormData();
    final blob = html.Blob([_imageBytes!]);
    formData.appendBlob('image', blob, _imagePath);

    // Envoyer la requête POST avec l'image vers le backend Flask pour extraction en arabe
    try {
      final response = await html.HttpRequest.request(
        'http://192.168.1.50:5000/upload_arabic', // URL de votre API Flask pour l'arabe
        method: 'POST',
        sendData: formData,
      );

      if (response.status == 200) {
        final data = json.decode(response.responseText!);
        setState(() {
          _extractedText = data['data_arabic']; // Réponse en arabe
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                backgroundColor: Colors.teal,  // Utilisez backgroundColor au lieu de primary
                foregroundColor: Colors.white, // Utilisez foregroundColor au lieu de onPrimary
                elevation: 5,
              ),
              child: Text("Sélectionner une image", style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImage,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                backgroundColor: Colors.teal[800], // Utilisez backgroundColor au lieu de primary
                foregroundColor: Colors.white, // Utilisez foregroundColor au lieu de onPrimary
                elevation: 5,
              ),
              child: Text("Télécharger et extraire le texte (Combiné)", style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImageArabic,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                backgroundColor: Colors.teal[600], // Utilisez une couleur différente pour ce bouton
                foregroundColor: Colors.white, // Utilisez foregroundColor au lieu de onPrimary
                elevation: 5,
              ),
              child: Text("Télécharger et extraire le texte (Arabe)", style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
            Text(
              _extractedText.isEmpty ? "Le résultat OCR apparaîtra ici" : _extractedText,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal[800]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
