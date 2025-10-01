import 'package:flutter/material.dart';

class OverflowFixes {
  /// Widget que envuelve contenido para evitar overflow horizontal
  static Widget safeHorizontalContent({
    required Widget child,
    double? maxWidth,
    EdgeInsets? padding,
  }) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: maxWidth ?? 300,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(8.0),
          child: child,
        ),
      ),
    );

  /// Row que se convierte en Wrap en pantallas pequeñas
  static Widget responsiveRow({
    required BuildContext context,
    required List<Widget> children,
    double spacing = 8.0,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      // En pantallas pequeñas, usar Wrap
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children,
      );
    } else {
      // En pantallas más grandes, usar Row
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    }
  }

  /// Dropdown compacto que evita overflow
  static Widget compactDropdown({
    required String value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<String?> onChanged,
    required String label,
    double width = 0.28,
  }) => Builder(
      builder: (context) {
        return SizedBox(
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
      },
    );

  /// Botones responsivos que se adaptan al tamaño de pantalla
  static Widget responsiveButtons({
    required BuildContext context,
    required List<Widget> buttons,
    double spacing = 8.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      // En pantallas pequeñas, usar Wrap
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: buttons.map((button) => SizedBox(
            width: screenWidth * 0.35,
            child: button,
          )).toList(),
      );
    } else {
      // En pantallas más grandes, usar Row
      return Row(
        children: buttons.map((button) => Expanded(child: button)).toList(),
      );
    }
  }

  /// Contenedor que se adapta al contenido sin causar overflow
  static Widget adaptiveContainer({
    required Widget child,
    double? maxWidth,
    double? maxHeight,
    EdgeInsets? padding,
    BoxDecoration? decoration,
  }) => ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: Container(
        padding: padding,
        decoration: decoration,
        child: child,
      ),
    );

  /// Texto que se adapta al espacio disponible
  static Widget adaptiveText({
    required String text,
    TextStyle? style,
    TextAlign textAlign = TextAlign.start,
    int? maxLines,
    double? fontSize,
  }) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: style?.copyWith(fontSize: fontSize) ?? TextStyle(fontSize: fontSize),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );

  /// Lista que se adapta al espacio disponible
  static Widget adaptiveList({
    required List<Widget> children,
    Axis scrollDirection = Axis.vertical,
    double spacing = 8.0,
  }) => SingleChildScrollView(
      scrollDirection: scrollDirection,
      child: scrollDirection == Axis.horizontal
          ? Row(
              children: children.map((child) {
                return Padding(
                  padding: EdgeInsets.only(right: spacing),
                  child: child,
                );
              }).toList(),
            )
          : Column(
              children: children.map((child) {
                return Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: child,
                );
              }).toList(),
            ),
    );

  /// Tabla responsiva que se adapta a pantallas pequeñas
  static Widget responsiveTable({
    required List<Widget> headers,
    required List<List<Widget>> rows,
    double cellPadding = 8.0,
  }) => Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        if (screenWidth < 600) {
          // En pantallas pequeñas, mostrar como lista
          return Column(
            children: rows.map((row) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: row.asMap().entries.map((entry) {
                    final index = entry.key;
                    final cell = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '${headers[index].toString()}: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(child: cell),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          );
        } else {
          // En pantallas grandes, mostrar como tabla
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: headers.map((header) => DataColumn(label: header)).toList(),
              rows: rows.map((row) => DataRow(cells: row.map((cell) => DataCell(cell)).toList())).toList(),
            ),
          );
        }
      },
    );
}



