import 'package:flutter/material.dart';
import 'package:ascend/data/models/challenge.dart';

class CreateChallengeSheet extends StatefulWidget {
  final Function(Challenge) onSave;

  const CreateChallengeSheet({super.key, required this.onSave});

  @override
  State<CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<CreateChallengeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _xpController = TextEditingController();
  final _badgeNameController = TextEditingController();
  final _rewardDescriptionController = TextEditingController();
  final _customDurationController = TextEditingController();

  ChallengeDifficulty _selectedDifficulty = ChallengeDifficulty.medium;
  int _selectedDuration = 30;
  bool _isCustomDuration = false;
  bool _isPresetSelected = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _xpController.dispose();
    _badgeNameController.dispose();
    _rewardDescriptionController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  void _selectPreset(Challenge preset) {
    setState(() {
      _isPresetSelected = true;
      _nameController.text = preset.name;
      _descriptionController.text = preset.description;
      _selectedDuration = preset.durationDays;
      _selectedDifficulty = preset.difficulty;
      _xpController.text = preset.xpReward.toString();
      _badgeNameController.text = preset.badgeName ?? '';
      _rewardDescriptionController.text = preset.rewardDescription ?? '';
      _isCustomDuration = false;
      _customDurationController.clear();
    });
  }

  void _clearPresetSelection() {
    setState(() {
      _isPresetSelected = false;
      _nameController.clear();
      _descriptionController.clear();
      _selectedDuration = 30;
      _selectedDifficulty = ChallengeDifficulty.medium;
      _xpController.clear();
      _badgeNameController.clear();
      _rewardDescriptionController.clear();
      _isCustomDuration = false;
      _customDurationController.clear();
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final int duration = _isCustomDuration
        ? (int.tryParse(_customDurationController.text) ?? 30)
        : _selectedDuration;

    final challenge = Challenge(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      durationDays: duration,
      difficulty: _selectedDifficulty,
      xpReward: int.tryParse(_xpController.text) ?? 100,
      badgeName: _badgeNameController.text.trim().isEmpty
          ? null
          : _badgeNameController.text.trim(),
      rewardDescription: _rewardDescriptionController.text.trim().isEmpty
          ? null
          : _rewardDescriptionController.text.trim(),
    );

    widget.onSave(challenge);
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
                  _buildPresetSection(),
                  SizedBox(height: 24),
                  _buildDivider(),
                  SizedBox(height: 24),
                  _buildCustomSection(),
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
            'Nouveau défi',
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

  Widget _buildPresetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Défis prédéfinis',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: Challenge.presets.length,
          itemBuilder: (context, index) {
            final preset = Challenge.presets[index];
            return _buildPresetCard(preset);
          },
        ),
      ],
    );
  }

  Widget _buildPresetCard(Challenge preset) {
    final isSelected = _isPresetSelected &&
        _nameController.text == preset.name;

    return GestureDetector(
      onTap: () => _selectPreset(preset),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                preset.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                '${preset.durationDays} jours',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(preset.difficulty)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      preset.difficulty.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getDifficultyColor(preset.difficulty),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '${preset.xpReward} XP',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Défi personnalisé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isPresetSelected) ...[
              Spacer(),
              TextButton(
                onPressed: _clearPresetSelection,
                child: Text('Réinitialiser'),
              ),
            ],
          ],
        ),
        SizedBox(height: 12),
        _buildNameField(),
        SizedBox(height: 16),
        _buildDescriptionField(),
        SizedBox(height: 16),
        _buildDurationField(),
        SizedBox(height: 16),
        _buildDifficultyField(),
        SizedBox(height: 16),
        _buildXpField(),
        SizedBox(height: 16),
        _buildBadgeNameField(),
        SizedBox(height: 16),
        _buildRewardDescriptionField(),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Nom *',
        hintText: 'Ex: Courir tous les matins',
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
        labelText: 'Description *',
        hintText: 'Décrivez votre défi...',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer une description';
        }
        return null;
      },
    );
  }

  Widget _buildDurationField() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Durée',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...Challenge.presetDurations.map((days) {
                  final isSelected = !_isCustomDuration &&
                      _selectedDuration == days;
                  return ChoiceChip(
                    label: Text('$days jours'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _isCustomDuration = false;
                        _selectedDuration = days;
                        _customDurationController.clear();
                      });
                    },
                  );
                }),
                ChoiceChip(
                  label: Text('Personnalisé'),
                  selected: _isCustomDuration,
                  onSelected: (selected) {
                    setState(() {
                      _isCustomDuration = selected;
                    });
                  },
                ),
              ],
            ),
            if (_isCustomDuration) ...[
              SizedBox(height: 12),
              TextFormField(
                controller: _customDurationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nombre de jours',
                  hintText: 'Ex: 45',
                  suffixText: 'jours',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (_isCustomDuration) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un nombre de jours';
                    }
                    final days = int.tryParse(value);
                    if (days == null || days <= 0) {
                      return 'Veuillez entrer un nombre valide';
                    }
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyField() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Difficulté',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...ChallengeDifficulty.values.map((difficulty) {
              return RadioListTile<ChallengeDifficulty>(
                title: Text(difficulty.displayName),
                value: difficulty,
                groupValue: _selectedDifficulty,
                onChanged: (value) {
                  setState(() => _selectedDifficulty = value!);
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

  Widget _buildXpField() {
    return TextFormField(
      controller: _xpController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Récompense XP',
        hintText: 'Ex: 200',
        suffixText: 'XP',
        prefixIcon: Icon(Icons.star),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final xp = int.tryParse(value);
          if (xp == null || xp < 0) {
            return 'Veuillez entrer un nombre valide';
          }
        }
        return null;
      },
    );
  }

  Widget _buildBadgeNameField() {
    return TextFormField(
      controller: _badgeNameController,
      decoration: InputDecoration(
        labelText: 'Nom du badge (optionnel)',
        hintText: 'Ex: Champion',
        prefixIcon: Icon(Icons.emoji_events),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRewardDescriptionField() {
    return TextFormField(
      controller: _rewardDescriptionController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Description de la récompense (optionnel)',
        hintText: 'Ex: Badge "Champion" + 500 XP',
        prefixIcon: Icon(Icons.card_giftcard),
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
            'Lancer le défi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return Colors.green;
      case ChallengeDifficulty.medium:
        return Colors.orange;
      case ChallengeDifficulty.hard:
        return Colors.red;
      case ChallengeDifficulty.extreme:
        return Colors.purple;
    }
  }
}
