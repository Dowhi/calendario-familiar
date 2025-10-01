import 'package:flutter/material.dart';

class CompactDropdown extends StatelessWidget {

  const CompactDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
    this.width = 0.18,
  }) : super(key: key);
  final String value;
  final List<Map<String, dynamic>> items;
  final ValueChanged<String?> onChanged;
  final String label;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: MediaQuery.of(context).size.width * width,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          isDense: true,
          labelText: label,
          labelStyle: const TextStyle(fontSize: 8, color: Colors.grey),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
        style: const TextStyle(fontSize: 9, color: Colors.black87),
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
          return DropdownMenuItem<String>(
            value: item['name'],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item['icon'] != null) 
                  Icon(item['icon'], size: 10, color: Colors.grey[700]),
                if (item['icon'] != null) 
                  const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    item['name'],
                    style: const TextStyle(fontSize: 8, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
}



