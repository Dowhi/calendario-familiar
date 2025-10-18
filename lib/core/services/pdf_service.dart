import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<String> generateReportPdf({
    required String reportType,
    required Map<String, dynamic> reportData,
    required String period,
  }) async {
    final pdf = pw.Document();

    // Crear la página del reporte
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          _buildHeader(reportType, period),
          _buildReportContent(reportType, reportData),
        ],
      ),
    );

    // Guardar el PDF en el directorio de documentos
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'reporte_${reportType.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  static Future<void> showPdfPreview({
    required String reportType,
    required Map<String, dynamic> reportData,
    required String period,
  }) async {
    final pdf = pw.Document();

    // Crear la página del reporte
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          _buildHeader(reportType, period),
          _buildReportContent(reportType, reportData),
        ],
      ),
    );

    // Mostrar vista previa del PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_${reportType.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static pw.Widget _buildHeader(String reportType, String period) => pw.Header(
      level: 0,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Reporte Avanzado',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
                     pw.Text(
             reportType,
             style: pw.TextStyle(
               fontSize: 18,
               fontWeight: pw.FontWeight.bold,
             ),
           ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Período: $period',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey,
            ),
          ),
          pw.Divider(),
        ],
      ),
    );

  static pw.Widget _buildReportContent(String reportType, Map<String, dynamic> reportData) {
    final reportTypeKey = reportData['type'] as String?;
    
    switch (reportTypeKey) {
      case 'shifts':
        return _buildShiftsReportContent(reportData);
      case 'hours':
        return _buildHoursReportContent(reportData);
      case 'categories':
        return _buildCategoriesReportContent(reportData);
      case 'notes':
        return _buildNotesReportContent(reportData);
      case 'productivity':
        return _buildProductivityReportContent(reportData);
             case 'absences':
         return _buildAbsencesReportContent(reportData);
       case 'monthly_summary':
         return _buildMonthlySummaryReportContent(reportData);
       default:
         return pw.Text('Tipo de reporte no soportado');
    }
  }

  static pw.Widget _buildShiftsReportContent(Map<String, dynamic> reportData) {
    final data = reportData['data'] as Map<String, int>;
    final total = reportData['total'] as int;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumen de Turnos',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
                 pw.Text(
           'Total: $total turnos',
           style: pw.TextStyle(
             fontSize: 14,
             fontWeight: pw.FontWeight.bold,
           ),
         ),
        pw.SizedBox(height: 16),
        _buildDataTable(
          headers: ['Turno', 'Cantidad', 'Porcentaje'],
          data: data.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100).round() : 0;
            return [entry.key, entry.value.toString(), '$percentage%'];
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildHoursReportContent(Map<String, dynamic> reportData) {
    final data = reportData['data'] as Map<String, int>;
    final total = reportData['total'] as int;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Horas por Turno',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
                 pw.Text(
           'Total: ${total}h',
           style: pw.TextStyle(
             fontSize: 14,
             fontWeight: pw.FontWeight.bold,
           ),
         ),
        pw.SizedBox(height: 16),
        _buildDataTable(
          headers: ['Turno', 'Horas', 'Porcentaje'],
          data: data.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100).round() : 0;
            return [entry.key, '${entry.value}h', '$percentage%'];
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildCategoriesReportContent(Map<String, dynamic> reportData) {
    final data = reportData['data'] as Map<String, int>;
    final totalDays = reportData['totalDays'] as int;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Categorías por Día',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
                 pw.Text(
           'Total días: $totalDays',
           style: pw.TextStyle(
             fontSize: 14,
             fontWeight: pw.FontWeight.bold,
           ),
         ),
        pw.SizedBox(height: 16),
        _buildDataTable(
          headers: ['Categoría', 'Cantidad', 'Porcentaje'],
          data: data.entries.map((entry) {
            final percentage = totalDays > 0 ? (entry.value / totalDays * 100).round() : 0;
            return [entry.key, entry.value.toString(), '$percentage%'];
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildNotesReportContent(Map<String, dynamic> reportData) {
    final data = reportData['data'] as Map<String, int>;
    final total = reportData['total'] as int;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notas por Día',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
                 pw.Text(
           'Total: $total notas',
           style: pw.TextStyle(
             fontSize: 14,
             fontWeight: pw.FontWeight.bold,
           ),
         ),
        pw.SizedBox(height: 16),
        _buildDataTable(
          headers: ['Fecha', 'Notas'],
          data: data.entries.take(20).map((entry) => [entry.key, '${entry.value} notas']).toList(),
          includeTotal: true, // Incluir total para mostrar el total de notas mostradas
        ),
        if (data.length > 20)
          pw.Text(
            '... y ${data.length - 20} días más',
            style: pw.TextStyle(
              fontSize: 12,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildProductivityReportContent(Map<String, dynamic> reportData) {
    final daysWithEvents = reportData['daysWithEvents'] as int;
    final totalDays = reportData['totalDays'] as int;
    final productivityPercentage = reportData['productivityPercentage'] as int;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Productividad',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: _getProductivityColor(productivityPercentage),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                '$productivityPercentage%',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Productividad',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildStatCard(
                'Días con Eventos',
                '$daysWithEvents',
                PdfColors.green,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _buildStatCard(
                'Días Totales',
                '$totalDays',
                PdfColors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildAbsencesReportContent(Map<String, dynamic> reportData) {
    final absentDays = reportData['absentDays'] as List<String>;
    final totalAbsentDays = reportData['totalAbsentDays'] as int;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Días sin Eventos',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
                 pw.Text(
           'Total: $totalAbsentDays días',
           style: pw.TextStyle(
             fontSize: 14,
             fontWeight: pw.FontWeight.bold,
           ),
         ),
        pw.SizedBox(height: 16),
        if (absentDays.isNotEmpty) ...[
                     pw.Text(
             'Fechas sin eventos:',
             style: pw.TextStyle(
               fontSize: 14,
               fontWeight: pw.FontWeight.bold,
             ),
           ),
          pw.SizedBox(height: 8),
          ...absentDays.take(20).map((date) => pw.Text('• $date')),
          if (absentDays.length > 20)
            pw.Text(
              '... y ${absentDays.length - 20} días más',
              style: pw.TextStyle(
                fontSize: 12,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
        ] else ...[
          pw.Text(
            '¡Excelente! No hay días sin eventos en este período.',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.green,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildDataTable({
    required List<String> headers,
    required List<List<String>> data,
    bool includeTotal = true,
  }) {
    final List<pw.TableRow> rows = [
      // Encabezados
      pw.TableRow(
        children: headers.map((header) => pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            header,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        )).toList(),
      ),
      // Datos
      ...data.map((row) => pw.TableRow(
        children: row.map((cell) => pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(cell),
        )).toList(),
      )),
    ];

    // Añadir fila de totales si se solicita y hay datos
    if (includeTotal && data.isNotEmpty && headers.length >= 2) {
      final List<String> totalRow = [];
      
      // Primera columna: "TOTAL"
      totalRow.add('TOTAL');
      
      // Calcular totales para las columnas numéricas (excluyendo la primera columna que suele ser texto)
      for (int i = 1; i < headers.length; i++) {
        int total = 0;
        for (final row in data) {
          if (row.length > i) {
            // Extraer números de las celdas (ignorar texto como "h", "%", etc.)
            final cellValue = row[i];
            final numericValue = _extractNumericValue(cellValue);
            total += numericValue;
          }
        }
        
        // Formatear el total según el tipo de columna
        if (headers[i].toLowerCase().contains('porcentaje')) {
          totalRow.add('$total%');
        } else if (headers[i].toLowerCase().contains('hora')) {
          totalRow.add('${total}h');
        } else {
          totalRow.add(total.toString());
        }
      }
      
      // Añadir la fila de totales con estilo destacado
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey.shade(0.1),
          ),
          children: totalRow.map((cell) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              cell,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
              ),
            ),
          )).toList(),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(),
      children: rows,
    );
  }

  static int _extractNumericValue(String value) {
    // Extraer solo los números de una cadena
    final numericString = value.replaceAll(RegExp(r'[^0-9]'), '');
    return numericString.isNotEmpty ? int.tryParse(numericString) ?? 0 : 0;
  }

     static pw.Widget _buildStatCard(String title, String value, PdfColor color) => pw.Container(
       padding: const pw.EdgeInsets.all(12),
       decoration: pw.BoxDecoration(
         color: PdfColors.grey.shade(0.1),
         border: pw.Border.all(color: color),
         borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
       ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

       static pw.Widget _buildMonthlySummaryReportContent(Map<String, dynamic> reportData) {
    final months = reportData['months'] as List<String>;
    final shiftTypes = reportData['shiftTypes'] as List<String>;
    final monthlyData = reportData['monthlyData'] as Map<String, Map<String, int>>;
    final summaryType = reportData['summaryType'] as String? ?? 'Por Turnos';
    
    // Calcular totales por columna
    final Map<String, int> columnTotals = {};
    for (final shiftType in shiftTypes) {
      columnTotals[shiftType] = 0;
      for (final monthData in monthlyData.values) {
        columnTotals[shiftType] = columnTotals[shiftType]! + (monthData[shiftType] ?? 0);
      }
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumen por Meses - $summaryType',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Total meses: ${months.length}',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 16),
        
        // Tabla de resumen mensual
        _buildMonthlyDataTable(months, shiftTypes, monthlyData, columnTotals),
      ],
    );
  }

     static pw.Widget _buildMonthlyDataTable(List<String> months, List<String> shiftTypes, Map<String, Map<String, int>> monthlyData, Map<String, int> columnTotals) => pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Encabezados
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Mes',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            ...shiftTypes.map((shiftType) => pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                shiftType,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            )).toList(),
          ],
        ),
        // Filas de datos
        ...months.map((monthName) {
          // Encontrar el monthKey correspondiente
          String? monthKey;
          for (final entry in monthlyData.entries) {
            try {
              final date = DateTime.parse('${entry.key}-01');
              final formattedMonth = DateFormat('MMMM yyyy', 'es_ES').format(date);
              if (formattedMonth == monthName) {
                monthKey = entry.key;
                break;
              }
            } catch (e) {
              // Ignorar errores de parsing
            }
          }
          
          final monthData = monthKey != null ? monthlyData[monthKey]! : <String, int>{};
          
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(monthName),
              ),
              ...shiftTypes.map((shiftType) => pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(monthData[shiftType]?.toString() ?? '0'),
              )).toList(),
            ],
          );
        }).toList(),
        
        // Fila de totales
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey.shade(0.1),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'TOTAL',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            ...shiftTypes.map((shiftType) => pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                columnTotals[shiftType]?.toString() ?? '0',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            )).toList(),
          ],
        ),
      ],
    );

   static PdfColor _getProductivityColor(int percentage) {
     if (percentage >= 80) return PdfColors.green;
     if (percentage >= 60) return PdfColors.orange;
     return PdfColors.red;
   }
 }
