import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/system_models.dart';
import '../providers/app_providers.dart';
import '../services/pcremote_repository.dart';
import '../features/pro/pro_plan_provider.dart';

class NovaActionResult {
  final String toolName;
  final Map<String, dynamic> arguments;
  final bool success;
  final String message;

  const NovaActionResult({
    required this.toolName,
    required this.arguments,
    required this.success,
    required this.message,
  });
}

class NovaResponse {
  final String text;
  final List<NovaActionResult> executedActions;
  final bool isError;

  const NovaResponse({
    required this.text,
    this.executedActions = const [],
    this.isError = false,
  });
}

class GeminiService {
  final String? apiKey;
  final PCRemoteRepository repository;
  final HostSystemInfo systemInfo;

  static const String _model = 'gemini-1.5-flash';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiService({
    required this.apiKey,
    required this.repository,
    required this.systemInfo,
  });

  static final List<Map<String, dynamic>> _toolDeclarations = [
    {
      'name': 'set_volume',
      'description': 'Sets the PC master volume level from 0 to 100 percent.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'level': {
            'type': 'INTEGER',
            'description': 'Target volume percentage (0 to 100)',
          }
        },
        'required': ['level'],
      }
    },
    {
      'name': 'media_control',
      'description': 'Controls media playback or mute status on the PC.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'action': {
            'type': 'STRING',
            'enum': ['play_pause', 'next', 'previous', 'mute', 'unmute', 'mic_on', 'mic_off', 'volume_up', 'volume_down'],
            'description': 'Media action to execute',
          }
        },
        'required': ['action'],
      }
    },
    {
      'name': 'hardware_toggle',
      'description': 'Controls PC hardware radios (Wi-Fi, Bluetooth) or display power state.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'target': {
            'type': 'STRING',
            'enum': ['wifi', 'bluetooth', 'display'],
            'description': 'Target hardware feature',
          },
          'state': {
            'type': 'BOOLEAN',
            'description': 'True to enable/turn ON, False to disable/turn OFF',
          }
        },
        'required': ['target', 'state'],
      }
    },
    {
      'name': 'set_brightness',
      'description': 'Controls PC display brightness level from 0 to 100 percent.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'level': {
            'type': 'INTEGER',
            'description': 'Brightness percentage (0 to 100)',
          }
        },
        'required': ['level'],
      }
    },
    {
      'name': 'power_action',
      'description': 'Executes PC power protocols: lock screen, sleep, hibernate, log off, restart, or shutdown.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'action': {
            'type': 'STRING',
            'enum': ['lock', 'sleep', 'hibernate', 'logoff', 'restart', 'shutdown', 'display_off', 'display_wake'],
            'description': 'Power action to execute',
          }
        },
        'required': ['action'],
      }
    },
    {
      'name': 'get_pc_status',
      'description': 'Retrieves current live PC telemetry including battery, CPU, RAM, volume, Wi-Fi, Bluetooth, and display state.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {},
      }
    },
    {
      'name': 'execute_routine',
      'description': 'Executes a pre-defined tactical multi-step automated routine.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'routine': {
            'type': 'STRING',
            'enum': ['night_mode', 'gaming_mode', 'work_focus', 'power_saver'],
            'description': 'Pre-set tactical routine',
          }
        },
        'required': ['routine'],
      }
    }
  ];

  String _buildSystemPrompt() {
    return '''
You are "Nova", the tactical, futuristic Cybernetic AI Co-Pilot of Wintroller (PC Remote System).
You specialize strictly in automated hardware, media, brightness, power, and system telemetry controls.
You do NOT control mouse or keyboard typing directly.

Current PC Telemetry:
- Hostname: ${systemInfo.hostname}
- Battery: ${systemInfo.batteryPercent}% (${systemInfo.isCharging ? 'Charging' : 'On Battery'})
- CPU Load: ${systemInfo.cpuUsage.toStringAsFixed(0)}%
- RAM Usage: ${systemInfo.ramUsage.toStringAsFixed(0)}%
- Master Volume: ${systemInfo.volume}% (${systemInfo.isMuted ? 'Muted' : 'Active'})
- Brightness: ${systemInfo.brightness}%
- Wi-Fi Radio: ${systemInfo.isWifiOn ? 'ON' : 'OFF'}
- Bluetooth Radio: ${systemInfo.isBluetoothOn ? 'ON' : 'OFF'}
- Display State: ${systemInfo.isDisplayOn ? 'ON' : 'OFF'}

Rules:
1. Always call the appropriate function tool(s) when the user expresses intent to adjust or check their PC.
2. Multiple tools can be called in parallel if requested (e.g. "turn off wifi and mute volume").
3. Keep spoken and text responses concise, confident, and with a sleek tactical cybernetic personality (1-2 sentences).
''';
  }

  Future<NovaResponse> processCommand(String userPrompt, {List<Map<String, dynamic>> conversationHistory = const []}) async {
    final key = apiKey?.trim();
    if (key == null || key.isEmpty) {
      return const NovaResponse(
        text: 'Nova AI requires a Google Gemini API Key. Please configure your key in Settings or upgrade to Pro.',
        isError: true,
      );
    }

    try {
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$key');

      final contents = [
        ...conversationHistory,
        {
          'role': 'user',
          'parts': [{'text': userPrompt}]
        }
      ];

      final requestBody = {
        'contents': contents,
        'systemInstruction': {
          'parts': [{'text': _buildSystemPrompt()}]
        },
        'tools': [
          {'functionDeclarations': _toolDeclarations}
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 500,
        }
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        final errorJson = json.decode(response.body);
        final errorMessage = errorJson['error']?['message'] ?? 'API Error ${response.statusCode}';
        return NovaResponse(
          text: 'Nova Tactical Link Failed: $errorMessage',
          isError: true,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return const NovaResponse(
          text: 'Nova received an empty response signal from the neural core.',
          isError: true,
        );
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>? ?? [];

      String replyText = '';
      final List<NovaActionResult> executedActions = [];

      for (final part in parts) {
        if (part is Map<String, dynamic>) {
          if (part.containsKey('text')) {
            replyText += part['text'] as String;
          }

          if (part.containsKey('functionCall')) {
            final functionCall = part['functionCall'] as Map<String, dynamic>;
            final name = functionCall['name'] as String;
            final args = (functionCall['args'] as Map<String, dynamic>?) ?? {};

            final actionResult = await _executeTool(name, args);
            executedActions.add(actionResult);
          }
        }
      }

      // If Gemini returned function calls without prose text, create a crisp confirmation
      if (replyText.trim().isEmpty && executedActions.isNotEmpty) {
        final messages = executedActions.map((a) => a.message).join(' ');
        replyText = 'Command executed. $messages';
      }

      return NovaResponse(
        text: replyText.trim(),
        executedActions: executedActions,
      );
    } catch (e) {
      return NovaResponse(
        text: 'Nova neural connection error: ${e.toString()}',
        isError: true,
      );
    }
  }

  Future<NovaActionResult> _executeTool(String name, Map<String, dynamic> args) async {
    try {
      switch (name) {
        case 'set_volume':
          final level = (args['level'] as num?)?.toInt() ?? 50;
          repository.setVolume(level);
          return NovaActionResult(
            toolName: name,
            arguments: args,
            success: true,
            message: 'Master volume calibrated to $level%.',
          );

        case 'media_control':
          final action = args['action'] as String? ?? 'play_pause';
          switch (action) {
            case 'play_pause':
              repository.mediaPlayPause();
              break;
            case 'next':
              repository.mediaNext();
              break;
            case 'previous':
              repository.mediaPrevious();
              break;
            case 'mute':
              repository.mediaMute();
              break;
            case 'unmute':
              repository.mediaUnmute();
              break;
            case 'mic_on':
              repository.mediaMicOn();
              break;
            case 'mic_off':
              repository.mediaMicOff();
              break;
            case 'volume_up':
              repository.mediaVolumeUp();
              break;
            case 'volume_down':
              repository.mediaVolumeDown();
              break;
          }
          return NovaActionResult(
            toolName: name,
            arguments: args,
            success: true,
            message: 'Media protocol [$action] executed.',
          );

        case 'hardware_toggle':
          final target = args['target'] as String? ?? 'wifi';
          final state = args['state'] as bool? ?? true;
          if (target == 'wifi') {
            repository.setWifi(state);
            return NovaActionResult(
              toolName: name,
              arguments: args,
              success: true,
              message: 'Wi-Fi radio ${state ? 'activated' : 'deactivated'}.',
            );
          } else if (target == 'bluetooth') {
            repository.setBluetooth(state);
            return NovaActionResult(
              toolName: name,
              arguments: args,
              success: true,
              message: 'Bluetooth radio ${state ? 'activated' : 'deactivated'}.',
            );
          } else if (target == 'display') {
            repository.setDisplay(state);
            return NovaActionResult(
              toolName: name,
              arguments: args,
              success: true,
              message: 'Display power ${state ? 'woken' : 'powered down'}.',
            );
          }
          break;

        case 'set_brightness':
          final level = (args['level'] as num?)?.toInt() ?? 75;
          repository.setBrightness(level);
          return NovaActionResult(
            toolName: name,
            arguments: args,
            success: true,
            message: 'Display brightness set to $level%.',
          );

        case 'power_action':
          final action = args['action'] as String? ?? 'lock';
          switch (action) {
            case 'lock':
              repository.lock();
              break;
            case 'sleep':
              repository.sleep();
              break;
            case 'hibernate':
              repository.hibernate();
              break;
            case 'logoff':
              repository.logoff();
              break;
            case 'restart':
              repository.restart();
              break;
            case 'shutdown':
              repository.shutdown();
              break;
            case 'display_off':
              repository.setDisplay(false);
              break;
            case 'display_wake':
              repository.setDisplay(true);
              break;
          }
          return NovaActionResult(
            toolName: name,
            arguments: args,
            success: true,
            message: 'Power protocol [$action] initiated.',
          );

        case 'get_pc_status':
          return NovaActionResult(
            toolName: name,
            arguments: args,
            success: true,
            message: 'Host: ${systemInfo.hostname} | Battery: ${systemInfo.batteryPercent}% | CPU: ${systemInfo.cpuUsage.toStringAsFixed(0)}% | RAM: ${systemInfo.ramUsage.toStringAsFixed(0)}%',
          );

        case 'execute_routine':
          final routine = args['routine'] as String? ?? 'night_mode';
          if (routine == 'night_mode') {
            repository.setBrightness(10);
            repository.mediaMute();
            repository.setDisplay(false);
            return NovaActionResult(
              toolName: name,
              arguments: args,
              success: true,
              message: 'Night Mode engaged: Display off, volume muted, brightness dimmed.',
            );
          } else if (routine == 'gaming_mode') {
            repository.setBrightness(100);
            repository.setVolume(80);
            repository.setWifi(true);
            return NovaActionResult(
              toolName: name,
              arguments: args,
              success: true,
              message: 'Gaming Mode engaged: Max brightness, 80% volume, high-bandwidth Wi-Fi.',
            );
          } else if (routine == 'power_saver') {
            repository.setBrightness(20);
            repository.setBluetooth(false);
            return NovaActionResult(
              toolName: name,
              arguments: args,
              success: true,
              message: 'Power Saver engaged: Dimmed brightness, Bluetooth radio disabled.',
            );
          }
          break;
      }
      return NovaActionResult(
        toolName: name,
        arguments: args,
        success: false,
        message: 'Unknown action.',
      );
    } catch (e) {
      return NovaActionResult(
        toolName: name,
        arguments: args,
        success: false,
        message: 'Execution error: $e',
      );
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final proState = ref.watch(proPlanProvider);
  final repo = ref.watch(pcRemoteRepositoryProvider);
  final sysInfo = ref.watch(systemInfoProvider).value ?? const HostSystemInfo();

  return GeminiService(
    apiKey: proState.geminiApiKey,
    repository: repo,
    systemInfo: sysInfo,
  );
});
