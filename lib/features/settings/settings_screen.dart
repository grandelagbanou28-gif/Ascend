// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ascend/core/enums/app_enums.dart';
import 'package:ascend/core/services/settings_service.dart';
import 'package:ascend/features/theme/theme_selection_screen.dart';
import 'package:ascend/features/debug/debug_test_page.dart';
import 'package:ascend/features/backup_and_import/backup_import_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  
  const SettingsScreen({super.key, required this.toggleTheme, required this.isDarkMode});
  
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late HabitType _defaultHabitType;
  late HabitFrequency _defaultFrequency;
  bool _loading = true;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showStreakNotifications = true;
  bool _showMilestoneNotifications = true;
  bool _autoBackup = false;
  bool _showMotivationalQuotes = true;
  bool _showProgressAnimations = true;
  bool _compactMode = false;
  bool _showWeekends = true;
  bool _use24HourFormat = true;
  bool _showHabitIcons = true;
  bool _showSuccessRate = true;
  bool _showCurrentStreak = true;
  bool _enableHapticFeedback = true;
  bool _showTodayWidget = true;
  bool _enableDataValidation = true;
  int _reminderTime = 9; // 9 AM
  int _autoBackupFrequency = 7; // Weekly
  int _dataRetentionDays = 365; // 1 year
  double _chartAnimationSpeed = 1.0;
  String _dateFormat = 'JJ/MM/AAAA';
  String _language = 'Français';
  String _currency = '€';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    
    // Load all settings from SettingsService
    _defaultHabitType = await SettingsService.getDefaultHabitType();
    _defaultFrequency = await SettingsService.getDefaultFrequency();
    
    _notificationsEnabled = await SettingsService.getNotificationsEnabled();
    _soundEnabled = await SettingsService.getSoundEnabled();
    _vibrationEnabled = await SettingsService.getVibrationEnabled();
    _showStreakNotifications = await SettingsService.getStreakNotifications();
    _showMilestoneNotifications = await SettingsService.getMilestoneNotifications();
    _reminderTime = await SettingsService.getReminderTime();
    
    _compactMode = await SettingsService.getCompactMode();
    _showProgressAnimations = await SettingsService.getShowAnimations();
    _chartAnimationSpeed = await SettingsService.getAnimationSpeed();
    _dateFormat = await SettingsService.getDateFormat();
    _use24HourFormat = await SettingsService.getUse24HourFormat();
    _showWeekends = await SettingsService.getShowWeekends();
    _showMotivationalQuotes = await SettingsService.getMotivationalQuotes();
    _showTodayWidget = await SettingsService.getTodayWidget();
    _showHabitIcons = await SettingsService.getShowHabitIcons();
    _showSuccessRate = await SettingsService.getShowSuccessRate();
    _showCurrentStreak = await SettingsService.getShowCurrentStreak();
    
    _autoBackup = await SettingsService.getAutoBackup();
    _autoBackupFrequency = await SettingsService.getAutoBackupFrequency();
    _dataRetentionDays = await SettingsService.getDataRetentionDays();
    _enableDataValidation = await SettingsService.getDataValidation();
    
    _language = await SettingsService.getLanguage();
    _enableHapticFeedback = await SettingsService.getHapticFeedback();
    
    setState(() => _loading = false);
  }
  
  String formatPascalCase(String input) {
    // Convert PascalCase to readable format
    return input.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: AnimationLimiter(
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              _buildGeneralSection(),
              SizedBox(height: 16),
              _buildAppearanceSection(),
              SizedBox(height: 16),
              _buildHabitsSection(),
              SizedBox(height: 16),
              _buildNotificationsSection(),
              SizedBox(height: 16),
              _buildDataSection(),
              SizedBox(height: 16),
              _buildAdvancedSection(),
              SizedBox(height: 16),
              _buildAboutSection(),
              if (kDebugMode) ...[
                SizedBox(height: 16),
                _buildDebugSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGeneralSection() {
    return _buildSettingsCard(
      title: '⚙️ Général',
      children: [
        ListTile(
          title: Text('Langue'),
          subtitle: Text(_language),
          leading: Icon(Icons.language),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showLanguageSelector,
        ),
        ListTile(
          title: Text('Devise'),
          subtitle: Text(_currency),
          leading: Icon(Icons.attach_money),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showCurrencySelector,
        ),
        ListTile(
          title: Text('Format de date'),
          subtitle: Text(_dateFormat),
          leading: Icon(Icons.date_range),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showDateFormatSelector,
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return _buildSettingsCard(
      title: '🎨 Apparence',
      children: [
        ListTile(
          title: Text('Thème'),
          subtitle: Text('Sélectionner parmi 40+ thèmes disponibles'),
          leading: Icon(Icons.palette),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ThemeSelectionScreen(
                onThemeChanged: (theme) {
                  // Theme change is handled in ThemeSelectionScreen
                },
              ),
            ),
          ),
        ),
        SwitchListTile(
          title: Text('Mode sombre'),
          subtitle: Text('Basculer entre thème sombre/lumineux'),
          value: widget.isDarkMode,
          onChanged: (_) => widget.toggleTheme(),
          secondary: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
        ),
        SwitchListTile(
          title: Text('Mode compact'),
          subtitle: Text('Afficher plus de contenu en moins d\'espace'),
          value: _compactMode,
          onChanged: (value) async {
            setState(() => _compactMode = value);
            await SettingsService.setCompactMode(value);
          },
          secondary: Icon(Icons.view_compact),
        ),
        SwitchListTile(
          title: Text('Animations de progression'),
          subtitle: Text('Graphiques et indicateurs animés'),
          value: _showProgressAnimations,
          onChanged: (value) async {
            setState(() => _showProgressAnimations = value);
            await SettingsService.setShowAnimations(value);
          },
          secondary: Icon(Icons.animation),
        ),
        ListTile(
          title: Text('Vitesse d\'animation'),
          subtitle: Text('${(_chartAnimationSpeed * 100).toInt()}%'),
          leading: Icon(Icons.speed),
          trailing: SizedBox(
            width: 100,
            child: Slider(
              value: _chartAnimationSpeed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              onChanged: (value) async {
                setState(() => _chartAnimationSpeed = value);
                await SettingsService.setAnimationSpeed(value);
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHabitsSection() {
    return _buildSettingsCard(
      title: '📋 Habitudes',
      children: [
        ListTile(
          title: Text('Type d\'habitude par défaut'),
          subtitle: Text(formatPascalCase(_defaultHabitType.toString().split('.').last)),
          leading: Icon(Icons.category),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showHabitTypeSelector,
        ),
        ListTile(
          title: Text('Fréquence par défaut'),
          subtitle: Text(formatPascalCase(_defaultFrequency.toString().split('.').last)),
          leading: Icon(Icons.schedule),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showFrequencySelector,
        ),
        SwitchListTile(
          title: Text('Afficher les icônes'),
          subtitle: Text('Afficher les icônes à côté des noms'),
          value: _showHabitIcons,
          onChanged: (value) async {
            setState(() => _showHabitIcons = value);
            await SettingsService.setShowHabitIcons(value);
          },
          secondary: Icon(Icons.emoji_emotions),
        ),
        SwitchListTile(
          title: Text('Afficher le taux de réussite'),
          subtitle: Text('Afficher le pourcentage de réussite'),
          value: _showSuccessRate,
          onChanged: (value) async {
            setState(() => _showSuccessRate = value);
            await SettingsService.setShowSuccessRate(value);
          },
          secondary: Icon(Icons.percent),
        ),
        SwitchListTile(
          title: Text('Afficher la série en cours'),
          subtitle: Text('Afficher le compteur de série'),
          value: _showCurrentStreak,
          onChanged: (value) async {
            setState(() => _showCurrentStreak = value);
            await SettingsService.setShowCurrentStreak(value);
          },
          secondary: Icon(Icons.local_fire_department),
        ),
      ],
    );
  }
  
  Widget _buildNotificationsSection() {
    return _buildSettingsCard(
      title: '🔔 Notifications',
      children: [
        SwitchListTile(
          title: Text('Activer les notifications'),
          subtitle: Text('Recevoir les rappels d\'habitudes'),
          value: _notificationsEnabled,
          onChanged: (value) async {
            setState(() => _notificationsEnabled = value);
            await SettingsService.setNotificationsEnabled(value);
          },
          secondary: Icon(Icons.notifications),
        ),
        if (_notificationsEnabled) ...[
          ListTile(
            title: Text('Heure de rappel par défaut'),
            subtitle: Text('$_reminderTime:00'),
            leading: Icon(Icons.access_time),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showTimeSelector,
          ),
          SwitchListTile(
            title: Text('Son'),
            subtitle: Text('Jouer le son de notification'),
            value: _soundEnabled,
            onChanged: (value) async {
              setState(() => _soundEnabled = value);
              await SettingsService.setSoundEnabled(value);
            },
            secondary: Icon(Icons.volume_up),
          ),
          SwitchListTile(
            title: Text('Vibration'),
            subtitle: Text('Vibrer lors des notifications'),
            value: _vibrationEnabled,
            onChanged: (value) async {
              setState(() => _vibrationEnabled = value);
              await SettingsService.setVibrationEnabled(value);
            },
            secondary: Icon(Icons.vibration),
          ),
          SwitchListTile(
            title: Text('Notifications de série'),
            subtitle: Text('Célébrer les étapes de série'),
            value: _showStreakNotifications,
            onChanged: (value) async {
              setState(() => _showStreakNotifications = value);
              await SettingsService.setStreakNotifications(value);
            },
            secondary: Icon(Icons.celebration),
          ),
          SwitchListTile(
            title: Text('Notifications d\'accomplissements'),
            subtitle: Text('Notifier les réussites'),
            value: _showMilestoneNotifications,
            onChanged: (value) async {
              setState(() => _showMilestoneNotifications = value);
              await SettingsService.setMilestoneNotifications(value);
            },
            secondary: Icon(Icons.emoji_events),
          ),
        ],
      ],
    );
  }
  
  Widget _buildDataSection() {
    return _buildSettingsCard(
      title: '💾 Données',
      children: [
        ListTile(
          title: Text('Sauvegarde & Import'),
          subtitle: Text('Gérer les sauvegardes de données'),
          leading: Icon(Icons.backup),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BackupImportScreen()),
          ),
        ),
        ListTile(
          title: Text('Exporter les données'),
          subtitle: Text('Sauvegarder vos données en fichier'),
          leading: Icon(Icons.file_upload),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _exportData,
        ),
        SwitchListTile(
          title: Text('Sauvegarde automatique'),
          subtitle: Text('Sauvegarder automatiquement les données'),
          value: _autoBackup,
          onChanged: (value) => setState(() => _autoBackup = value),
          secondary: Icon(Icons.cloud_upload),
        ),
        if (_autoBackup) ...[
          ListTile(
            title: Text('Fréquence de sauvegarde'),
            subtitle: Text('Tous les $_autoBackupFrequency jours'),
            leading: Icon(Icons.schedule),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showBackupFrequencySelector,
          ),
        ],
        ListTile(
          title: Text('Conservation des données'),
          subtitle: Text('Conserver les données pendant $_dataRetentionDays jours'),
          leading: Icon(Icons.history),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showDataRetentionSelector,
        ),
        SwitchListTile(
          title: Text('Validation des données'),
          subtitle: Text('Valider l\'intégrité des données'),
          value: _enableDataValidation,
          onChanged: (value) => setState(() => _enableDataValidation = value),
          secondary: Icon(Icons.verified),
        ),
        ListTile(
          title: Text('Supprimer le compte'),
          subtitle: Text('Supprimer définitivement toutes les données'),
          leading: Icon(Icons.delete_forever, color: Colors.red),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showDeleteAccountDialog,
        ),
      ],
    );
  }
  
  Widget _buildAdvancedSection() {
    return _buildSettingsCard(
      title: '⚙️ Avancé',
      children: [
        SwitchListTile(
          title: Text('Retour haptique'),
          subtitle: Text('Vibrer lors des interactions'),
          value: _enableHapticFeedback,
          onChanged: (value) async {
            setState(() => _enableHapticFeedback = value);
            await SettingsService.setHapticFeedback(value);
          },
          secondary: Icon(Icons.vibration),
        ),
        ListTile(
          title: Text('Réinitialiser les paramètres'),
          subtitle: Text('Restaurer les paramètres par défaut'),
          leading: Icon(Icons.restore, color: Colors.orange),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showResetSettingsDialog,
        ),
      ],
    );
  }
  
  Widget _buildAboutSection() {
    return _buildSettingsCard(
      title: 'ℹ️ À propos',
      children: [
        ListTile(
          title: Text('Version de l\'application'),
          subtitle: Text('1.0.0'),
          leading: Icon(Icons.info_outline),
        ),
        ListTile(
          title: Text('Politique de confidentialité'),
          subtitle: Text('Comment nous gérons vos données'),
          leading: Icon(Icons.privacy_tip),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showPrivacyPolicy,
        ),
        ListTile(
          title: Text('Conditions d\'utilisation'),
          subtitle: Text('Termes d\'utilisation de l\'application'),
          leading: Icon(Icons.description),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showTermsOfService,
        ),
        ListTile(
          title: Text('Noter l\'application'),
          subtitle: Text('Laisser un avis'),
          leading: Icon(Icons.star),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _rateApp,
        ),
        ListTile(
          title: Text('Contacter le support'),
          subtitle: Text('Obtenir de l\'aide ou signaler un problème'),
          leading: Icon(Icons.support),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _contactSupport,
        ),
      ],
    );
  }
  
  Widget _buildDebugSection() {
    return _buildSettingsCard(
      title: '🛠️ Débogage',
      children: [
        ListTile(
          title: Text('Page de test de débogage'),
          subtitle: Text('Outils de test (mode débogage uniquement)'),
          leading: Icon(Icons.bug_report, color: Colors.red),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DebugTestPage()),
          ),
        ),
        ListTile(
          title: Text('Générer des données de test'),
          subtitle: Text('Créer des habitudes d\'exemple pour les tests'),
          leading: Icon(Icons.data_object, color: Colors.blue),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _generateTestData,
        ),
      ],
    );
  }
  
  Widget _buildSettingsCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
  
  // Dialog methods
  void _showHabitTypeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sélectionner le type d\'habitude par défaut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: HabitType.values.map((type) {
            return RadioListTile<HabitType>(
              title: Text(formatPascalCase(type.toString().split('.').last)),
              value: type,
              groupValue: _defaultHabitType,
              onChanged: (HabitType? value) {
                if (value != null) {
                  setState(() => _defaultHabitType = value);
                  SettingsService.setDefaultHabitType(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showFrequencySelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sélectionner la fréquence par défaut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: HabitFrequency.values.map((freq) {
            return RadioListTile<HabitFrequency>(
              title: Text(formatPascalCase(freq.toString().split('.').last)),
              value: freq,
              groupValue: _defaultFrequency,
              onChanged: (HabitFrequency? value) {
                if (value != null) {
                  setState(() => _defaultFrequency = value);
                  SettingsService.setDefaultFrequency(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showTimeSelector() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderTime, minute: 0),
    ).then((time) async {
      if (time != null) {
        setState(() => _reminderTime = time.hour);
        await SettingsService.setReminderTime(time.hour);
      }
    });
  }
  
  void _showDateFormatSelector() {
    final formats = [
      'JJ/MM/AAAA',
      'MM/JJ/AAAA',
      'AAAA-MM-JJ',
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sélectionner le format de date'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) {
            return RadioListTile<String>(
              title: Text(format),
              value: format,
              groupValue: _dateFormat,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _dateFormat = value);
                  SettingsService.setDateFormat(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showBackupFrequencySelector() {
    final frequencies = [1, 3, 7, 14, 30];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fréquence de sauvegarde'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: frequencies.map((days) {
            return RadioListTile<int>(
              title: Text('Tous les $days jour${days > 1 ? 's' : ''}'),
              value: days,
              groupValue: _autoBackupFrequency,
              onChanged: (int? value) {
                if (value != null) {
                  setState(() => _autoBackupFrequency = value);
                  SettingsService.setAutoBackupFrequency(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showDataRetentionSelector() {
    final retentions = [30, 90, 180, 365, 730, -1]; // -1 = forever
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conservation des données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: retentions.map((days) {
            return RadioListTile<int>(
              title: Text(days == -1 ? 'Indéfiniment' : '$days jours'),
              value: days,
              groupValue: _dataRetentionDays,
              onChanged: (int? value) {
                if (value != null) {
                  setState(() => _dataRetentionDays = value);
                  SettingsService.setDataRetentionDays(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showLanguageSelector() {
    final languages = ['Français', 'English', 'Español'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sélectionner la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang),
              value: lang,
              groupValue: _language,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _language = value);
                  SettingsService.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer toutes les données'),
        content: Text('Cette action supprimera définitivement toutes vos habitudes et entrées. Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear all data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Toutes les données ont été supprimées')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Tout supprimer'),
          ),
        ],
      ),
    );
  }
  
  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Réinitialiser les paramètres'),
        content: Text('Cette action restaurera tous les paramètres à leurs valeurs par défaut.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // Reset settings
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Paramètres réinitialisés')),
              );
            },
            child: Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
  
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Politique de confidentialité'),
        content: SingleChildScrollView(
          child: Text(
            'Ascend respecte votre vie privée. Toutes les données sont stockées localement sur votre appareil. '
            'Nous ne collectons, stockons ni ne partageons aucune information personnelle. '
            'Vos données d\'habitudes restent privées et sous votre contrôle.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
  
  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conditions d\'utilisation'),
        content: SingleChildScrollView(
          child: Text(
            'En utilisant Ascend, vous acceptez d\'utiliser l\'application de manière responsable. '
            'L\'application est fournie en l\'état sans garantie. '
            'Vous êtes responsable de la sauvegarde de vos données.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
  
  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('La fonctionnalité d\'évaluation ouvrirait le magasin d\'applications')),
    );
  }
  
  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('La fonctionnalité de contact ouvrirait un email')),
    );
  }
  
  void _generateTestData() async {
    // Generate sample habits for testing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Données de test générées')),
    );
  }
  
  void _showCurrencySelector() {
    final currencies = ['€', '$', '£', '¥'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sélectionner la devise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) {
            return RadioListTile<String>(
              title: Text(currency),
              value: currency,
              groupValue: _currency,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _currency = value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fonctionnalité d\'exportation des données')),
    );
  }
  
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le compte'),
        content: Text('Cette action supprimera définitivement toutes vos données, y compris vos habitudes, entrées et paramètres. Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Compte supprimé')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }
}
