import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calendario_familiar/core/models/shift_template.dart';

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
    
    // Cargar colores del turno existente
    if (widget.shiftTemplate != null) {
      _selectedBackgroundColor = widget.shiftTemplate!.colorHex;
      // Por defecto, texto blanco para contraste
      _selectedTextColor = '#FFFFFF';
    }
  }

  String _getInitialAbbreviation() {
    if (widget.shiftTemplate != null) {
      return _getAbbreviationFromName(widget.shiftTemplate!.name);
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
                            if (widget.shiftTemplate == null)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '1',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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
          _buildColorPicker(_backgroundColors, _selectedBackgroundColor, (color) {
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
          _buildColorPicker(_textColors, _selectedTextColor, (color) {
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Pestaña de Horarios',
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

  Widget _buildColorPicker(List<String> colors, String selectedColor, Function(String) onColorSelected) {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length + 2, // +2 para los iconos de color picker y navegación
        itemBuilder: (context, index) {
          if (index == 0) {
            // Icono de color picker
            return Container(
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
            );
          }
          
          if (index == colors.length + 1) {
            // Icono de navegación derecha
            return Container(
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

  void _saveShift() {
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

    // TODO: Implementar guardado real cuando esté disponible el backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.shiftTemplate != null 
              ? 'Turno "${_nameController.text}" actualizado' 
              : 'Turno "${_nameController.text}" creado',
        ),
        backgroundColor: Colors.green,
      ),
    );

    // Simular guardado
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.pop();
      }
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text(
          'Eliminar Turno',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar el turno "${_nameController.text}"?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteShift();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteShift() {
    // TODO: Implementar eliminación real cuando esté disponible el backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Turno "${_nameController.text}" eliminado'),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.pop();
      }
    });
  }
}
