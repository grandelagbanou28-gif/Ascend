import 'package:flutter/material.dart';
import 'package:ascend/data/models/sub_goal.dart';

class AddSubGoalSheet extends StatefulWidget {
  final Function(SubGoal) onSave;
  final SubGoal? subGoalToEdit;

  const AddSubGoalSheet({
    super.key,
    required this.onSave,
    this.subGoalToEdit,
  });

  @override
  State<AddSubGoalSheet> createState() => _AddSubGoalSheetState();
}

class _AddSubGoalSheetState extends State<AddSubGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _dueDate;
  GoalPriority _selectedPriority = GoalPriority.medium;
  double _progression = 0.0;

  bool get _isEditing => widget.subGoalToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadSubGoalData(widget.subGoalToEdit!);
    }
  }

  void _loadSubGoalData(SubGoal subGoal) {
    _nameController.text = subGoal.name;
    _notesController.text = subGoal.notes ?? '';
    _dueDate = subGoal.dueDate;
    _selectedPriority = subGoal.priority;
    _progression = subGoal.progression;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final subGoal = SubGoal(
      id: widget.subGoalToEdit?.id,
      name: _nameController.text.trim(),
      dueDate: _dueDate,
      priority: _selectedPriority,
      progression: _progression,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isCompleted: widget.subGoalToEdit?.isCompleted ?? false,
      completedAt: widget.subGoalToEdit?.completedAt,
      createdAt: widget.subGoalToEdit?.createdAt,
    );

    widget.onSave(subGoal);
    Navigator.pop(context);
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                  _buildDueDateSection(),
                  SizedBox(height: 16),
                  _buildPrioritySection(),
                  SizedBox(height: 16),
                  _buildProgressionSection(),
                  SizedBox(height: 16),
                  _buildNotesField(),
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
            _isEditing ? 'Modifier le sous-objectif' : 'Nouvel sous-objectif',
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
        hintText: 'Ex: Rechercher des informations',
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

  Widget _buildDueDateSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.calendar_today),
        title: Text('Date d\'échéance'),
        subtitle: Text(
          _dueDate != null
              ? '${_dueDate!.day.toString().padLeft(2, '0')}/${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.year}'
              : 'Non définie',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_dueDate != null)
              IconButton(
                onPressed: () => setState(() => _dueDate = null),
                icon: Icon(Icons.clear, size: 20),
              ),
            Icon(Icons.chevron_right),
          ],
        ),
        onTap: _pickDueDate,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
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
            ...GoalPriority.values.map((priority) {
              return RadioListTile<GoalPriority>(
                title: Text(priority.displayName),
                value: priority,
                groupValue: _selectedPriority,
                onChanged: (value) {
                  setState(() => _selectedPriority = value!);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressionSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progression',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  width: 60,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(_progression * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Slider(
              value: _progression,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: '${(_progression * 100).round()}%',
              onChanged: (value) {
                setState(() => _progression = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Notes (optionnel)',
        hintText: 'Ajoutez des notes...',
        prefixIcon: Icon(Icons.notes),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Enregistrer',
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
