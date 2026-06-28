import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ascend/data/models/goal.dart';

class AddGoalSheet extends StatefulWidget {
  final Function(Goal) onSave;
  final Goal? goalToEdit;

  const AddGoalSheet({
    super.key,
    required this.onSave,
    this.goalToEdit,
  });

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customDurationController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String? _selectedDuration;
  bool _isCustomDuration = false;

  final List<String> _durations = [
    '1 semaine',
    '2 semaines',
    '1 mois',
    '2 mois',
    '3 mois',
    '6 mois',
    '1 an',
    'Personnalisé',
  ];

  bool get _isEditing => widget.goalToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final goal = widget.goalToEdit!;
      _nameController.text = goal.name;
      _descriptionController.text = goal.description ?? '';
      _startDate = goal.startDate;
      _endDate = goal.endDate;
      _selectedDuration = goal.duration;
      _isCustomDuration = _selectedDuration == 'Personnalisé';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final duration = _isCustomDuration
        ? _customDurationController.text.trim()
        : _selectedDuration;

    final goal = Goal(
      id: _isEditing ? widget.goalToEdit!.id : null,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      duration: duration,
      startDate: _startDate,
      endDate: _endDate,
      status: _isEditing ? widget.goalToEdit!.status : GoalStatus.active,
      subGoals: _isEditing ? widget.goalToEdit!.subGoals : [],
      createdAt: _isEditing ? widget.goalToEdit!.createdAt : DateTime.now(),
    );

    widget.onSave(goal);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Text(
                    _isEditing ? 'Modifier l\'objectif' : 'Nouvel objectif',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nom',
                          prefixIcon: const Icon(Icons.flag_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer un nom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (optionnel)',
                          prefixIcon: Icon(Icons.description_outlined),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDuration,
                        decoration: const InputDecoration(
                          labelText: 'Durée',
                          prefixIcon: Icon(Icons.timer_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _durations.map((d) {
                          return DropdownMenuItem(value: d, child: Text(d));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDuration = value;
                            _isCustomDuration = value == 'Personnalisé';
                          });
                        },
                      ),
                      if (_isCustomDuration) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customDurationController,
                          decoration: const InputDecoration(
                            labelText: 'Durée personnalisée',
                            prefixIcon: Icon(Icons.edit_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Date de début'),
                        subtitle: Text(dateFormat.format(_startDate)),
                        onTap: () => _pickDate(isStart: true),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('Date de fin (optionnel)'),
                        subtitle: Text(
                          _endDate != null ? dateFormat.format(_endDate!) : 'Non définie',
                        ),
                        trailing: _endDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _endDate = null),
                              )
                            : null,
                        onTap: () => _pickDate(isStart: false),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
