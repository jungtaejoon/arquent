enum ParameterType {
  string,
  number,
  boolean,
  enumType,
  list,
}

class ParameterDefinition {
  const ParameterDefinition({
    required this.key,
    required this.label,
    required this.type,
    this.description,
    this.required = false,
    this.defaultValue,
    this.options,
  });

  final String key;
  final String label;
  final ParameterType type;
  final String? description;
  final bool required;
  final dynamic defaultValue;
  final List<String>? options;
}

class TriggerDefinition {
  const TriggerDefinition({
    required this.type,
    required this.label,
    required this.guide,
    required this.userInitiated,
    this.parameters = const [],
  });

  final String type;
  final String label;
  final String guide;
  final bool userInitiated;
  final List<ParameterDefinition> parameters;
}

class ActionDefinition {
  const ActionDefinition({
    required this.type,
    required this.label,
    required this.category,
    required this.guide,
    required this.sensitive,
    required this.supportedLocally,
    required this.defaultParams,
    this.parameters = const [],
    this.outputs = const {},
  });

  final String type;
  final String label;
  final String category;
  final String guide;
  final bool sensitive;
  final bool supportedLocally;
  final Map<String, dynamic> defaultParams;
  final List<ParameterDefinition> parameters;
  final Map<String, String> outputs;
}

class RecipeTemplateDefinition {
  const RecipeTemplateDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.usageSteps,
    required this.triggerType,
    required this.riskLevel,
    required this.actions,
    required this.tags,
    this.actionParamOverrides = const {},
  });

  final String id;
  final String name;
  final String description;
  final List<String> usageSteps;
  final String triggerType;
  final String riskLevel;
  final List<String> actions;
  final List<String> tags;
  final Map<String, Map<String, dynamic>> actionParamOverrides;
}

const triggerCatalog = <TriggerDefinition>[
  TriggerDefinition(
    type: 'trigger.manual',
    label: 'Manual Run',
    guide: '사용자가 직접 실행 버튼을 누를 때 동작',
    userInitiated: true,
  ),
  TriggerDefinition(
    type: 'trigger.hotkey',
    label: 'Hotkey',
    guide: '단축키 입력으로 실행',
    userInitiated: true,
    parameters: [
      ParameterDefinition(
        key: 'key_combo',
        label: 'Key Combination',
        type: ParameterType.string,
        description: 'e.g. Ctrl+Shift+A',
        required: true,
      ),
    ],
  ),
  TriggerDefinition(
    type: 'trigger.widget_tap',
    label: 'Widget Tap',
    guide: '위젯 탭으로 실행',
    userInitiated: true,
    parameters: [
      ParameterDefinition(
        key: 'widget_id',
        label: 'Widget ID',
        type: ParameterType.string,
        required: true,
      ),
    ],
  ),
  TriggerDefinition(
    type: 'trigger.share_sheet',
    label: 'Share Sheet',
    guide: '공유 시트에서 전달된 입력으로 실행',
    userInitiated: true,
    parameters: [
      ParameterDefinition(
        key: 'accepted_types',
        label: 'Accepted Types',
        type: ParameterType.list,
        description: 'e.g. text/plain, image/*',
        defaultValue: ['text/plain'],
      ),
    ],
  ),
  TriggerDefinition(
    type: 'trigger.schedule',
    label: 'Schedule',
    guide: '시간/주기 기반 자동 실행 (민감 동작에는 비권장)',
    userInitiated: false,
    parameters: [
      ParameterDefinition(
        key: 'cron_expression',
        label: 'Cron Expression',
        type: ParameterType.string,
        description: 'e.g. 0 0 * * * (Every day at midnight)',
        required: true,
      ),
    ],
  ),
  TriggerDefinition(
    type: 'trigger.app_open',
    label: 'App Open',
    guide: '앱 시작 시 실행',
    userInitiated: false,
  ),
  TriggerDefinition(
    type: 'trigger.location_enter',
    label: 'Location Enter',
    guide: '특정 위치 진입 시 실행',
    userInitiated: false,
    parameters: [
      ParameterDefinition(
        key: 'latitude',
        label: 'Latitude',
        type: ParameterType.number,
        required: true,
      ),
      ParameterDefinition(
        key: 'longitude',
        label: 'Longitude',
        type: ParameterType.number,
        required: true,
      ),
      ParameterDefinition(
        key: 'radius_meters',
        label: 'Radius (meters)',
        type: ParameterType.number,
        defaultValue: 100,
      ),
    ],
  ),
  TriggerDefinition(
    type: 'trigger.webhook',
    label: 'Webhook',
    guide: '외부 HTTP 이벤트 수신 시 실행',
    userInitiated: false,
    parameters: [
      ParameterDefinition(
        key: 'path',
        label: 'Webhook Path',
        type: ParameterType.string,
        required: true,
      ),
    ],
  ),
  TriggerDefinition(
    type: 'trigger.recipe_completed',
    label: 'Recipe Completed',
    guide: '다른 레시피 실행 완료 후 연쇄 실행',
    userInitiated: false,
    parameters: [
      ParameterDefinition(
        key: 'source_recipe_id',
        label: 'Source Recipe ID',
        type: ParameterType.string,
        required: true,
      ),
      ParameterDefinition(
        key: 'on_status',
        label: 'On Status',
        type: ParameterType.enumType,
        options: ['success', 'failure', 'any'],
        defaultValue: 'success',
      ),
    ],
  ),
];

