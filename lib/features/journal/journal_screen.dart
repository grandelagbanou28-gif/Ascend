import 'package:flutter/material.dart';
import 'package:ascend/data/models/journal_entry.dart';
import 'package:ascend/core/services/journal_service.dart';
import 'package:intl/intl.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  DateTime _selectedDate = DateTime.now();
  Mood? _selectedMood;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  List<String> _tags = [];
  JournalEntry? _existingEntry;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    JournalService.loadEntries();
    _loadEntryForDate();
  }

  @override
  void dispose() {
    _textController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _loadEntryForDate() {
    final entry = JournalService.getEntryByDate(_selectedDate);
    setState(() {
      _existingEntry = entry;
      if (entry != null) {
        _selectedMood = entry.mood;
        _textController.text = entry.textContent ?? '';
        _tags = List<String>.from(entry.tags);
      } else {
        _selectedMood = null;
        _textController.clear();
        _tags = [];
      }
    });
  }

  List<DateTime> _getWeekDays() {
    final now = _selectedDate;
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveEntry() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner votre humeur')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_existingEntry != null) {
        _existingEntry!.mood = _selectedMood!;
        _existingEntry!.textContent = _textController.text.isEmpty
            ? null
            : _textController.text;
        _existingEntry!.tags = List<String>.from(_tags);
        _existingEntry!.updatedAt = DateTime.now();
        await JournalService.updateEntry(_existingEntry!);
      } else {
        final entry = JournalEntry(
          date: _selectedDate,
          mood: _selectedMood!,
          textContent: _textController.text.isEmpty
              ? null
              : _textController.text,
          tags: List<String>.from(_tags),
        );
        await JournalService.addEntry(entry);
        _existingEntry = entry;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal enregistré')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildDateSelector(theme),
            const SizedBox(height: 16),
            _buildMoodSection(theme),
            if (_selectedMood != null) ...[
              const SizedBox(height: 16),
              _buildEntrySection(theme),
            ],
            const SizedBox(height: 24),
            _buildSaveButton(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    final weekDays = _getWeekDays();
    final dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          final day = weekDays[index];
          final isSelected = _isSameDay(day, _selectedDate);
          final isToday = _isSameDay(day, DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = day);
              _loadEntryForDate();
            },
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comment je me sens?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: Mood.values.map((mood) {
                final isSelected = _selectedMood == mood;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedMood = mood);
                    if (_existingEntry == null) {
                      _loadEntryForDate();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : Border.all(
                              color: theme.colorScheme.outlineVariant,
                              width: 1,
                            ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          mood.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mood.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntrySection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(theme),
            const SizedBox(height: 12),
            _buildActionButtons(theme),
            const SizedBox(height: 12),
            _buildTagsSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(ThemeData theme) {
    return TextField(
      controller: _textController,
      maxLines: null,
      minLines: 4,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText: 'Écrire...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sélection de photo - à implémenter'),
                ),
              );
            },
            icon: const Icon(Icons.photo_camera),
            label: const Text('Photos'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enregistrement audio - à implémenter'),
                ),
              );
            },
            icon: const Icon(Icons.mic),
            label: const Text('Audio'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.map((tag) => Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeTag(tag),
                  backgroundColor:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                )),
            SizedBox(
              width: 150,
              height: 32,
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Ajouter un tag',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: theme.colorScheme.primary),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: _addTag,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                onSubmitted: (_) => _addTag(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isSaving ? null : _saveEntry,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Enregistrer',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher dans le journal'),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final results =
                  JournalService.searchEntries(searchController.text);
              Navigator.pop(context);
              _showSearchResults(results);
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(List<JournalEntry> results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Résultats (${results.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text('Aucun résultat trouvé'),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final entry = results[index];
                        return ListTile(
                          leading: Text(
                            entry.mood.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            DateFormat('d MMMM yyyy', 'fr_FR')
                                .format(entry.date),
                          ),
                          subtitle: entry.textContent != null
                              ? Text(
                                  entry.textContent!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _selectedDate = entry.date;
                            });
                            _loadEntryForDate();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
