import 'package:flutter/material.dart';
import 'package:calendario_familiar/core/utils/color_ext.dart';

class ColorPicker extends StatelessWidget {

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });
  final String selectedColor;
  final Function(String) onColorSelected;

  @override
  Widget build(BuildContext context) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppColors.eventColors.map((color) {
        final colorHex = color.toHex;
        final isSelected = selectedColor == colorHex;
        
        return GestureDetector(
          onTap: () => onColorSelected(color.toHex()),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
        );
      }).toList(),
    );
}

