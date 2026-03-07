import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/foundation.dart';

class TranslationService{
  final modelManager = OnDeviceTranslatorModelManager();

  Future<String> translateAlert(String text) async {
    final String targetLangCode =PlatformDispatcher.instance.locale.languageCode;
    
    // 1. Initialise the translator directly 
    final onDeviceTranslator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: _translateLanguageFromCode(targetLangCode),
    );

    try {
      // 3. Perform the actual translation
      final String translatedText = await onDeviceTranslator.translateText(text);
      
      // 4. Always close the translator to prevent memory leaks
      onDeviceTranslator.close(); 
      return translatedText;
    } catch (e) {
      debugPrint("Translation Error: $e");
      return text; // Fallback: return original text so the alert isn't lost
    }
  }
  
  Future<void> prepareLanguageModel(String languageCode) async {
    final TranslateLanguage language = _translateLanguageFromCode(languageCode);
    
    // Check if the model is already downloaded
    final bool isDownloaded = await modelManager.isModelDownloaded(language.bcpCode);

    if (!isDownloaded) {
      print("Downloading $languageCode model...");
      // Trigger download; this requires internet once
      await modelManager.downloadModel(language.bcpCode);
      print("Download complete.");
    }
  }

  // Helper to map code to ML Kit constants
  TranslateLanguage _translateLanguageFromCode(String code) {
    switch (code) {
      case 'ms': return TranslateLanguage.malay;
      case 'zh': return TranslateLanguage.chinese;
      case 'ta': return TranslateLanguage.tamil;
      default: return TranslateLanguage.english;
    }
  }

}