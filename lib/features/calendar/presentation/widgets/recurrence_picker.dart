import 'package:flutter/material.dart';
import 'package:calendario_familiar/core/models/recurrence.dart';
import 'package:calendario_familiar/core/utils/recurrence_utils.dart';

class RecurrencePicker extends StatefulWidget {

  const RecurrencePicker({
    super.key,
    this.recurrence,
    required this.onRecurrenceChanged,
  });
  final Recurrence? recurrence;
  final Function(Recurrence?) onRecurrenceChanged;

  @override
  State<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends State<RecurrencePicker> {
  String _selectedOption = 'Sin repetición';

  @override
  void initState() {
    super.initState();
    if (widget.recurrence != null) {
      _selectedOption = RecurrenceUtils.getRecurrenceDescription(widget.recurrence!);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedOption,
          decoration: const InputDecoration(
            labelText: 'Frecuencia',
          ),
          items: RecurrenceUtils.getRecurrenceOptions().map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedOption = value;
              });
              
              final rule = RecurrenceUtils.getRecurrenceRule(value);
              widget.onRecurrenceChanged(rule);
            }
          },
        ),
        
        if (_selectedOption != 'Sin repetición') ...[
          const SizedBox(height: 16),
          _buildIntervalSelector(),
        ],
      ],
    );

  Widget _buildIntervalSelector() {
    final currentInterval = widget.recurrence?.interval ?? 1;
    
    return Row(
      children: [
        const Text('Cada '),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: currentInterval,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            items: List.generate(12, (index) => index + 1).map((interval) => DropdownMenuItem(
                value: interval,
                child: Text('$interval'),
              )).toList(),
            onChanged: (value) {
              if (value != null) {
                final rule = RecurrenceUtils.getRecurrenceRule(_selectedOption);
                if (rule != null) {
                  widget.onRecurrenceChanged(rule.copyWith(interval: value));
                }
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(_getIntervalUnit()),
      ],
    );
  }

  String _getIntervalUnit() {
    switch (widget.recurrence?.rule) {
      case 'daily':
        return 'día${widget.recurrence?.interval == 1 ? '' : 's'}';
      case 'weekly':
        return 'semana${widget.recurrence?.interval == 1 ? '' : 's'}';
      case 'monthly':
        return 'mes${widget.recurrence?.interval == 1 ? '' : 'es'}';
      default:
        return '';
    }
  }
}

