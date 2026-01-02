import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for AI-powered first aid instructions using Claude API
class FirstAidAIService {
  static final FirstAidAIService _instance = FirstAidAIService._internal();
  factory FirstAidAIService() => _instance;
  FirstAidAIService._internal();

  // TODO: Replace with your actual API key - store securely
  static const String _apiKey = 'YOUR_CLAUDE_API_KEY';
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';

  /// Get first aid instructions for a described injury
  Future<FirstAidResponse> getFirstAidInstructions(
      String injuryDescription) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': _buildPrompt(injuryDescription),
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'][0]['text'] as String;
        return _parseResponse(content);
      } else {
        debugPrint('AI API error: ${response.statusCode} - ${response.body}');
        return _getFallbackInstructions(injuryDescription);
      }
    } catch (e) {
      debugPrint('Error getting first aid instructions: $e');
      return _getFallbackInstructions(injuryDescription);
    }
  }

  String _buildPrompt(String injuryDescription) {
    return '''You are an emergency first aid assistant. The user has described an injury or medical situation. 
Provide clear, step-by-step first aid instructions that can be followed by someone without medical training.

IMPORTANT:
- Always start by assessing if this is a life-threatening emergency that requires immediate professional help
- Provide practical, actionable steps
- Use simple language
- Include safety precautions
- Mention when to seek professional medical help

User's description: $injuryDescription

Please respond in the following JSON format:
{
  "isEmergency": true/false,
  "emergencyMessage": "If emergency, provide urgent action message",
  "title": "Brief title of the condition",
  "steps": ["Step 1", "Step 2", "Step 3", ...],
  "warnings": ["Warning 1", "Warning 2", ...],
  "seekHelpIf": ["Condition 1 when to seek help", "Condition 2", ...]
}''';
  }

  FirstAidResponse _parseResponse(String content) {
    try {
      // Extract JSON from the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final data = json.decode(jsonStr);
        return FirstAidResponse.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error parsing AI response: $e');
    }

    // If parsing fails, return a basic response
    return FirstAidResponse(
      isEmergency: false,
      emergencyMessage: null,
      title: 'First Aid Instructions',
      steps: [content],
      warnings: [],
      seekHelpIf: ['Symptoms worsen', 'Pain increases', 'You feel unwell'],
    );
  }

  FirstAidResponse _getFallbackInstructions(String injuryDescription) {
    final description = injuryDescription.toLowerCase();

    // Check for common injury types and provide appropriate fallback
    if (description.contains('cut') ||
        description.contains('bleeding') ||
        description.contains('wound')) {
      return _getCutInstructions();
    } else if (description.contains('burn')) {
      return _getBurnInstructions();
    } else if (description.contains('sprain') ||
        description.contains('twisted') ||
        description.contains('ankle')) {
      return _getSprainInstructions();
    } else if (description.contains('chok')) {
      return _getChokingInstructions();
    } else if (description.contains('head') ||
        description.contains('concussion')) {
      return _getHeadInjuryInstructions();
    } else if (description.contains('fracture') ||
        description.contains('broken') ||
        description.contains('bone')) {
      return _getFractureInstructions();
    } else if (description.contains('sting') ||
        description.contains('bite') ||
        description.contains('insect')) {
      return _getInsectBiteInstructions();
    }

    return _getGeneralInstructions();
  }

  FirstAidResponse _getCutInstructions() {
    return FirstAidResponse(
      isEmergency: false,
      emergencyMessage:
          'If bleeding is severe and won\'t stop, call emergency services immediately!',
      title: 'Cut / Wound Care',
      steps: [
        'Wash your hands thoroughly or wear clean gloves if available',
        'Apply firm pressure to the wound with a clean cloth or bandage',
        'Keep pressure on for at least 10-15 minutes without lifting',
        'Once bleeding slows, gently clean the wound with clean water',
        'Apply antibiotic ointment if available',
        'Cover with a sterile bandage or clean cloth',
        'Change the bandage daily and keep the wound clean',
      ],
      warnings: [
        'Do not remove objects embedded in the wound',
        'Do not apply a tourniquet unless trained',
        'Avoid using cotton balls directly on wounds',
      ],
      seekHelpIf: [
        'Bleeding doesn\'t stop after 15 minutes of pressure',
        'The wound is deep, long, or has jagged edges',
        'You see signs of infection (redness, swelling, pus, fever)',
        'The wound was caused by a dirty or rusty object',
        'You haven\'t had a tetanus shot in the last 5 years',
      ],
    );
  }

  FirstAidResponse _getBurnInstructions() {
    return FirstAidResponse(
      isEmergency: false,
      emergencyMessage:
          'For severe burns covering large areas or affecting face/hands/genitals, call emergency services!',
      title: 'Burn Care',
      steps: [
        'Remove yourself from the heat source immediately',
        'Cool the burn under cool (not cold) running water for 10-20 minutes',
        'Remove any jewelry or tight clothing near the burn before swelling',
        'Cover the burn loosely with a sterile, non-stick bandage',
        'Take over-the-counter pain medication if needed',
        'Do NOT apply ice, butter, or toothpaste to the burn',
      ],
      warnings: [
        'Never break blisters - they protect against infection',
        'Do not apply ice directly to burns',
        'Do not use adhesive bandages on burns',
        'Chemical burns require flushing with water for 20+ minutes',
      ],
      seekHelpIf: [
        'The burn is larger than 3 inches or covers a large area',
        'The burn is on the face, hands, feet, genitals, or joints',
        'The burn appears white or charred',
        'You develop fever or signs of infection',
        'It was caused by chemicals, electricity, or explosion',
      ],
    );
  }

  FirstAidResponse _getSprainInstructions() {
    return FirstAidResponse(
      isEmergency: false,
      emergencyMessage: null,
      title: 'Sprain Care (R.I.C.E. Method)',
      steps: [
        'REST: Stop all activities and avoid putting weight on the injured area',
        'ICE: Apply ice wrapped in a cloth for 15-20 minutes every 2-3 hours',
        'COMPRESSION: Wrap the area with an elastic bandage (not too tight)',
        'ELEVATION: Keep the injured area raised above heart level when possible',
        'Take over-the-counter pain medication if needed',
        'Continue R.I.C.E. for the first 48-72 hours',
      ],
      warnings: [
        'Do not apply ice directly to skin',
        'Do not wrap bandage too tightly - check for numbness/tingling',
        'Do not use heat in the first 48 hours',
        'Avoid activities that cause pain',
      ],
      seekHelpIf: [
        'You heard a popping sound when the injury occurred',
        'You cannot bear weight on the limb',
        'The area is severely swollen or misshapen',
        'There is numbness or tingling',
        'Pain and swelling don\'t improve within 48-72 hours',
      ],
    );
  }

  FirstAidResponse _getChokingInstructions() {
    return FirstAidResponse(
      isEmergency: true,
      emergencyMessage:
          'CHOKING IS A LIFE-THREATENING EMERGENCY! Call emergency services immediately if the person cannot breathe!',
      title: 'Choking Emergency',
      steps: [
        'Ask "Are you choking?" If they can\'t speak or cough, proceed with help',
        'Stand behind the person and wrap your arms around their waist',
        'Make a fist with one hand and place it above their navel',
        'Grasp your fist with your other hand',
        'Give quick, upward thrusts (Heimlich maneuver)',
        'Repeat until the object is expelled or the person can breathe',
        'If the person becomes unconscious, begin CPR if trained',
      ],
      warnings: [
        'Do not perform abdominal thrusts on pregnant women or infants',
        'For infants: use back blows and chest thrusts instead',
        'Do not try to sweep the object out blindly with your finger',
      ],
      seekHelpIf: [
        'The object is not expelled after multiple attempts',
        'The person loses consciousness',
        'The person has difficulty breathing after the object is removed',
        'There is persistent coughing or throat pain afterward',
      ],
    );
  }

  FirstAidResponse _getHeadInjuryInstructions() {
    return FirstAidResponse(
      isEmergency: true,
      emergencyMessage:
          'Head injuries can be serious! If the person lost consciousness or shows confusion, call emergency services!',
      title: 'Head Injury Care',
      steps: [
        'Keep the person still and calm - do not move them if spine injury is suspected',
        'If conscious, have them lie down with head and shoulders slightly elevated',
        'Apply a cold compress to reduce swelling (do not apply pressure)',
        'Check for clear fluid from nose or ears (this is serious)',
        'Monitor consciousness, breathing, and any changes in behavior',
        'Keep the person awake for several hours after the injury',
        'Do not give any medications without medical advice',
      ],
      warnings: [
        'Do not move the person if spine injury is possible',
        'Do not remove any object embedded in the head',
        'Do not apply direct pressure to skull fractures',
        'Do not allow the person to fall asleep for at least a few hours',
      ],
      seekHelpIf: [
        'Loss of consciousness, even briefly',
        'Confusion, memory loss, or unusual behavior',
        'Severe headache that gets worse',
        'Repeated vomiting',
        'Clear fluid from nose or ears',
        'Unequal pupil sizes',
        'Seizures',
        'Slurred speech or vision problems',
      ],
    );
  }

  FirstAidResponse _getFractureInstructions() {
    return FirstAidResponse(
      isEmergency: false,
      emergencyMessage:
          'If bone is visible or the limb appears severely deformed, call emergency services!',
      title: 'Suspected Fracture Care',
      steps: [
        'Do not move the injured limb - keep it in the position found',
        'Immobilize the area above and below the suspected fracture',
        'Apply ice wrapped in cloth to reduce swelling',
        'If possible, create a splint using rigid material (board, rolled newspaper)',
        'Pad the splint for comfort and secure it without binding too tightly',
        'Monitor for signs of circulation problems (numbness, tingling, blue color)',
        'Keep the person calm and still until help arrives',
      ],
      warnings: [
        'Do not try to straighten or realign the bone',
        'Do not move the person if spine injury is suspected',
        'Do not apply splint too tightly',
        'Open fractures need sterile covering, do not push bone back in',
      ],
      seekHelpIf: [
        'All suspected fractures should be evaluated by a medical professional',
        'Bone is visible through the skin',
        'The limb is severely deformed or bent unnaturally',
        'There is severe swelling or bruising',
        'Numbness or tingling below the injury',
        'The person cannot move the limb at all',
      ],
    );
  }

  FirstAidResponse _getInsectBiteInstructions() {
    return FirstAidResponse(
      isEmergency: false,
      emergencyMessage:
          'If there are signs of severe allergic reaction (difficulty breathing, swelling of face/throat), call emergency services immediately!',
      title: 'Insect Bite/Sting Care',
      steps: [
        'Remove the stinger if visible by scraping sideways with a flat edge (don\'t squeeze)',
        'Wash the area with soap and water',
        'Apply a cold pack wrapped in cloth for 10 minutes to reduce swelling',
        'Apply calamine lotion or hydrocortisone cream to reduce itching',
        'Take antihistamine if available for itching',
        'Keep the area clean and avoid scratching',
      ],
      warnings: [
        'Do not squeeze the stinger - this can release more venom',
        'Watch for signs of allergic reaction for at least 30 minutes',
        'Do not scratch - this can cause infection',
      ],
      seekHelpIf: [
        'Difficulty breathing or swallowing',
        'Swelling of face, lips, or throat',
        'Dizziness, nausea, or rapid heartbeat',
        'Multiple stings',
        'Known severe allergy to insect stings',
        'Signs of infection (increasing redness, warmth, pus)',
        'The bite is from a tick (risk of Lyme disease)',
      ],
    );
  }

  FirstAidResponse _getGeneralInstructions() {
    return FirstAidResponse(
      isEmergency: false,
      emergencyMessage: null,
      title: 'General First Aid',
      steps: [
        'Stay calm and assess the situation for any dangers',
        'Check if the person is responsive and breathing',
        'If there is bleeding, apply pressure with a clean cloth',
        'Keep the person comfortable and calm',
        'Do not move the person if a spine injury is suspected',
        'Monitor vital signs and keep the person warm',
        'Call for professional medical help if needed',
      ],
      warnings: [
        'Do not give food or water if surgery might be needed',
        'Do not move someone with a suspected spine injury',
        'Do not remove embedded objects',
      ],
      seekHelpIf: [
        'The person is unconscious or unresponsive',
        'There is difficulty breathing',
        'Severe bleeding that won\'t stop',
        'Chest pain or signs of heart attack',
        'Signs of stroke (face drooping, arm weakness, speech difficulty)',
        'You are unsure about the severity of the injury',
      ],
    );
  }
}

/// Response model for first aid instructions
class FirstAidResponse {
  final bool isEmergency;
  final String? emergencyMessage;
  final String title;
  final List<String> steps;
  final List<String> warnings;
  final List<String> seekHelpIf;

  FirstAidResponse({
    required this.isEmergency,
    this.emergencyMessage,
    required this.title,
    required this.steps,
    required this.warnings,
    required this.seekHelpIf,
  });

  factory FirstAidResponse.fromJson(Map<String, dynamic> json) {
    return FirstAidResponse(
      isEmergency: json['isEmergency'] ?? false,
      emergencyMessage: json['emergencyMessage'],
      title: json['title'] ?? 'First Aid Instructions',
      steps: List<String>.from(json['steps'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      seekHelpIf: List<String>.from(json['seekHelpIf'] ?? []),
    );
  }
}
