import 'package:flutter/material.dart';
import 'package:ascend/core/enums/app_enums.dart';
import 'package:ascend/data/models/habit.dart';

class AddHabitSheet extends StatefulWidget {
  final Function(Habit) onSave;
  final Habit? habitToEdit;

  const AddHabitSheet({
    super.key,
    required this.onSave,
    this.habitToEdit,
  });

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _targetUnitController = TextEditingController();

  HabitType _selectedType = HabitType.Positive;
  HabitCategory _selectedCategory = HabitCategory.Health;
  IconData _selectedIcon = Icons.star;
  Color _selectedColor = HabitColors.colors[0];
  HabitFrequency _selectedFrequency = HabitFrequency.Daily;
  HabitPriority _selectedPriority = HabitPriority.Medium;
  int _durationMinutes = 0;
  int _reminderHour = 8;
  int _reminderMinute = 0;
  bool _hasReminder = false;
  final List<int> _customDays = [];

  @override
  void initState() {
    super.initState();
    if (widget.habitToEdit != null) {
      _loadHabitData(widget.habitToEdit!);
    }
  }

  void _loadHabitData(Habit habit) {
    _nameController.text = habit.name;
    _descriptionController.text = habit.description ?? '';
    _selectedType = habit.type;
    _selectedCategory = habit.category;
    _selectedIcon = habit.icon ?? Icons.star;
    _selectedColor = habit.color ?? HabitColors.colors[0];
    _selectedFrequency = habit.frequency;
    _selectedPriority = habit.priority;
    _durationMinutes = habit.durationMinutes;
    _hasReminder = habit.hasReminder;
    _reminderHour = habit.reminderHour ?? 8;
    _reminderMinute = habit.reminderMinute ?? 0;
    _customDays.addAll(habit.customDays);
    if (habit.targetValue != null) {
      _targetValueController.text = habit.targetValue.toString();
    }
    _targetUnitController.text = habit.targetUnit ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    _targetUnitController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final habit = Habit(
      id: widget.habitToEdit?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      type: _selectedType,
      category: _selectedCategory,
      icon: _selectedIcon,
      color: _selectedColor,
      frequency: _selectedFrequency,
      customDays: _customDays,
      targetValue: _targetValueController.text.isNotEmpty
          ? double.tryParse(_targetValueController.text)
          : null,
      targetUnit: _targetUnitController.text.trim().isEmpty
          ? null
          : _targetUnitController.text.trim(),
      hasReminder: _hasReminder,
      reminderHour: _hasReminder ? _reminderHour : null,
      reminderMinute: _hasReminder ? _reminderMinute : null,
      priority: _selectedPriority,
      durationMinutes: _durationMinutes,
      createdAt: widget.habitToEdit?.createdAt,
    );

    widget.onSave(habit);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildNameField(),
                  SizedBox(height: 16),
                  _buildDescriptionField(),
                  SizedBox(height: 16),
                  _buildTypeSection(),
                  SizedBox(height: 16),
                  _buildCategorySection(),
                  SizedBox(height: 16),
                  _buildIconSection(),
                  SizedBox(height: 16),
                  _buildColorSection(),
                  SizedBox(height: 16),
                  _buildFrequencySection(),
                  SizedBox(height: 16),
                  _buildPrioritySection(),
                  SizedBox(height: 16),
                  _buildDurationSection(),
                  SizedBox(height: 16),
                  _buildTargetSection(),
                  SizedBox(height: 16),
                  _buildReminderSection(),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.habitToEdit != null ? 'Modifier l\'habitude' : 'Nouvelle habitude',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Nom *',
        hintText: 'Ex: Faire du sport',
        prefixIcon: Icon(Icons.edit),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer un nom';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Description (optionnel)',
        hintText: 'Décrivez votre habitude...',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTypeSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type d\'habitude',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HabitType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.displayName),
                  avatar: Icon(type.icon, size: 18),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedType = type);
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 8),
            Text(
              _selectedType.description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catégorie',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HabitCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category.displayName),
                  avatar: Icon(category.icon, size: 18),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Icône',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HabitIcons.icons.entries.map((entry) {
                final isSelected = _selectedIcon == entry.value;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIcon = entry.value);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _selectedColor.withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _selectedColor
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(entry.value, size: 24),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Couleur',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(HabitColors.colors.length, (index) {
                final color = HabitColors.colors[index];
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fréquence',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...HabitFrequency.values.map((freq) {
              return RadioListTile<HabitFrequency>(
                title: Text(freq.displayName),
                value: freq,
                groupValue: _selectedFrequency,
                onChanged: (value) {
                  setState(() => _selectedFrequency = value!);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
            if (_selectedFrequency == HabitFrequency.CustomDays) ...[
              SizedBox(height: 12),
              Text('Jours personnalisés :'),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildDayChip('L', 1),
                  _buildDayChip('M', 2),
                  _buildDayChip('M', 3),
                  _buildDayChip('J', 4),
                  _buildDayChip('V', 5),
                  _buildDayChip('S', 6),
                  _buildDayChip('D', 0),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(String label, int dayIndex) {
    final isSelected = _customDays.contains(dayIndex);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _customDays.add(dayIndex);
          } else {
            _customDays.remove(dayIndex);
          }
        });
      },
    );
  }

  Widget _buildPrioritySection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priorité',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HabitPriority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                return ChoiceChip(
                  label: Text(priority.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedPriority = priority);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Durée (minutes)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _durationMinutes.toDouble(),
                    min: 0,
                    max: 180,
                    divisions: 36,
                    label: '$_durationMinutes min',
                    onChanged: (value) {
                      setState(() => _durationMinutes = value.toInt());
                    },
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  width: 60,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_durationMinutes min',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Objectif (optionnel)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _targetValueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Valeur',
                      hintText: 'Ex: 3',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _targetUnitController,
                    decoration: InputDecoration(
                      labelText: 'Unité',
                      hintText: 'Ex: litres',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('Rappel'),
              subtitle: Text('Recevoir une notification'),
              value: _hasReminder,
              onChanged: (value) {
                setState(() => _hasReminder = value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (_hasReminder) ...[
              SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.access_time),
                title: Text('Heure du rappel'),
                subtitle: Text(
                  '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                ),
                trailing: Icon(Icons.chevron_right),
                onTap: _pickReminderTime,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );

    if (time != null) {
      setState(() {
        _reminderHour = time.hour;
        _reminderMinute = time.minute;
      });
    }
  }

  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            widget.habitToEdit != null ? 'Enregistrer' : 'Créer l\'habitude',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
