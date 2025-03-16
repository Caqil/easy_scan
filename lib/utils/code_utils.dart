// // Helper class to organize content type information
// import 'package:flutter/material.dart';



// ContentTypeInfo getContentTypeInfo(String value) {
//   if (value.startsWith('http://') || value.startsWith('https://')) {
//     return ContentTypeInfo(Icons.language, Colors.blue, 'URL');
//   } else if (value.startsWith('tel:') ||
//       RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(value)) {
//     return ContentTypeInfo(Icons.phone, Colors.green, 'Phone');
//   } else if (value.contains('@') && value.contains('.')) {
//     return ContentTypeInfo(Icons.email, Colors.orange, 'Email');
//   } else if (value.startsWith('WIFI:')) {
//     return ContentTypeInfo(Icons.wifi, Colors.purple, 'WiFi');
//   } else if (value.startsWith('MATMSG:') || value.startsWith('mailto:')) {
//     return ContentTypeInfo(Icons.email, Colors.orange, 'Email');
//   } else if (value.startsWith('geo:') ||
//       RegExp(r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$')
//           .hasMatch(value)) {
//     return ContentTypeInfo(Icons.location_on, Colors.red, 'Location');
//   } else if (value.startsWith('BEGIN:VCARD')) {
//     return ContentTypeInfo(Icons.contact_page, Colors.indigo, 'Contact');
//   } else if (value.startsWith('BEGIN:VEVENT')) {
//     return ContentTypeInfo(Icons.event, Colors.teal, 'Event');
//   } else if (RegExp(r'^[0-9]+$').hasMatch(value)) {
//     return ContentTypeInfo(Icons.qr_code, Colors.black, 'Product');
//   } else {
//     return ContentTypeInfo(Icons.text_fields, Colors.grey, 'Text');
//   }
// }

// // Get appropriate color for the barcode type
// Color getColorForType(String type) {
//   switch (type.toLowerCase()) {
//     case 'url':
//     case 'url/website':
//       return Colors.blue;
//     case 'phone':
//     case 'phone number':
//       return Colors.green;
//     case 'email':
//     case 'email address':
//     case 'email message':
//       return Colors.orange;
//     case 'wifi':
//     case 'wifi network':
//       return Colors.purple;
//     case 'location':
//       return Colors.red;
//     case 'contact':
//     case 'contact information':
//       return Colors.indigo;
//     case 'event':
//     case 'calendar event':
//       return Colors.teal;
//     case 'product':
//     case 'product code':
//       return Colors.brown;
//     case 'custom':
//       return Colors.deepPurple;
//     default:
//       return Colors.blueGrey;
//   }
// }
