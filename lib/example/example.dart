// PopupMenuButton<String>(
//           icon: Image.asset(
//                 'images/scanning.jpg',
//                 height: 20.0,
//                 fit: BoxFit.cover,
//               ),
//           onSelected: (String value) {
//             peerController.text = value;
//             _peer = value;
//           },
//           itemBuilder: (BuildContext context) {
//             return items.map<PopupMenuItem<String>>((String value) {
//               return new PopupMenuItem(child: new Text(value), value: value);
//             }).toList();
//           },
//         );