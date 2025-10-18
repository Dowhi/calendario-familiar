import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calendario_familiar/core/models/shift_template.dart';
import 'package:calendario_familiar/core/services/firestore_service.dart';
// Eliminado: import auth_controller (ya no se utiliza)

class ShiftConfigurationScreen extends ConsumerStatefulWidget {
  final ShiftTemplate? shiftTemplate; // null para crear nuevo, no null para editar

  const ShiftConfigurationScreen({
    super.key,
    this.shiftTemplate,
  });

  @override
  ConsumerState<ShiftConfigurationScreen> createState() => _ShiftConfigurationScreenState();
}

class _ShiftConfigurationScreenState extends ConsumerState<ShiftConfigurationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Controladores de texto
  late TextEditingController _nameController;
  late TextEditingController _abbreviationController;
  
  // Variables de estado
  String _selectedBackgroundColor = '#B71C1C';
  String _selectedTextColor = '#FFFFFF';
  double _textSize = 12.0;

  // Variables para horarios
  String _startTime = '12:00';
  String _endTime = '14:00';
  bool _isSplitShift = true;
  String _secondStartTime = '15:00';
  String _secondEndTime = '15:00';
  int _breakTimeMinutes = 25;
  bool _calculateDuration = true;
  int _calculatedHours = 1;
  int _calculatedMinutes = 35;
  
  // Variables para alarmas
  bool _alarm1Enabled = true;
  bool _previousDayAlarm = false;
  String _alarmTime = '08:00';
  
  // Lista de colores predefinidos
  final List<String> _backgroundColors = [
    '#FFC0CB', // Pink
    '#FF69B4', // Hot pink
    '#B71C1C', // Dark red
    '#8D6E63', // Brown
    '#D4AF37', // Gold
    '#FF5722', // Deep orange
    '#FF9800', // Orange
    '#FFEB3B', // Yellow
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#9C27B0', // Purple
    '#795548', // Brown
  ];
  
  final List<String> _textColors = [
    '#9E9E9E', // Grey
    '#FFFFFF', // White
    '#FFCDD2', // Light pink
    '#FFF9C4', // Light yellow
    '#C8E6C9', // Light green
    '#BBDEFB', // Light blue
    '#E1BEE7', // Light purple
    '#000000', // Black
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Inicializar controladores con datos del turno o valores por defecto
    _nameController = TextEditingController(
      text: widget.shiftTemplate?.name ?? 'Nuevo',
    );
    _abbreviationController = TextEditingController(
      text: _getInitialAbbreviation(),
    );
    
    // Agregar listener para actualizar el preview cuando cambie la abreviatura
    _abbreviationController.addListener(() {
      setState(() {}); // Forzar actualización del preview
    });
    
          // Cargar datos del turno existente
          if (widget.shiftTemplate != null) {
            _selectedBackgroundColor = widget.shiftTemplate!.colorHex;
            _selectedTextColor = widget.shiftTemplate!.textColorHex;
            _textSize = widget.shiftTemplate!.textSize;
            
            // Cargar horarios
            _startTime = widget.shiftTemplate!.startTime;
            _endTime = widget.shiftTemplate!.endTime;
            _isSplitShift = widget.shiftTemplate!.isSplitShift;
            _secondStartTime = widget.shiftTemplate!.secondStartTime ?? '15:00';
            _secondEndTime = widget.shiftTemplate!.secondEndTime ?? '15:00';
            _breakTimeMinutes = widget.shiftTemplate!.breakTimeMinutes;
            _calculateDuration = widget.shiftTemplate!.calculateDuration;
            _calculatedHours = widget.shiftTemplate!.calculatedHours ?? 1;
            _calculatedMinutes = widget.shiftTemplate!.calculatedMinutes ?? 35;
            _alarm1Enabled = widget.shiftTemplate!.alarm1Enabled;
            _previousDayAlarm = widget.shiftTemplate!.previousDayAlarm;
            _alarmTime = widget.shiftTemplate!.alarmTime ?? '08:00';
          }
  }

  String _getInitialAbbreviation() {
    if (widget.shiftTemplate != null) {
      // Si estamos editando, usar la abreviatura existente o generar una nueva
      if (widget.shiftTemplate!.abbreviation.isNotEmpty) {
        return widget.shiftTemplate!.abbreviation;
      } else {
        // Si no hay abreviatura, generar una basada en el nombre
        return _getAbbreviationFromName(widget.shiftTemplate!.name);
      }
    }
    return 'F.A.';
  }

  String _getAbbreviationFromName(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('d1') || nameLower.contains('día 1')) return 'D1';
    if (nameLower.contains('d2') || nameLower.contains('día 2')) return 'D2';
    if (nameLower.contains('libre')) return 'L';
    if (nameLower.contains('feria')) return 'Feria';
    if (nameLower.contains('santa')) return 'S.Santa';
    if (nameLower.contains('descanso')) return 'Descanso';
    if (nameLower.contains('tarde')) return 'T';
    if (nameLower.contains('nuevo')) return 'F.A.';
    
    // Abreviación por defecto (primeras letras)
    return name.length > 8 
        ? name.substring(0, 8).toUpperCase()
        : name.toUpperCase();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _abbreviationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_downward, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'CONFIGURACIÓN DE TURNOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sección del nombre del turno
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nombre del turno',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(int.parse(_selectedBackgroundColor.substring(1, 7), radix: 16) + 0xFF000000),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Stack(
                          children: [
                            Text(
                              _abbreviationController.text,
                              style: TextStyle(
                                color: Color(int.parse(_selectedTextColor.substring(1, 7), radix: 16) + 0xFF000000),
                                fontSize: _textSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Pestañas
          Container(
            color: Colors.grey[900],
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.teal,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[400],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: 'ASPECTO'),
                Tab(text: 'HORARIOS'),
                Tab(text: 'ACCIONES'),
              ],
            ),
          ),
          
          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAspectoTab(),
                _buildHorariosTab(),
                _buildAccionesTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAspectoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Abreviatura
          const Text(
            'ABREVIATURA',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _abbreviationController,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Color de fondo
          const Text(
            'COLOR DE FONDO',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildBackgroundColorPicker(_backgroundColors, _selectedBackgroundColor, (color) {
            setState(() {
              _selectedBackgroundColor = color;
            });
          }),
          
          const SizedBox(height: 24),
          
          // Color de texto
          const Text(
            'COLOR DE TEXTO',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextColorPicker(_textColors, _selectedTextColor, (color) {
            setState(() {
              _selectedTextColor = color;
            });
          }),
          
          const SizedBox(height: 24),
          
          // Tamaño del texto
          const Text(
            'TAMAÑO DEL TEXTO',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  _textSize.round().toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _textSize,
                    min: 8.0,
                    max: 24.0,
                    divisions: 16,
                    activeColor: Colors.teal,
                    inactiveColor: Colors.grey[300],
                    onChanged: (value) {
                      setState(() {
                        _textSize = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorariosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título HORARIOS
          const Text(
            'HORARIOS',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Configuración de horarios del turno
          _buildShiftTimeConfiguration(),
          const SizedBox(height: 24),

          // Tiempo de descanso y duración
          _buildBreakTimeAndDuration(),
          const SizedBox(height: 24),

          // Alarmas del turno
          _buildShiftAlarms(),
        ],
      ),
    );
  }

  Widget _buildShiftTimeConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horarios principales
        Row(
          children: [
            Expanded(
              child: _buildTimeInput('Inicio', _startTime, (value) {
                setState(() {
                  _startTime = value;
                });
                _calculateDurationFromTimes();
              }),
            ),
            const SizedBox(width: 8),
            const Text(
              '-',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimeInput('Final', _endTime, (value) {
                setState(() {
                  _endTime = value;
                });
                _calculateDurationFromTimes();
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Checkbox Turno partido
        Row(
          children: [
            Checkbox(
              value: _isSplitShift,
              onChanged: (value) {
                setState(() {
                  _isSplitShift = value ?? false;
                });
                _calculateDurationFromTimes();
              },
              activeColor: Colors.teal,
            ),
            const Text(
              'Turno partido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),

        // Horarios del segundo turno (si está habilitado)
        if (_isSplitShift) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeInput('Inicio', _secondStartTime, (value) {
                  setState(() {
                    _secondStartTime = value;
                  });
                  _calculateDurationFromTimes();
                }),
              ),
              const SizedBox(width: 8),
              const Text(
                '-',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeInput('Final', _secondEndTime, (value) {
                  setState(() {
                    _secondEndTime = value;
                  });
                  _calculateDurationFromTimes();
                }),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBreakTimeAndDuration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiempo de descanso
        Row(
          children: [
            GestureDetector(
              onTap: () => _showBreakTimeDialog(),
              child: Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: Center(
                  child: Text(
                    _breakTimeMinutes.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tiempo de descanso (minutos)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Calcular duración
        Row(
          children: [
            Checkbox(
              value: _calculateDuration,
              onChanged: (value) {
                setState(() {
                  _calculateDuration = value ?? false;
                });
              },
              activeColor: Colors.teal,
            ),
            const Text(
              'Calcular duración',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (_calculateDuration) ...[
              GestureDetector(
                onTap: () => _showDurationDialog(true),
                child: Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: Center(
                    child: Text(
                      '${_calculatedHours} h',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showDurationDialog(false),
                child: Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: Center(
                    child: Text(
                      '${_calculatedMinutes} m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildShiftAlarms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ALARMAS DEL TURNO',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // Alarma 1
        Row(
          children: [
            Checkbox(
              value: _alarm1Enabled,
              onChanged: (value) {
                setState(() {
                  _alarm1Enabled = value ?? false;
                });
              },
              activeColor: Colors.teal,
            ),
            const Text(
              'Alarma 1',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),

        if (_alarm1Enabled) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 40), // Espacio para alineación
              Checkbox(
                value: _previousDayAlarm,
                onChanged: (value) {
                  setState(() {
                    _previousDayAlarm = value ?? false;
                  });
                },
                activeColor: Colors.teal,
              ),
              const Text(
                'Del día anterior',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 16),
              _buildTimeInput('', _alarmTime, (value) {
                setState(() {
                  _alarmTime = value;
                });
              }),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 40), // Espacio para alineación
              const Text(
                'Sonido por defecto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.music_note,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTimeInput(String label, String value, Function(String) onChanged) {
    return GestureDetector(
      onTap: () => _showTimePickerDialog(label, value, onChanged),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[600]!),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              if (label.isNotEmpty) ...[
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(
                Icons.access_time,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccionesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Pestaña de Acciones',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Funcionalidad en desarrollo',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundColorPicker(List<String> colors, String selectedColor, Function(String) onColorSelected) {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length + 2, // +2 para los iconos de color picker y navegación
        itemBuilder: (context, index) {
          if (index == 0) {
            // Icono de color picker - abre popup RGB
            return GestureDetector(
              onTap: () => _showColorPickerDialog(onColorSelected),
              child: Container(
                width: 48,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.palette,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            );
          }
          
          if (index == colors.length + 1) {
            // Icono de navegación derecha
            return GestureDetector(
              onTap: () => _scrollColorPicker(0), // Scroll para colores de fondo
              child: Container(
                width: 48,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            );
          }
          
          final color = colors[index - 1];
          final isSelected = color == selectedColor;
          
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000),
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? Border.all(color: Colors.green, width: 2) : null,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 20,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextColorPicker(List<String> colors, String selectedColor, Function(String) onColorSelected) {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length + 2, // +2 para los iconos de color picker y navegación
        itemBuilder: (context, index) {
          if (index == 0) {
            // Icono de color picker - abre popup RGB para texto
            return GestureDetector(
              onTap: () => _showTextColorPickerDialog(onColorSelected),
              child: Container(
                width: 48,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.palette,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            );
          }
          
          if (index == colors.length + 1) {
            // Icono de navegación derecha
            return GestureDetector(
              onTap: () => _scrollColorPicker(1), // Scroll para colores de texto
              child: Container(
                width: 48,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            );
          }
          
          final color = colors[index - 1];
          final isSelected = color == selectedColor;
          
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey[800], // Fondo gris para mostrar el color del texto
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? Border.all(color: Colors.green, width: 2) : null,
              ),
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000),
                    shape: BoxShape.circle,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Icono de eliminar
          IconButton(
            onPressed: widget.shiftTemplate != null ? _confirmDelete : null,
            icon: Icon(
              Icons.delete,
              color: widget.shiftTemplate != null ? Colors.red : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          
          // Botón Cancelar
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Botón Guardar
          Expanded(
            child: ElevatedButton(
              onPressed: _saveShift,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'GUARDAR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveShift() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un nombre para el turno'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_abbreviationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa una abreviatura para el turno'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      // Eliminado: obtención de familyId desde authController (ya no se utiliza)
      final familyId = 'default_family'; // FamilyId fijo sin autenticación

      if (widget.shiftTemplate != null) {
        // Actualizar turno existente
        await firestoreService.updateShiftTemplate(
          id: widget.shiftTemplate!.id,
          name: _nameController.text.trim(),
          abbreviation: _abbreviationController.text.trim(),
          colorHex: _selectedBackgroundColor,
          textColorHex: _selectedTextColor,
          textSize: _textSize,
          startTime: _startTime,
          endTime: _endTime,
          description: widget.shiftTemplate!.description,
          isSplitShift: _isSplitShift,
          secondStartTime: _isSplitShift ? _secondStartTime : null,
          secondEndTime: _isSplitShift ? _secondEndTime : null,
          breakTimeMinutes: _breakTimeMinutes,
          calculateDuration: _calculateDuration,
          calculatedHours: _calculateDuration ? _calculatedHours : null,
          calculatedMinutes: _calculateDuration ? _calculatedMinutes : null,
          alarm1Enabled: _alarm1Enabled,
          previousDayAlarm: _previousDayAlarm,
          alarmTime: _alarm1Enabled ? _alarmTime : null,
        );
      } else {
        // Crear nuevo turno
        await firestoreService.addShiftTemplate(
          name: _nameController.text.trim(),
          abbreviation: _abbreviationController.text.trim(),
          colorHex: _selectedBackgroundColor,
          startTime: _startTime,
          endTime: _endTime,
          description: 'Turno creado desde la app',
          familyId: familyId,
          textColorHex: _selectedTextColor,
          textSize: _textSize,
          isSplitShift: _isSplitShift,
          secondStartTime: _isSplitShift ? _secondStartTime : null,
          secondEndTime: _isSplitShift ? _secondEndTime : null,
          breakTimeMinutes: _breakTimeMinutes,
          calculateDuration: _calculateDuration,
          calculatedHours: _calculateDuration ? _calculatedHours : null,
          calculatedMinutes: _calculateDuration ? _calculatedMinutes : null,
          alarm1Enabled: _alarm1Enabled,
          previousDayAlarm: _previousDayAlarm,
          alarmTime: _alarm1Enabled ? _alarmTime : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.shiftTemplate != null 
                  ? 'Turno "${_nameController.text}" actualizado en Firebase' 
                  : 'Turno "${_nameController.text}" creado en Firebase',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Cerrar pantalla después de guardar
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.pop();
          }
        });
      }
    } catch (e) {
      print('❌ Error guardando turno en Firebase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando turno en Firebase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete() {
    if (widget.shiftTemplate == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text(
          'Eliminar Turno',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué quieres eliminar del turno "${_nameController.text}"?',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            const Text(
              '• Solo la plantilla: Elimina únicamente la plantilla del turno',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Plantilla y turnos asignados: Elimina la plantilla y todos los turnos ya asignados en el calendario',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteShift(deleteAssignedShifts: false);
            },
            child: const Text('Solo plantilla', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteShift(deleteAssignedShifts: true);
            },
            child: const Text('Plantilla y turnos', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShift({required bool deleteAssignedShifts}) async {
    if (widget.shiftTemplate == null) return;

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      if (deleteAssignedShifts) {
        // Eliminar plantilla y limpiar turnos asignados
        await firestoreService.deleteShiftTemplate(widget.shiftTemplate!.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Turno "${_nameController.text}" y todos los turnos asignados eliminados'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Eliminar solo la plantilla (sin limpiar turnos asignados)
        await firestoreService.deleteShiftTemplateOnly(widget.shiftTemplate!.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plantilla "${_nameController.text}" eliminada (turnos asignados conservados)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.pop();
        }
      });
    } catch (e) {
      print('❌ Error eliminando turno de Firebase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error eliminando turno de Firebase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTextColorPickerDialog(Function(String) onColorSelected) {
    // Convertir color hexadecimal actual a RGB
    Color currentColor = Color(int.parse(_selectedTextColor.substring(1, 7), radix: 16) + 0xFF000000);

    // Variables para los sliders RGB
    double red = currentColor.red.toDouble();
    double green = currentColor.green.toDouble();
    double blue = currentColor.blue.toDouble();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header rojo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFB71C1C),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'SELECCIONE COLOR DE TEXTO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Contenido del diálogo
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Preview del color seleccionado
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[800], // Fondo gris para mostrar el color del texto
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _abbreviationController.text,
                          style: TextStyle(
                            color: Color.fromRGBO(red.round(), green.round(), blue.round(), 1.0),
                            fontSize: _textSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Slider Rojo
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: red,
                            min: 0,
                            max: 255,
                            divisions: 255,
                            activeColor: Colors.teal,
                            inactiveColor: Colors.grey[300],
                            onChanged: (value) {
                              setDialogState(() {
                                red = value;
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 40,
                          child: Text(
                            red.round().toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Slider Verde
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: green,
                            min: 0,
                            max: 255,
                            divisions: 255,
                            activeColor: Colors.teal,
                            inactiveColor: Colors.grey[300],
                            onChanged: (value) {
                              setDialogState(() {
                                green = value;
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 40,
                          child: Text(
                            green.round().toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Slider Azul
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: blue,
                            min: 0,
                            max: 255,
                            divisions: 255,
                            activeColor: Colors.teal,
                            inactiveColor: Colors.grey[300],
                            onChanged: (value) {
                              setDialogState(() {
                                blue = value;
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 40,
                          child: Text(
                            blue.round().toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'CANCELAR',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Convertir RGB a hexadecimal
                              String hexColor = '#${red.round().toRadixString(16).padLeft(2, '0')}${green.round().toRadixString(16).padLeft(2, '0')}${blue.round().toRadixString(16).padLeft(2, '0')}';
                              onColorSelected(hexColor.toUpperCase());
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'ACEPTAR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollColorPicker(int pickerType) {
    // TODO: Implementar scroll horizontal para mostrar más colores
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navegación de colores en desarrollo'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Calcular duración automáticamente basada en los horarios
  void _calculateDurationFromTimes() {
    if (!_calculateDuration) return;
    
    try {
      // Calcular duración del primer turno
      final firstDuration = _calculateTimeDifference(_startTime, _endTime);
      
      int totalMinutes = firstDuration;
      
      // Si es turno partido, agregar duración del segundo turno
      if (_isSplitShift) {
        final secondDuration = _calculateTimeDifference(_secondStartTime, _secondEndTime);
        totalMinutes += secondDuration;
        
        // Restar tiempo de descanso
        totalMinutes -= _breakTimeMinutes;
      }
      
      // Convertir a horas y minutos
      _calculatedHours = totalMinutes ~/ 60;
      _calculatedMinutes = totalMinutes % 60;
      
      // Asegurar que no sea negativo
      if (_calculatedHours < 0) _calculatedHours = 0;
      if (_calculatedMinutes < 0) _calculatedMinutes = 0;
      
      setState(() {});
    } catch (e) {
      print('Error calculando duración: $e');
    }
  }

  // Calcular diferencia entre dos tiempos en minutos
  int _calculateTimeDifference(String startTime, String endTime) {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    
    if (startParts.length != 2 || endParts.length != 2) {
      return 0;
    }
    
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);
    
    // Convertir a minutos desde medianoche
    final startTotalMinutes = startHour * 60 + startMinute;
    final endTotalMinutes = endHour * 60 + endMinute;
    
    // Manejar turnos de 24 horas (24:00 = 1440 minutos)
    if (endTime == '24:00') {
      return (24 * 60) - startTotalMinutes;
    }
    
    // Calcular diferencia
    int difference = endTotalMinutes - startTotalMinutes;
    
    // Si el turno cruza la medianoche (endTime < startTime)
    if (difference < 0) {
      difference += 24 * 60; // Agregar 24 horas en minutos
    }
    
    // Manejar caso especial: 00:00 a 23:59 = 23h 59m (casi 24h)
    if (startTime == '00:00' && endTime == '23:59') {
      return 23 * 60 + 59; // 23 horas y 59 minutos
    }
    
    return difference;
  }

  void _showBreakTimeDialog() {
    final TextEditingController customController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text(
          'Tiempo de Descanso',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecciona los minutos de descanso:',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            // Opciones predefinidas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeButton(0),
                _buildTimeButton(15),
                _buildTimeButton(25),
                _buildTimeButton(30),
                _buildTimeButton(45),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeButton(60),
                _buildTimeButton(90),
                _buildTimeButton(120),
                _buildTimeButton(180),
                _buildTimeButton(240),
              ],
            ),
            const SizedBox(height: 16),
            // Campo personalizable
            Row(
              children: [
                const Text(
                  'Personalizado:',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[600]!),
                    ),
                    child: TextFormField(
                      controller: customController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Minutos',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final customValue = int.tryParse(customController.text);
                    if (customValue != null && customValue >= 0) {
                      setState(() {
                        _breakTimeMinutes = customValue;
                      });
                      _calculateDurationFromTimes();
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor ingresa un número válido'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(60, 40),
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton(int minutes) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _breakTimeMinutes = minutes;
        });
        _calculateDurationFromTimes();
        Navigator.pop(context);
      },
      child: Container(
        width: 50,
        height: 40,
        decoration: BoxDecoration(
          color: _breakTimeMinutes == minutes ? Colors.teal : Colors.grey[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            minutes.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showDurationDialog(bool isHours) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: Text(
          isHours ? 'Horas' : 'Minutos',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isHours ? 'Selecciona las horas:' : 'Selecciona los minutos:',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                isHours ? 12 : 60,
                (index) => _buildDurationButton(index, isHours),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationButton(int value, bool isHours) {
    final currentValue = isHours ? _calculatedHours : _calculatedMinutes;
    final isSelected = currentValue == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isHours) {
            _calculatedHours = value;
          } else {
            _calculatedMinutes = value;
          }
        });
        Navigator.pop(context);
      },
      child: Container(
        width: 40,
        height: 35,
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey[700],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showTimePickerDialog(String label, String currentTime, Function(String) onChanged) {
    // Parsear el tiempo actual
    final timeParts = currentTime.split(':');
    int currentHour = int.tryParse(timeParts[0]) ?? 8;
    int currentMinute = int.tryParse(timeParts[1]) ?? 0;
    bool isAM = currentHour < 12;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Text(
                  'Select time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Display digital del tiempo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hora
                    GestureDetector(
                      onTap: () => _showHourPicker(setDialogState, currentHour, (hour) {
                        setDialogState(() {
                          currentHour = hour;
                        });
                      }),
                      child: Container(
                        width: 60,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[300]!, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            currentHour == 24 ? '24' : (currentHour > 12 ? currentHour - 12 : currentHour == 0 ? 12 : currentHour).toString(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    Text(
                      ':',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Minutos
                    GestureDetector(
                      onTap: () => _showMinutePicker(setDialogState, currentMinute, (minute) {
                        setDialogState(() {
                          currentMinute = minute;
                        });
                      }),
                      child: Container(
                        width: 60,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            currentMinute.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // AM/PM
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              isAM = true;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isAM ? Colors.pink[300] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                'AM',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isAM ? Colors.white : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              isAM = false;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 30,
                            decoration: BoxDecoration(
                              color: !isAM ? Colors.pink[300] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                'PM',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: !isAM ? Colors.white : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Convertir a formato 24h
                        int hour24 = currentHour;
                        if (!isAM && currentHour != 12) {
                          hour24 = currentHour + 12;
                        } else if (isAM && currentHour == 12) {
                          hour24 = 0;
                        }
                        
                        // Manejar turnos de 24 horas (24:00)
                        String timeString;
                        if (hour24 == 24) {
                          timeString = '24:00';
                        } else {
                          timeString = '${hour24.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}';
                        }
                        
                        onChanged(timeString);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHourPicker(StateSetter setDialogState, int currentHour, Function(int) onChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text('Seleccionar Hora', style: TextStyle(color: Colors.white)),
        content: Container(
          width: 280,
          height: 400,
          child: Column(
            children: [
              // Botones especiales para 00:00 y 24:00
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSpecialHourButton('00:00', 0, currentHour, onChanged),
                    _buildSpecialHourButton('24:00', 24, currentHour, onChanged),
                  ],
                ),
              ),
              
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 8),
              
              // Horas normales en grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final hour = index + 1; // 1-12
                    final isSelected = (currentHour > 12 ? currentHour - 12 : currentHour == 0 ? 12 : currentHour) == hour;
                    
                    return GestureDetector(
                      onTap: () {
                        onChanged(hour);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.teal : Colors.grey[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            hour.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialHourButton(String label, int hour, int currentHour, Function(int) onChanged) {
    final isSelected = currentHour == hour;
    
    return GestureDetector(
      onTap: () {
        onChanged(hour);
        Navigator.pop(context);
      },
      child: Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.blue[700],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange[300]! : Colors.blue[400]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                hour == 0 ? 'Medianoche' : '24 horas',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMinutePicker(StateSetter setDialogState, int currentMinute, Function(int) onChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text('Seleccionar Minutos', style: TextStyle(color: Colors.white)),
        content: Container(
          width: 280,
          height: 400,
          child: Column(
            children: [
              // Botones especiales para minutos comunes
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildSpecialMinuteButton('00', 0, currentMinute, onChanged),
                    _buildSpecialMinuteButton('15', 15, currentMinute, onChanged),
                    _buildSpecialMinuteButton('30', 30, currentMinute, onChanged),
                    _buildSpecialMinuteButton('45', 45, currentMinute, onChanged),
                  ],
                ),
              ),
              
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 8),
              
              // Minutos en grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 60,
                  itemBuilder: (context, index) {
                    final minute = index;
                    final isSelected = currentMinute == minute;
                    final isSpecialMinute = [0, 15, 30, 45].contains(minute);
                    
                    return GestureDetector(
                      onTap: () {
                        onChanged(minute);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.teal 
                              : isSpecialMinute 
                                  ? Colors.grey[600] 
                                  : Colors.grey[700],
                          borderRadius: BorderRadius.circular(6),
                          border: isSpecialMinute 
                              ? Border.all(color: Colors.grey[500]!, width: 1)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            minute.toString().padLeft(2, '0'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSpecialMinute ? 14 : 12,
                              fontWeight: isSpecialMinute 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialMinuteButton(String label, int minute, int currentMinute, Function(int) onChanged) {
    final isSelected = currentMinute == minute;
    
    return GestureDetector(
      onTap: () {
        onChanged(minute);
        Navigator.pop(context);
      },
      child: Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.blue[700],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green[300]! : Colors.blue[400]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPickerDialog(Function(String) onColorSelected) {
    // Convertir color hexadecimal actual a RGB
    Color currentColor = Color(int.parse(_selectedBackgroundColor.substring(1, 7), radix: 16) + 0xFF000000);
    
    // Variables para los sliders RGB
    double red = currentColor.red.toDouble();
    double green = currentColor.green.toDouble();
    double blue = currentColor.blue.toDouble();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header rojo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFB71C1C),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'SELECCIONE UN COLOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Contenido del diálogo
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Preview del color seleccionado
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(red.round(), green.round(), blue.round(), 1.0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _abbreviationController.text,
                          style: TextStyle(
                            color: Color(int.parse(_selectedTextColor.substring(1, 7), radix: 16) + 0xFF000000),
                            fontSize: _textSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Slider Rojo
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: red,
                            min: 0,
                            max: 255,
                            divisions: 255,
                            activeColor: Colors.teal,
                            inactiveColor: Colors.grey[300],
                            onChanged: (value) {
                              setDialogState(() {
                                red = value;
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 40,
                          child: Text(
                            red.round().toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Slider Verde
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: green,
                            min: 0,
                            max: 255,
                            divisions: 255,
                            activeColor: Colors.teal,
                            inactiveColor: Colors.grey[300],
                            onChanged: (value) {
                              setDialogState(() {
                                green = value;
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 40,
                          child: Text(
                            green.round().toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Slider Azul
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: blue,
                            min: 0,
                            max: 255,
                            divisions: 255,
                            activeColor: Colors.teal,
                            inactiveColor: Colors.grey[300],
                            onChanged: (value) {
                              setDialogState(() {
                                blue = value;
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 40,
                          child: Text(
                            blue.round().toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'CANCELAR',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Convertir RGB a hexadecimal
                              String hexColor = '#${red.round().toRadixString(16).padLeft(2, '0')}${green.round().toRadixString(16).padLeft(2, '0')}${blue.round().toRadixString(16).padLeft(2, '0')}';
                              onColorSelected(hexColor.toUpperCase());
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'ACEPTAR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
