import 'package:flutter/material.dart';
import 'package:ascend/data/models/goal.dart';
import 'package:ascend/data/models/sub_goal.dart';
import 'package:ascend/core/services/goal_service.dart';
import 'package:intl/intl.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;
  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  Goal get goal => widget.goal;

  void _refresh() => setState(() {});

  String _formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy', 'fr_FR').format(date);

  Color _statusColor() {
    switch (goal.status) {
      case GoalStatus.active:
        return Colors.green;
      case GoalStatus.completed:
        return Colors.blue;
      case GoalStatus.paused:
        return Colors.orange;
      case GoalStatus.abandoned:
        return Colors.red;
    }
  }

  Color _priorityColor(GoalPriority priority) {
    switch (priority) {
      case GoalPriority.low:
        return Colors.grey;
      case GoalPriority.medium:
        return Colors.orange;
      case GoalPriority.high:
        return Colors.deepOrange;
      case GoalPriority.urgent:
        return Colors.red;
    }
  }

  // --- AppBar actions ---
  void _showEditGoalSheet() {
    final nameCtrl = TextEditingController(text: goal.name);
    final descCtrl = TextEditingController(text: goal.description ?? '');
    final durationCtrl = TextEditingController(text: goal.duration ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modifier l\'objectif',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nom', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationCtrl,
              decoration: const InputDecoration(
                  labelText: 'Durée', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  goal.name = nameCtrl.text.trim();
                  goal.description = descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim();
                  goal.duration = durationCtrl.text.trim().isEmpty
                      ? null
                      : durationCtrl.text.trim();
                  await GoalService.updateGoal(goal);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _refresh();
                },
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'objectif'),
        content:
            Text('Voulez-vous vraiment supprimer « ${goal.name} » ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await GoalService.deleteGoal(goal.id);
      if (mounted) Navigator.pop(context);
    }
  }

  // --- Sub-goal management ---
  void _showAddSubGoalSheet() {
    final nameCtrl = TextEditingController();
    GoalPriority selectedPriority = GoalPriority.medium;
    DateTime? selectedDueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ajouter un sous-objectif',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nom', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GoalPriority>(
                value: selectedPriority,
                decoration: const InputDecoration(
                    labelText: 'Priorité', border: OutlineInputBorder()),
                items: GoalPriority.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheetState(() => selectedPriority = v);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(selectedDueDate == null
                    ? 'Choisir une date d\'échéance'
                    : _formatDate(selectedDueDate!)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setSheetState(() => selectedDueDate = picked);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: nameCtrl.text.trim().isEmpty
                      ? null
                      : () async {
                          final sub = SubGoal(
                            name: nameCtrl.text.trim(),
                            priority: selectedPriority,
                            dueDate: selectedDueDate,
                          );
                          await GoalService.addSubGoal(goal.id, sub);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _refresh();
                        },
                  child: const Text('Ajouter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSubGoalSheet(SubGoal sub) {
    final nameCtrl = TextEditingController(text: sub.name);
    final notesCtrl = TextEditingController(text: sub.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Modifier le sous-objectif',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nom', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GoalPriority>(
                value: sub.priority,
                decoration: const InputDecoration(
                    labelText: 'Priorité', border: OutlineInputBorder()),
                items: GoalPriority.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheetState(() => sub.priority = v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Progression : '),
                  Expanded(
                    child: Slider(
                      value: sub.progression,
                      onChanged: (v) => setSheetState(() => sub.progression = v),
                    ),
                  ),
                  Text('${(sub.progression * 100).round()}%'),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Notes', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    sub.name = nameCtrl.text.trim();
                    sub.notes = notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim();
                    await GoalService.updateSubGoal(goal.id, sub);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _refresh();
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSubGoal(SubGoal sub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le sous-objectif'),
        content: Text('Voulez-vous vraiment supprimer « ${sub.name} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await GoalService.deleteSubGoal(goal.id, sub.id);
      _refresh();
    }
  }

  // --- Goal status actions ---
  Future<void> _completeGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer l\'objectif'),
        content: const Text('Marquer cet objectif comme terminé ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await GoalService.completeGoal(goal.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pauseOrResume() async {
    if (goal.status == GoalStatus.paused) {
      await GoalService.resumeGoal(goal.id);
    } else {
      await GoalService.pauseGoal(goal.id);
    }
    _refresh();
  }

  Future<void> _abandonGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandonner l\'objectif'),
        content: const Text('Voulez-vous vraiment abandonner cet objectif ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, abandonner'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await GoalService.abandonGoal(goal.id);
      if (mounted) Navigator.pop(context);
    }
  }

  // --- Build helpers ---
  Widget _buildHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            if (goal.description != null && goal.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                goal.description!,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
            ],
            if (goal.duration != null && goal.duration!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(goal.duration!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Chip(
              label: Text(goal.statusDisplayName,
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: _statusColor(),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(goal.progression * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${goal.completedSubGoals} / ${goal.totalSubGoals} sous-objectifs',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progression,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.play_circle_outline,
                    size: 18, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text('Début : ${_formatDate(goal.startDate)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
            if (goal.endDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.flag_outlined, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text('Fin : ${_formatDate(goal.endDate!)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubGoalTile(SubGoal sub) {
    final dueText = sub.dueDate != null ? _formatDate(sub.dueDate!) : null;
    final isOverdue =
        sub.dueDate != null && sub.dueDate!.isBefore(DateTime.now()) && !sub.isCompleted;

    return Dismissible(
      key: ValueKey(sub.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteSubGoal(sub);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showEditSubGoalSheet(sub),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: sub.isCompleted,
                      onChanged: (val) async {
                        sub.isCompleted = val ?? false;
                        if (sub.isCompleted) {
                          sub.progression = 1.0;
                          sub.completedAt = DateTime.now();
                        } else {
                          sub.progression = 0.0;
                          sub.completedAt = null;
                        }
                        await GoalService.updateSubGoal(goal.id, sub);
                        _refresh();
                      },
                    ),
                    Expanded(
                      child: Text(
                        sub.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: sub.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: sub.isCompleted ? Colors.grey : null,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _priorityColor(sub.priority).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        sub.priority.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _priorityColor(sub.priority),
                        ),
                      ),
                    ),
                  ],
                ),
                if (dueText != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14,
                            color: isOverdue ? Colors.red : Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          dueText,
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red : Colors.grey[600],
                            fontWeight:
                                isOverdue ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 4),
                          const Text('En retard',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.red)),
                        ],
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: sub.progression,
                          activeColor: _priorityColor(sub.priority),
                          onChanged: (val) async {
                            sub.progression = val;
                            if (val >= 1.0 && !sub.isCompleted) {
                              sub.isCompleted = true;
                              sub.completedAt = DateTime.now();
                            } else if (val < 1.0 && sub.isCompleted) {
                              sub.isCompleted = false;
                              sub.completedAt = null;
                            }
                            await GoalService.updateSubGoal(goal.id, sub);
                            _refresh();
                          },
                        ),
                      ),
                      Text(
                        '${(sub.progression * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubGoalsSection() {
    final subGoals = goal.subGoals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Sous-objectifs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${goal.completedSubGoals}/${goal.totalSubGoals}',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (subGoals.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.checklist, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun sous-objectif',
                    style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Appuyez sur « Ajouter » pour commencer',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          )
        else
          ...subGoals.map(_buildSubGoalTile),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: _showAddSubGoalSheet,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un sous-objectif'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isActive = goal.status == GoalStatus.active;
    final isPaused = goal.status == GoalStatus.paused;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          if (isActive) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _completeGoal,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Terminer l\'objectif'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (isActive || isPaused)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _pauseOrResume,
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(isPaused ? 'Reprendre' : 'Mettre en pause'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (isActive) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _abandonGoal,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Abandonner'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: _showEditGoalSheet,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
            onPressed: _confirmDeleteGoal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildSubGoalsSection(),
            const SizedBox(height: 16),
            if (goal.status == GoalStatus.active ||
                goal.status == GoalStatus.paused)
              _buildActionButtons(),
          ],
        ),
      ),
    );
  }
}
