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
      'description': 'Controls media playback, volume steps, or mic status on the PC.',
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
    final key = apiKey?.trim().replaceAll('"', '').replaceAll("'", '').replaceAll('\n', '').replaceAll('\r', '');

    // If no key or short key, immediately use Local Tactical Neural Core
    if (key == null || key.length < 10) {
      return _processLocalCommand(userPrompt);
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
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': key,
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // Fallback to local tactical processor so user's command is NEVER lost
        final localRes = await _processLocalCommand(userPrompt);
        return NovaResponse(
          text: '${localRes.text}\n[Note: Gemini API key authentication failed. Executed via Local Tactical Core. Get a free key at https://aistudio.google.com/apikey]',
          executedActions: localRes.executedActions,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return _processLocalCommand(userPrompt);
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

      if (replyText.trim().isEmpty && executedActions.isNotEmpty) {
        final messages = executedActions.map((a) => a.message).join(' ');
        replyText = 'Protocol confirmed. $messages';
      }

      if (executedActions.isEmpty && replyText.isEmpty) {
        return _processLocalCommand(userPrompt);
      }

      return NovaResponse(
        text: replyText.trim(),
        executedActions: executedActions,
      );
    } catch (e) {
      // Automatic fallback to local tactical engine
      final localRes = await _processLocalCommand(userPrompt);
      return NovaResponse(
        text: '${localRes.text}\n[Offline Tactical Core Engaged]',
        executedActions: localRes.executedActions,
      );
    }
  }

  // Instant Local Tactical Core Engine (0ms Latency Fallback)
  Future<NovaResponse> _processLocalCommand(String prompt) async {
    final lower = prompt.toLowerCase();
    final List<NovaActionResult> actions = [];
    final List<String> messages = [];

    // 1. Routine: Night Mode
    if (lower.contains('night mode') || lower.contains('good night') || lower.contains('bedtime')) {
      final res = await _executeTool('execute_routine', {'routine': 'night_mode'});
      actions.add(res);
      messages.add(res.message);
    }
    // 2. Routine: Gaming Mode
    else if (lower.contains('gaming mode') || lower.contains('game mode')) {
      final res = await _executeTool('execute_routine', {'routine': 'gaming_mode'});
      actions.add(res);
      messages.add(res.message);
    }
    // 3. Routine: Power Saver
    else if (lower.contains('power saver') || lower.contains('battery saver')) {
      final res = await _executeTool('execute_routine', {'routine': 'power_saver'});
      actions.add(res);
      messages.add(res.message);
    }

    // 4. Volume Control
    final volMatch = RegExp(r'(?:volume|vol|sound)\s*(?:to|at|=)?\s*(\d{1,3})%?').firstMatch(lower);
    if (volMatch != null) {
      final level = int.tryParse(volMatch.group(1)!)?.clamp(0, 100) ?? 50;
      final res = await _executeTool('set_volume', {'level': level});
      actions.add(res);
      messages.add(res.message);
    } else if (lower.contains('volume up') || lower.contains('louder') || lower.contains('increase volume')) {
      final res = await _executeTool('media_control', {'action': 'volume_up'});
      actions.add(res);
      messages.add(res.message);
    } else if (lower.contains('volume down') || lower.contains('quieter') || lower.contains('decrease volume') || lower.contains('lower volume')) {
      final res = await _executeTool('media_control', {'action': 'volume_down'});
      actions.add(res);
      messages.add(res.message);
    }

    // 5. Mute / Unmute
    if (lower.contains('unmute') || lower.contains('sound on')) {
      final res = await _executeTool('media_control', {'action': 'unmute'});
      actions.add(res);
      messages.add(res.message);
    } else if (lower.contains('mute') || lower.contains('silence') || lower.contains('sound off')) {
      final res = await _executeTool('media_control', {'action': 'mute'});
      actions.add(res);
      messages.add(res.message);
    }

    // 6. Media Playback
    if (lower.contains('play') || lower.contains('pause') || lower.contains('resume')) {
      final res = await _executeTool('media_control', {'action': 'play_pause'});
      actions.add(res);
      messages.add(res.message);
    } else if (lower.contains('next song') || lower.contains('next track') || lower.contains('skip')) {
      final res = await _executeTool('media_control', {'action': 'next'});
      actions.add(res);
      messages.add(res.message);
    } else if (lower.contains('prev') || lower.contains('previous song')) {
      final res = await _executeTool('media_control', {'action': 'previous'});
      actions.add(res);
      messages.add(res.message);
    }

    // 7. Wi-Fi Toggle
    if (lower.contains('wifi') || lower.contains('wi-fi')) {
      final state = !lower.contains('off') && !lower.contains('disable');
      final res = await _executeTool('hardware_toggle', {'target': 'wifi', 'state': state});
      actions.add(res);
      messages.add(res.message);
    }

    // 8. Bluetooth Toggle
    if (lower.contains('bluetooth') || lower.contains('bt')) {
      final state = !lower.contains('off') && !lower.contains('disable');
      final res = await _executeTool('hardware_toggle', {'target': 'bluetooth', 'state': state});
      actions.add(res);
      messages.add(res.message);
    }

    // 9. Display Power
    if (lower.contains('display') || lower.contains('screen') || lower.contains('monitor')) {
      if (lower.contains('off') || lower.contains('sleep') || lower.contains('turn off')) {
        final res = await _executeTool('hardware_toggle', {'target': 'display', 'state': false});
        actions.add(res);
        messages.add(res.message);
      } else if (lower.contains('on') || lower.contains('wake') || lower.contains('turn on')) {
        final res = await _executeTool('hardware_toggle', {'target': 'display', 'state': true});
        actions.add(res);
        messages.add(res.message);
      }
    }

    // 10. Brightness
    final brightMatch = RegExp(r'brightness\s*(?:to|at|=)?\s*(\d{1,3})%?').firstMatch(lower);
    if (brightMatch != null) {
      final level = int.tryParse(brightMatch.group(1)!)?.clamp(0, 100) ?? 75;
      final res = await _executeTool('set_brightness', {'level': level});
      actions.add(res);
      messages.add(res.message);
    } else if (lower.contains('max brightness') || lower.contains('full brightness')) {
      final res = await _executeTool('set_brightness', {'level': 100});
      actions.add(res);
      messages.add(res.message);
    } else if (lower.contains('dim brightness') || lower.contains('low brightness')) {
      final res = await _executeTool('set_brightness', {'level': 20});
      actions.add(res);
      messages.add(res.message);
    }

    // 11. Power Actions
    if (lower.contains('lock')) {
      final res = await _executeTool('power_action', {'action': 'lock'});
      actions.add(res);
      messages.add(res.message);
    } else if (lower.contains('sleep pc') || lower.contains('put pc to sleep')) {
      final res = await _executeTool('power_action', {'action': 'sleep'});
      actions.add(res);
      messages.add(res.message);
    } else if (lower.contains('hibernate')) {
      final res = await _executeTool('power_action', {'action': 'hibernate'});
      actions.add(res);
      messages.add(res.message);
    } else if (lower.contains('restart') || lower.contains('reboot')) {
      final res = await _executeTool('power_action', {'action': 'restart'});
      actions.add(res);
      messages.add(res.message);
    } else if (lower.contains('shutdown') || lower.contains('turn off pc')) {
      final res = await _executeTool('power_action', {'action': 'shutdown'});
      actions.add(res);
      messages.add(res.message);
    }

    // 12. Telemetry Inquiries
    if (lower.contains('battery') || lower.contains('cpu') || lower.contains('ram') || lower.contains('load') || lower.contains('status')) {
      final res = await _executeTool('get_pc_status', {});
      actions.add(res);
      messages.add(res.message);
    }

    if (actions.isNotEmpty) {
      return NovaResponse(
        text: messages.join(' '),
        executedActions: actions,
      );
    }

    return const NovaResponse(
      text: 'Nova Tactical AI received your signal. Try commands like "Set volume to 30%", "Night Mode", "Turn off Wi-Fi", "Lock PC", or "Check battery".',
      isError: false,
    );
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
