import 'package:flutter/material.dart';
import 'package:ascend/core/services/profile_service.dart';
import 'package:ascend/data/models/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile? profile;

  const EditProfileScreen({super.key, this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _countryController;
  late TextEditingController _quoteController;
  
  String? _selectedLanguage;
  String? _selectedTimezone;
  String? _selectedTheme;
  String? _selectedPrimaryColor;
  bool _isLoading = false;

  final List<Map<String, String>> _languages = [
    {'code': 'fr', 'name': 'Français'},
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'de', 'name': 'Deutsch'},
    {'code': 'ar', 'name': 'العربية'},
    {'code': 'zh', 'name': '中文'},
    {'code': 'ja', 'name': '日本語'},
    {'code': 'pt', 'name': 'Português'},
  ];

  final List<Map<String, String>> _timezones = [
    {'id': 'Europe/Paris', 'name': 'Paris (UTC+1)'},
    {'id': 'Europe/London', 'name': 'Londres (UTC+0)'},
    {'id': 'America/New_York', 'name': 'New York (UTC-5)'},
    {'id': 'America/Los_Angeles', 'name': 'Los Angeles (UTC-8)'},
    {'id': 'Asia/Tokyo', 'name': 'Tokyo (UTC+9)'},
    {'id': 'Asia/Dubai', 'name': 'Dubaï (UTC+4)'},
    {'id': 'Africa/Casablanca', 'name': 'Casablanca (UTC+1)'},
    {'id': 'Pacific/Auckland', 'name': 'Auckland (UTC+12)'},
  ];

  final List<Map<String, dynamic>> _themes = [
    {'id': 'default', 'name': 'Default', 'icon': Icons.palette},
    {'id': 'ocean', 'name': 'Océan', 'icon': Icons.water},
    {'id': 'sunset', 'name': 'Coucher de soleil', 'icon': Icons.wb_sunny},
    {'id': 'forest', 'name': 'Forêt', 'icon': Icons.forest},
    {'id': 'royal', 'name': 'Royal', 'icon': Icons.diamond},
    {'id': 'crimson', 'name': 'Cramoisi', 'icon': Icons.favorite},
    {'id': 'mint', 'name': 'Menthe', 'icon': Icons.grass},
  ];

  final List<Color> _colors = [
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.indigo,
    Colors.green,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.displayName ?? '');
    _usernameController = TextEditingController(text: widget.profile?.username ?? '');
    _countryController = TextEditingController(text: widget.profile?.country ?? '');
    _quoteController = TextEditingController(text: widget.profile?.favoriteQuote ?? '');
    _selectedLanguage = widget.profile?.language;
    _selectedTimezone = widget.profile?.timezone;
    _selectedTheme = widget.profile?.theme;
    _selectedPrimaryColor = widget.profile?.primaryColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _countryController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ProfileService.updateProfile(
        displayName: _nameController.text.trim(),
        username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        language: _selectedLanguage,
        timezone: _selectedTimezone,
        favoriteQuote: _quoteController.text.trim().isEmpty ? null : _quoteController.text.trim(),
        theme: _selectedTheme,
        primaryColor: _selectedPrimaryColor,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil mis à jour !'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Avatar section
            _buildSection(
              title: 'Photo de profil',
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        backgroundImage: (widget.profile?.avatarUrl != null &&
                                widget.profile!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(widget.profile!.avatarUrl!)
                            : null,
                        child: (widget.profile?.avatarUrl == null ||
                                widget.profile!.avatarUrl!.isEmpty)
                            ? Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: Image picker
                    },
                    child: Text('Changer la photo'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Personal info section
            _buildSection(
              title: 'Informations personnelles',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Pseudo (optionnel)',
                    prefixIcon: Icon(Icons.alternate_email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _countryController,
                  decoration: InputDecoration(
                    labelText: 'Pays (optionnel)',
                    prefixIcon: Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Language & Timezone
            _buildSection(
              title: 'Préférences',
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: InputDecoration(
                    labelText: 'Langue',
                    prefixIcon: Icon(Icons.language),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _languages.map((lang) {
                    return DropdownMenuItem(
                      value: lang['code'],
                      child: Text(lang['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                  },
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedTimezone,
                  decoration: InputDecoration(
                    labelText: 'Fuseau horaire',
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _timezones.map((tz) {
                    return DropdownMenuItem(
                      value: tz['id'],
                      child: Text(tz['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTimezone = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),

            // Quote
            _buildSection(
              title: 'Citation favorite',
              children: [
                TextFormField(
                  controller: _quoteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Votre citation préférée (optionnel)',
                    prefixIcon: Icon(Icons.format_quote),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Theme selection
            _buildSection(
              title: 'Thème',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _themes.map((theme) {
                    final isSelected = _selectedTheme == theme['id'];
                    return ChoiceChip(
                      label: Text(theme['name']),
                      avatar: Icon(theme['icon'], size: 18),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTheme = theme['id'];
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Primary color
            _buildSection(
              title: 'Couleur principale',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colors.map((color) {
                    final isSelected = _selectedPrimaryColor == '#${color.value.toRadixString(16).substring(2)}';
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPrimaryColor = '#${color.value.toRadixString(16).substring(2)}';
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
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
                        child: isSelected ? Icon(Icons.check, color: Colors.white, size: 24) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
