class Redaction {
  final int start;
  final int end;
  final String style; // 'bar', 'blur', 'inline'
  final String? reason;
  final int? clearanceLevel;
  final bool revealed;

  Redaction({
    required this.start,
    required this.end,
    this.style = 'bar',
    this.reason,
    this.clearanceLevel,
    this.revealed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'style': style,
      'reason': reason,
      'clearanceLevel': clearanceLevel,
      'revealed': revealed,
    };
  }

  factory Redaction.fromJson(Map<String, dynamic> json) {
    return Redaction(
      start: json['start'] as int,
      end: json['end'] as int,
      style: json['style'] as String? ?? 'bar',
      reason: json['reason'] as String?,
      clearanceLevel: json['clearanceLevel'] as int?,
      revealed: json['revealed'] as bool? ?? false,
    );
  }

  Redaction copyWith({
    int? start,
    int? end,
    String? style,
    String? reason,
    int? clearanceLevel,
    bool? revealed,
  }) {
    return Redaction(
      start: start ?? this.start,
      end: end ?? this.end,
      style: style ?? this.style,
      reason: reason ?? this.reason,
      clearanceLevel: clearanceLevel ?? this.clearanceLevel,
      revealed: revealed ?? this.revealed,
    );
  }
}
