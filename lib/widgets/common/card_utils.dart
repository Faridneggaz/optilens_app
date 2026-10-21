import 'package:flutter/material.dart';

Widget buildSimpleCard(String title, String value) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color.fromARGB(255, 255, 254, 254)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color.fromRGBO(31, 40, 55, 1),
          ),
        ),
      ],
    ),
  );
}
