import 'package:flutter/material.dart';

class FormatOption {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  FormatOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

// List of supported formats (matching PDF Converter Pro API)
final List<FormatOption> inputFormats = [
  // Document formats
  FormatOption(
      id: 'pdf', name: 'PDF', icon: Icons.picture_as_pdf, color: Colors.red),
  FormatOption(
      id: 'docx', name: 'DOCX', icon: Icons.description, color: Colors.blue),
  FormatOption(
      id: 'doc',
      name: 'DOC',
      icon: Icons.description,
      color: Colors.blue.shade800),
  FormatOption(
      id: 'rtf', name: 'RTF', icon: Icons.text_fields, color: Colors.orange),
  FormatOption(
      id: 'odt', name: 'ODT', icon: Icons.description, color: Colors.indigo),
  FormatOption(
      id: 'txt', name: 'TXT', icon: Icons.text_snippet, color: Colors.grey),
  FormatOption(id: 'html', name: 'HTML', icon: Icons.code, color: Colors.teal),

  // Spreadsheet formats
  FormatOption(
      id: 'xlsx', name: 'XLSX', icon: Icons.table_chart, color: Colors.green),
  FormatOption(
      id: 'xls',
      name: 'XLS',
      icon: Icons.table_chart,
      color: Colors.green.shade800),
  FormatOption(
      id: 'csv', name: 'CSV', icon: Icons.table_rows, color: Colors.amber),
  FormatOption(
      id: 'ods',
      name: 'ODS',
      icon: Icons.table_chart,
      color: Colors.lightGreen),

  // Presentation formats
  FormatOption(
      id: 'pptx',
      name: 'PPTX',
      icon: Icons.slideshow,
      color: Colors.deepOrange),
  FormatOption(
      id: 'ppt',
      name: 'PPT',
      icon: Icons.slideshow,
      color: Colors.orange.shade800),
  FormatOption(
      id: 'odp', name: 'ODP', icon: Icons.slideshow, color: Colors.amber),

  // Image formats
  FormatOption(id: 'jpg', name: 'JPG', icon: Icons.image, color: Colors.purple),
  FormatOption(
      id: 'jpeg', name: 'JPEG', icon: Icons.image, color: Colors.purple),
  FormatOption(id: 'png', name: 'PNG', icon: Icons.image, color: Colors.pink),
];

final List<FormatOption> outputFormats = [
  // Document formats
  FormatOption(
      id: 'pdf', name: 'PDF', icon: Icons.picture_as_pdf, color: Colors.red),
  FormatOption(
      id: 'docx', name: 'DOCX', icon: Icons.description, color: Colors.blue),
  FormatOption(
      id: 'doc',
      name: 'DOC',
      icon: Icons.description,
      color: Colors.blue.shade800),
  FormatOption(
      id: 'rtf', name: 'RTF', icon: Icons.text_fields, color: Colors.orange),
  FormatOption(
      id: 'odt', name: 'ODT', icon: Icons.description, color: Colors.indigo),
  FormatOption(
      id: 'txt', name: 'TXT', icon: Icons.text_snippet, color: Colors.grey),
  FormatOption(id: 'html', name: 'HTML', icon: Icons.code, color: Colors.teal),

  // Spreadsheet formats
  FormatOption(
      id: 'xlsx', name: 'XLSX', icon: Icons.table_chart, color: Colors.green),
  FormatOption(
      id: 'xls',
      name: 'XLS',
      icon: Icons.table_chart,
      color: Colors.green.shade800),
  FormatOption(
      id: 'csv', name: 'CSV', icon: Icons.table_rows, color: Colors.amber),
  FormatOption(
      id: 'ods',
      name: 'ODS',
      icon: Icons.table_chart,
      color: Colors.lightGreen),

  // Presentation formats
  FormatOption(
      id: 'pptx',
      name: 'PPTX',
      icon: Icons.slideshow,
      color: Colors.deepOrange),
  FormatOption(
      id: 'ppt',
      name: 'PPT',
      icon: Icons.slideshow,
      color: Colors.orange.shade800),
  FormatOption(
      id: 'odp', name: 'ODP', icon: Icons.slideshow, color: Colors.amber),

  // Image formats
  FormatOption(id: 'jpg', name: 'JPG', icon: Icons.image, color: Colors.purple),
  FormatOption(
      id: 'jpeg', name: 'JPEG', icon: Icons.image, color: Colors.purple),
  FormatOption(id: 'png', name: 'PNG', icon: Icons.image, color: Colors.pink),
];
