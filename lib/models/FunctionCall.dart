class FunctionCall {
  final String name;
  final Map<String, dynamic> parameters;

  FunctionCall({required this.name, required this.parameters});

  factory FunctionCall.fromJson(Map<String, dynamic> json) {
    return FunctionCall(
      name: json['name'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
    };
  }
}