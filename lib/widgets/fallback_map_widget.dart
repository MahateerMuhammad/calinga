// import 'package:flutter/material.dart';

// class FallbackMapWidget extends StatelessWidget {
//   final double initialLat;
//   final double initialLng;
//   final List<Map<String, dynamic>> markers;
//   final Function(Map<String, dynamic>)? onMarkerTap;

//   const FallbackMapWidget({
//     Key? key,
//     required this.initialLat,
//     required this.initialLng,
//     required this.markers,
//     this.onMarkerTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       height: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [Colors.blue[100]!, Colors.blue[50]!],
//         ),
//       ),
//       child: Stack(
//         children: [
//           // Background pattern to simulate map
//           CustomPaint(size: Size.infinite, painter: MapPatternPainter()),

//           // Center location indicator
//           const Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.my_location, size: 40, color: Colors.blue),
//                 SizedBox(height: 8),
//                 Text(
//                   'Your Location',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Location info
//           Positioned(
//             top: 20,
//             left: 20,
//             right: 20,
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     spreadRadius: 1,
//                     blurRadius: 10,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Location Information',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   Text('Latitude: ${initialLat.toStringAsFixed(6)}'),
//                   Text('Longitude: ${initialLng.toStringAsFixed(6)}'),
//                   const SizedBox(height: 8),
//                   Text('${markers.length} caregivers found nearby'),
//                 ],
//               ),
//             ),
//           ),

//           // Caregivers list
//           if (markers.isNotEmpty)
//             Positioned(
//               bottom: 20,
//               left: 20,
//               right: 20,
//               child: Container(
//                 height: 200,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       spreadRadius: 1,
//                       blurRadius: 10,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Padding(
//                       padding: EdgeInsets.all(16),
//                       child: Text(
//                         'Nearby Caregivers',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child: ListView.builder(
//                         itemCount: markers.length,
//                         itemBuilder: (context, index) {
//                           final caregiver = markers[index];
//                           return ListTile(
//                             leading: CircleAvatar(
//                               backgroundColor: Colors.green,
//                               child: Text(
//                                 caregiver['name']?.substring(0, 1) ?? 'C',
//                                 style: const TextStyle(color: Colors.white),
//                               ),
//                             ),
//                             title: Text(caregiver['name'] ?? 'Unknown'),
//                             subtitle: Text(
//                               '${caregiver['role'] ?? 'Caregiver'} • ${caregiver['formattedDistance'] ?? 'Unknown distance'}',
//                             ),
//                             trailing: Text(
//                               '\$${caregiver['hourlyRate']?.toStringAsFixed(0) ?? '0'}/hr',
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             onTap: () => onMarkerTap?.call(caregiver),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//           // Map unavailable notice
//           Positioned(
//             top: 50,
//             right: 20,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.orange,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: const Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.warning, color: Colors.white, size: 16),
//                   SizedBox(width: 4),
//                   Text(
//                     'Map View Unavailable',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class MapPatternPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.blue.withOpacity(0.1)
//       ..strokeWidth = 1;

//     // Draw grid pattern to simulate map
//     const spacing = 50.0;

//     for (double x = 0; x < size.width; x += spacing) {
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
//     }

//     for (double y = 0; y < size.height; y += spacing) {
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
