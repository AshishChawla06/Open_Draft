class Redaction {
  final int start;
  final int end;
  final String style; // 'bar', 'blur', 'inline'
  final String? reason;
  final int? clearanceLevel;
  final bool revealed;
  final double? x;
  final double? y;
  final double? width;
  final double? height;
  final String displayMode; // 'inline', 'overlay'

  Redaction({
    required this.start,
    required this.end,
    this.style = 'bar',
    this.reason,
    this.clearanceLevel,
    this.revealed = false,
    this.x,
    this.y,
    this.width,
    this.height,
    this.displayMode = 'inline',
  });

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'style': style,
      'reason': reason,
      'clearanceLevel': clearanceLevel,
      'revealed': revealed,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'displayMode': displayMode,
    };
  }

  factory Redaction.fromJson(Map<String, dynamic> json) {
    return Redaction(
      start: json['start'] as int? ?? 0,
      end: json['end'] as int? ?? 0,
      style: json['style'] as String? ?? 'bar',
      reason: json['reason'] as String?,
      clearanceLevel: json['clearanceLevel'] as int?,
      revealed: json['revealed'] as bool? ?? false,
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      displayMode: json['displayMode'] as String? ?? 'inline',
    );
  }

  Redaction copyWith({
    int? start,
    int? end,
    String? style,
    String? reason,
    int? clearanceLevel,
    bool? revealed,
    double? x,
    double? y,
    double? width,
    double? height,
    String? displayMode,
  }) {
    return Redaction(
      start: start ?? this.start,
      end: end ?? this.end,
      style: style ?? this.style,
      reason: reason ?? this.reason,
      clearanceLevel: clearanceLevel ?? this.clearanceLevel,
      revealed: revealed ?? this.revealed,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      displayMode: displayMode ?? this.displayMode,
    );
  }
}