const actionCatalog = <ActionDefinition>[
  ActionDefinition(
    type: 'notification.send',
    label: 'Notification Send',
    category: 'Output',
    guide: '사용자에게 결과를 알림으로 표시',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {'title': 'Automation done', 'body': 'Run {{metadata.run_id}} finished.'},
    outputs: const {
      'last_notification': 'The notification that was just sent (includes title/body)',
    },
    parameters: [
      ParameterDefinition(
        key: 'title',
        label: 'Title',
        type: ParameterType.string,
        required: true,
      ),
      ParameterDefinition(
        key: 'body',
        label: 'Body',
        type: ParameterType.string,
        required: true,
      ),
    ],
  ),
  ActionDefinition(
    type: 'file.write',
    label: 'File Write',
    category: 'File',
    guide: '샌드박스 파일 쓰기',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {'uri': 'sandbox://notes/{{metadata.run_id}}.txt', 'content': 'Created from Builder'},
    outputs: const {
      'last_file_uri': 'The URI of the file that was written',
    },
    parameters: [
      ParameterDefinition(
        key: 'uri',
        label: 'File URI',
        type: ParameterType.string,
        required: true,
      ),
      ParameterDefinition(
        key: 'content',
        label: 'Content',
        type: ParameterType.string,
        required: true,
      ),
    ],
  ),
  ActionDefinition(
    type: 'file.move',
    label: 'File Move',
    category: 'File',
    guide: '샌드박스 파일 이동',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {'uri': 'sandbox://notes/source.txt', 'destination': 'sandbox://archive/target.txt'},
    outputs: const {
      'last_file_uri': 'The new URI of the moved file',
    },
    parameters: [
      ParameterDefinition(
        key: 'uri',
        label: 'Source URI',
        type: ParameterType.string,
        required: true,
      ),
      ParameterDefinition(
        key: 'destination',
        label: 'Destination URI',
        type: ParameterType.string,
        required: true,
      ),
    ],
  ),
  ActionDefinition(
    type: 'file.rename',
    label: 'File Rename',
    category: 'File',
    guide: '샌드박스 파일 이름 변경',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {'uri': 'sandbox://notes/source.txt', 'new_name': 'renamed.txt'},
    outputs: const {
      'last_file_uri': 'The new URI of the renamed file',
    },
    parameters: [
      ParameterDefinition(
        key: 'uri',
        label: 'Source URI',
        type: ParameterType.string,
        required: true,
      ),
      ParameterDefinition(
        key: 'new_name',
        label: 'New Name',
        type: ParameterType.string,
        required: true,
      ),
    ],
  ),
  ActionDefinition(
    type: 'clipboard.write',
    label: 'Clipboard Write',
    category: 'Clipboard',
    guide: '텍스트를 클립보드에 복사',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {'text': 'Copied from automation run'},
    outputs: const {
      'clipboard_text': 'The text that was written to clipboard',
    },
    parameters: [
      ParameterDefinition(
        key: 'text',
        label: 'Text to Copy',
        type: ParameterType.string,
        required: true,
      ),
    ],
  ),
  ActionDefinition(
    type: 'clipboard.read',
    label: 'Clipboard Read',
    category: 'Clipboard',
    guide: '현재 클립보드 텍스트를 상태로 읽기',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {},
    outputs: const {
      'clipboard_text': 'The text read from clipboard',
    },
  ),
  ActionDefinition(
    type: 'http.request',
    label: 'HTTP Request',
    category: 'Network',
    guide: 'URL로 GET/POST 요청',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {'method': 'GET', 'url': 'https://example.com'},
    outputs: const {
      'http_status': 'Response status code (e.g. 200)',
      'http_body': 'Response body text',
      'http_error': 'Error message if failed',
    },
    parameters: [
      ParameterDefinition(
        key: 'method',
        label: 'HTTP Method',
        type: ParameterType.enumType,
        options: ['GET', 'POST', 'PUT', 'DELETE'],
        defaultValue: 'GET',
      ),
      ParameterDefinition(
        key: 'url',
        label: 'URL',
        type: ParameterType.string,
        required: true,
      ),
      ParameterDefinition(
        key: 'headers',
        label: 'Headers (JSON)',
        type: ParameterType.string,
      ),
      ParameterDefinition(
        key: 'body',
        label: 'Body',
        type: ParameterType.string,
      ),
    ],
  ),
  ActionDefinition(
    type: 'network.request',
    label: 'Network Request (Alias)',
    category: 'Network',
    guide: 'http.request와 동일하게 동작하는 별칭',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {'method': 'GET', 'url_from_input': true, 'timeout_ms': 12000},
    outputs: const {
      'http_status': 'Response status code (e.g. 200)',
      'http_body': 'Response body text',
      'http_error': 'Error message if failed',
    },
    parameters: [
      ParameterDefinition(
        key: 'method',
        label: 'HTTP Method',
        type: ParameterType.enumType,
        options: ['GET', 'POST', 'PUT', 'DELETE'],
        defaultValue: 'GET',
      ),
      ParameterDefinition(
        key: 'url_from_input',
        label: 'URL from Input',
        type: ParameterType.boolean,
        defaultValue: true,
      ),
      ParameterDefinition(
        key: 'timeout_ms',
        label: 'Timeout (ms)',
        type: ParameterType.number,
        defaultValue: 12000,
      ),
    ],
  ),
  ActionDefinition(
    type: 'text.summarize',
    label: 'Text Summarize',
    category: 'Transform',
    guide: '텍스트를 핵심 문장으로 요약',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {'source': 'http_body', 'max_sentences': 5, 'language': 'ko'},
    outputs: const {
      'summary': 'The summarized text',
    },
    parameters: [
      ParameterDefinition(
        key: 'source',
        label: 'Source Variable',
        type: ParameterType.string,
        defaultValue: 'http_body',
      ),
      ParameterDefinition(
        key: 'max_sentences',
        label: 'Max Sentences',
        type: ParameterType.number,
        defaultValue: 5,
      ),
      ParameterDefinition(
        key: 'language',
        label: 'Language',
        type: ParameterType.string,
        defaultValue: 'ko',
      ),
    ],
  ),
  ActionDefinition(
    type: 'transform.regex_clean',
    label: 'Regex Clean',
    category: 'Transform',
    guide: '공백/노이즈를 정리한 텍스트 생성',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {},
    outputs: const {
      'cleaned_text': 'Text with whitespace normalized',
    },
  ),
  ActionDefinition(
    type: 'transform.ocr_text',
    label: 'OCR Text',
    category: 'Transform',
    guide: '이미지에서 텍스트 추출(샘플)',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {},
    outputs: const {
      'ocr_text': 'Text detected in the image',
    },
  ),
  ActionDefinition(
    type: 'transform.ocr_receipt',
    label: 'OCR Receipt',
    category: 'Transform',
    guide: '영수증 텍스트를 CSV 라인으로 변환(샘플)',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {},
    outputs: const {
      'expense_csv_line': 'Parsed receipt data (date, item, price)',
    },
  ),
  ActionDefinition(
    type: 'transform.speech_to_text',
    label: 'Speech To Text',
    category: 'Transform',
    guide: '음성 내용을 텍스트로 변환(샘플)',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {},
    outputs: const {
      'transcript': 'Transcribed text from audio',
    },
  ),
  ActionDefinition(
    type: 'transform.qr_decode',
    label: 'QR Decode',
    category: 'Transform',
    guide: 'QR 데이터를 URL/텍스트로 디코딩(샘플)',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {},
    outputs: const {
      'decoded_qr': 'Decoded content from QR code',
    },
  ),
  ActionDefinition(
    type: 'camera.capture',
    label: 'Camera Capture',
    category: 'Sensitive',
    guide: '카메라 촬영 후 파일 저장',
    sensitive: true,
    supportedLocally: true,
    defaultParams: {'output_uri': 'sandbox://captures/photo_{{metadata.run_id}}.jpg'},
    outputs: const {
      'capture_uri': 'Resolved URI where photo was saved',
      'capture_source': 'Original source path from device',
    },
    parameters: [
      ParameterDefinition(
        key: 'output_uri',
        label: 'Output URI',
        type: ParameterType.string,
        required: true,
      ),
    ],
  ),
  ActionDefinition(
    type: 'webcam.capture',
    label: 'Webcam Capture',
    category: 'Sensitive',
    guide: '웹캠 촬영 후 파일 저장',
    sensitive: true,
    supportedLocally: true,
    defaultParams: {'output_uri': 'sandbox://captures/webcam_{{metadata.run_id}}.jpg'},
    outputs: const {
       'capture_uri': 'Resolved URI where photo was saved',
       'capture_source': 'Original source path from device',
    },
    parameters: [
      ParameterDefinition(
        key: 'output_uri',
        label: 'Output URI',
        type: ParameterType.string,
        required: true,
      ),
    ],
  ),
  ActionDefinition(
    type: 'microphone.record',
    label: 'Microphone Record',
    category: 'Sensitive',
    guide: '마이크 녹음 후 파일 저장',
    sensitive: true,
    supportedLocally: true,
    defaultParams: {'max_seconds': 3, 'output_uri': 'sandbox://captures/audio_{{metadata.run_id}}.wav'},
    outputs: const {
       'record_uri': 'Resolved URI where audio was saved',
       'record_source': 'Original source path from device',
    },
    parameters: [
      ParameterDefinition(
        key: 'max_seconds',
        label: 'Max Seconds',
        type: ParameterType.number,
        defaultValue: 3,
      ),
      ParameterDefinition(
        key: 'output_uri',
        label: 'Output URI',
        type: ParameterType.string,
        required: true,
      ),
    ],
  ),
  ActionDefinition(
    type: 'health.read',
    label: 'Health Read',
    category: 'Sensitive',
    guide: '수면/걸음수 요약 읽기',
    sensitive: true,
    supportedLocally: true,
    defaultParams: {},
    outputs: const {
      'sleep_hours': 'Daily sleep hours',
      'steps': 'Daily step count',
    },
  ),
  ActionDefinition(
    type: 'command.execute_allowlist',
    label: 'Command Execute (Allowlist)',
    category: 'System',
    guide: '허용된 명령만 실행 (현재 git pull)',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {'command': 'git pull'},
    outputs: const {
      'command_output': 'Output of the command',
    },
    parameters: [
      ParameterDefinition(
        key: 'command',
        label: 'Command',
        type: ParameterType.string,
        required: true,
      ),
    ],
  ),
  ActionDefinition(
    type: 'recipe.run',
    label: 'Run Recipe (Chain)',
    category: 'Orchestration',
    guide: '현재 레시피 완료/실패 조건에 따라 다른 레시피 실행',
    sensitive: false,
    supportedLocally: true,
    defaultParams: {'recipe_id': '', 'when': 'on_success'},
    outputs: const {
      'chain_recipe_id': 'Next recipe ID to run',
    },
    parameters: [
      ParameterDefinition(
        key: 'recipe_id',
        label: 'Recipe ID',
        type: ParameterType.string,
        required: true,
      ),
      ParameterDefinition(
        key: 'when',
        label: 'When to Run',
        type: ParameterType.enumType,
        options: ['on_success', 'on_failure', 'always'],
        defaultValue: 'on_success',
      ),
      ParameterDefinition(
        key: 'delay_ms',
        label: 'Delay (ms)',
        type: ParameterType.number,
        defaultValue: 0,
      ),
      ParameterDefinition(
        key: 'max_depth',
        label: 'Max Depth',
        type: ParameterType.number,
        defaultValue: 5,
      ),
    ],
  ),
];

