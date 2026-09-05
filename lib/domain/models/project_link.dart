class ProjectLink {
  final String label;
  final String url;

  const ProjectLink({required this.label, required this.url});

  Map<String, dynamic> toJson() => {'label': label, 'url': url};

  factory ProjectLink.fromJson(Map<String, dynamic> json) => ProjectLink(
        label: json['label'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}
