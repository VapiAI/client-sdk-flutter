class Metadata {
    final String metadata;

    Metadata({required this.metadata});

    factory Metadata.fromJson(Map<String, dynamic> json) {
        return Metadata(
            metadata: json['metadata'] as String,
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'metadata': metadata,
        };
    }

}