ActionDefinition? actionDefinitionByType(String type) {
  for (final definition in actionCatalog) {
    if (definition.type == type) {
      return definition;
    }
  }
  return null;
}

Map<String, dynamic> defaultParamsForActionType(String type) {
  final definition = actionDefinitionByType(type);
  if (definition == null) {
    return {
      'title': 'Automation done',
      'body': 'Run {{metadata.run_id}} finished.',
    };
  }
  return Map<String, dynamic>.from(definition.defaultParams);
}

const recipeTemplates = <RecipeTemplateDefinition>[
  RecipeTemplateDefinition(
    id: 'template.web_quick_summary',
    name: 'Web Quick Summary',
    description: 'URL 입력을 받아 페이지를 요청하고 핵심 내용을 요약합니다.',
    usageSteps: [
      'Run Local 실행 시 URL 입력',
      '요청 완료 후 요약 텍스트 확인',
      '필요 시 알림 내용을 복사/공유',
    ],
    triggerType: 'trigger.manual',
    riskLevel: 'Standard',
    actions: ['network.request', 'text.summarize', 'notification.send'],
    tags: ['web', 'summary', 'productivity'],
    actionParamOverrides: {
      'network.request': {'method': 'GET', 'url_from_input': true, 'timeout_ms': 12000},
      'text.summarize': {'source': 'http_body', 'max_sentences': 5, 'language': 'ko'},
      'notification.send': {'title': '웹 요약 완료', 'body_from': 'summary'},
    },
  ),
  RecipeTemplateDefinition(
    id: 'template.clipboard_clean',
    name: 'Clipboard Clean + Notify',
    description: '클립보드 텍스트를 정리한 뒤 결과를 알림으로 보여줍니다.',
    usageSteps: [
      '클립보드에 원문 복사',
      'Run Local 실행',
      '정리된 결과를 알림으로 확인',
    ],
    triggerType: 'trigger.hotkey',
    riskLevel: 'Standard',
    actions: ['clipboard.read', 'transform.regex_clean', 'notification.send'],
    tags: ['clipboard', 'cleaning', 'text'],
    actionParamOverrides: {
      'notification.send': {'title': '정리 완료', 'body_from': 'cleaned_text'},
    },
  ),
  RecipeTemplateDefinition(
    id: 'template.receipt_to_csv',
    name: 'Receipt OCR to CSV',
    description: '영수증 이미지를 텍스트로 추출해 CSV 라인 형태로 만듭니다.',
    usageSteps: [
      '카메라 촬영 또는 이미지 입력 준비',
      'Run Local 실행',
      'CSV 라인을 알림 또는 파일로 확인',
    ],
    triggerType: 'trigger.manual',
    riskLevel: 'Sensitive',
    actions: ['camera.capture', 'transform.ocr_receipt', 'notification.send'],
    tags: ['ocr', 'receipt', 'finance'],
    actionParamOverrides: {
      'notification.send': {'title': '영수증 처리 완료', 'body_from': 'expense_csv_line'},
    },
  ),
  RecipeTemplateDefinition(
    id: 'template.voice_todo',
    name: 'Voice Memo to TODO',
    description: '음성 녹음을 텍스트로 변환하고 요약 TODO를 생성합니다.',
    usageSteps: [
      'Run Local 실행',
      '짧게 음성 녹음',
      '변환/요약된 TODO 확인',
    ],
    triggerType: 'trigger.manual',
    riskLevel: 'Sensitive',
    actions: ['microphone.record', 'transform.speech_to_text', 'notification.send'],
    tags: ['voice', 'todo', 'productivity'],
    actionParamOverrides: {
      'microphone.record': {'max_seconds': 10},
      'notification.send': {'title': 'TODO 변환 완료', 'body_from': 'transcript'},
    },
  ),
];

RecipeTemplateDefinition? recipeTemplateById(String id) {
  for (final template in recipeTemplates) {
    if (template.id == id) {
      return template;
    }
  }
  return null;
}

TriggerDefinition? triggerDefinitionByType(String type) {
  for (final definition in triggerCatalog) {
    if (definition.type == type) {
      return definition;
    }
  }
  return null;
}

Map<String, dynamic> defaultParamsForTriggerType(String type) {
  final definition = triggerDefinitionByType(type);
  if (definition == null) return {};
  
  final params = <String, dynamic>{};
  for (final param in definition.parameters) {
    if (param.defaultValue != null) {
      params[param.key] = param.defaultValue;
    }
  }
  return params;
}
