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
      id: 'rtf', name: 'RTF', icon: Icons.text_fields, color: Colors.orange),
  FormatOption(
      id: 'txt', name: 'TXT', icon: Icons.text_snippet, color: Colors.grey),
  FormatOption(id: 'html', name: 'HTML', icon: Icons.code, color: Colors.teal),

  // Spreadsheet formats
  FormatOption(
      id: 'xlsx', name: 'XLSX', icon: Icons.table_chart, color: Colors.green),

  // Presentation formats
  FormatOption(
      id: 'pptx',
      name: 'PPTX',
      icon: Icons.slideshow,
      color: Colors.deepOrange),

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
      id: 'rtf', name: 'RTF', icon: Icons.text_fields, color: Colors.orange),
  FormatOption(
      id: 'txt', name: 'TXT', icon: Icons.text_snippet, color: Colors.grey),
  FormatOption(id: 'html', name: 'HTML', icon: Icons.code, color: Colors.teal),

  // Spreadsheet formats
  FormatOption(
      id: 'xlsx', name: 'XLSX', icon: Icons.table_chart, color: Colors.green),

  // Presentation formats
  FormatOption(
      id: 'pptx',
      name: 'PPTX',
      icon: Icons.slideshow,
      color: Colors.deepOrange),

  // Image formats
  FormatOption(id: 'jpg', name: 'JPG', icon: Icons.image, color: Colors.purple),
  FormatOption(
      id: 'jpeg', name: 'JPEG', icon: Icons.image, color: Colors.purple),
  FormatOption(id: 'png', name: 'PNG', icon: Icons.image, color: Colors.pink),
];
