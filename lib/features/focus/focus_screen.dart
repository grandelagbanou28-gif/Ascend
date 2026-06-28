import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ascend/data/models/focus_session.dart';
import 'package:ascend/core/services/focus_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  FocusMode _selectedMode = FocusMode.pomodoro25_5;
  AmbientSound _selectedSound = AmbientSound.none;
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  int _totalSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isWorkPhase = true;
  int _currentSession = 1;
  FocusSession? _currentSessionObj;

  @override
  void initState() {
    super.initState();
    _loadTodayStats();
    _remainingSeconds = _selectedMode.workMinutes * 60;
    _totalSeconds = _selectedMode.workMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTodayStats() async {
    await FocusService.loadSessions();
    setState(() {});
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    if (_currentSessionObj == null) {
      _currentSessionObj = FocusSession(
        mode: _selectedMode,
        sound: _selectedSound,
        plannedMinutes: _isWorkPhase
            ? _selectedMode.workMinutes
            : _selectedMode.breakMinutes,
      );
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          if (_isWorkPhase && _currentSessionObj != null) {
            final elapsedSeconds =
                _totalSeconds - _remainingSeconds;
            _currentSessionObj!.actualMinutes = elapsedSeconds ~/ 60;
          }
        } else {
          _timer?.cancel();
          _isRunning = false;
          _onPhaseComplete();
        }
      });
    });
  }

  void _onPhaseComplete() {
    if (_isWorkPhase) {
      if (_currentSessionObj != null) {
        _currentSessionObj!.status = FocusSessionStatus.completed;
        _currentSessionObj!.endTime = DateTime.now();
        _currentSessionObj!.xpEarned =
            FocusSession.calculateXp(_selectedMode, _currentSessionObj!.actualMinutes);
        FocusService.addSession(_currentSessionObj!);
      }
      _currentSession++;
      _showPhaseDialog(isWorkComplete: true);
    } else {
      _currentSessionObj = null;
      _showPhaseDialog(isWorkComplete: false);
    }
  }

  void _showPhaseDialog({required bool isWorkComplete}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(
          isWorkComplete ? 'Travail terminé !' : 'Pause terminée !',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isWorkComplete
              ? 'Bravo ! Vous avez gagné ${_currentSessionObj?.xpEarned ?? 0} XP'
              : 'Prêt pour la prochaine session ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetTimer();
            },
            child: const Text('Retour', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _switchPhase();
            },
            child: const Text('Continuer', style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }

  void _switchPhase() {
    setState(() {
      _isWorkPhase = !_isWorkPhase;
      if (_isWorkPhase) {
        _remainingSeconds = _selectedMode.workMinutes * 60;
        _totalSeconds = _selectedMode.workMinutes * 60;
      } else {
        _remainingSeconds = _selectedMode.breakMinutes * 60;
        _totalSeconds = _selectedMode.breakMinutes * 60;
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (_currentSessionObj != null) {
        _currentSessionObj!.status = FocusSessionStatus.paused;
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isWorkPhase = true;
      _currentSessionObj = null;
      _remainingSeconds = _selectedMode.workMinutes * 60;
      _totalSeconds = _selectedMode.workMinutes * 60;
    });
  }

  void _skipBreak() {
    if (!_isWorkPhase) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
        _isWorkPhase = true;
        _currentSessionObj = null;
        _remainingSeconds = _selectedMode.workMinutes * 60;
        _totalSeconds = _selectedMode.workMinutes * 60;
      });
    }
  }

  void _onModeChanged(FocusMode mode) {
    if (_isRunning) return;
    setState(() {
      _selectedMode = mode;
      _isWorkPhase = true;
      _remainingSeconds = mode.workMinutes * 60;
      _totalSeconds = mode.workMinutes * 60;
      _currentSession = 1;
      _currentSessionObj = null;
    });
  }

  void _onSoundChanged(AmbientSound sound) {
    setState(() {
      _selectedSound = sound;
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayMinutes = FocusService.getTodayTotalMinutes();
    final todayXp = FocusService.getTodayXpEarned();
    final progress = _totalSeconds > 0
        ? 1.0 - (_remainingSeconds / _totalSeconds)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Focus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildModeSelector(),
            const SizedBox(height: 24),
            _buildTimerDisplay(progress),
            const SizedBox(height: 24),
            _buildSoundSelector(),
            const SizedBox(height: 24),
            _buildControls(),
            const SizedBox(height: 24),
            _buildSessionInfo(todayMinutes, todayXp),
            const SizedBox(height: 24),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FocusMode.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final mode = FocusMode.values[index];
          final isSelected = _selectedMode == mode;
          return GestureDetector(
            onTap: () => _onModeChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF2A2A3E),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mode.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode == FocusMode.libre
                        ? 'Libre'
                        : '${mode.workMinutes}min/${mode.breakMinutes}min',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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

  Widget _buildTimerDisplay(double progress) {
    final String statusText = !_isWorkPhase && _selectedMode == FocusMode.libre
        ? 'Prêt'
        : _isWorkPhase
            ? 'Travail'
            : 'Pause';

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E1E2E),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 260,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: const Color(0xFF2A2A3E),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  color: _isWorkPhase
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF10B981),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedMode.description,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoundSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Son ambiant',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.9,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: AmbientSound.values.length,
          itemBuilder: (context, index) {
            final sound = AmbientSound.values[index];
            final isSelected = _selectedSound == sound;
            return GestureDetector(
              onTap: () => _onSoundChanged(sound),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF2A2A3E),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      sound.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sound.displayName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.refresh,
          label: 'Réinitialiser',
          onTap: _resetTimer,
        ),
        const SizedBox(width: 24),
        _buildMainPlayButton(),
        const SizedBox(width: 24),
        _buildControlButton(
          icon: Icons.skip_next,
          label: 'Sauter pause',
          onTap: !_isWorkPhase ? _skipBreak : null,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: onTap != null
                  ? const Color(0xFF1E1E2E)
                  : const Color(0xFF151520),
              shape: BoxShape.circle,
              border: Border.all(
                color: onTap != null
                    ? const Color(0xFF2A2A3E)
                    : const Color(0xFF1A1A28),
              ),
            ),
            child: Icon(
              icon,
              color: onTap != null ? Colors.white54 : Colors.white24,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: onTap != null ? Colors.white54 : Colors.white24,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPlayButton() {
    return GestureDetector(
      onTap: _isRunning ? _pauseTimer : _startTimer,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _isRunning ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildSessionInfo(int todayMinutes, int todayXp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.play_circle_outline,
            label: 'Session actuelle',
            value: '$_currentSession',
          ),
          const Divider(color: Color(0xFF2A2A3E), height: 24),
          _buildInfoRow(
            icon: Icons.timer_outlined,
            label: 'Temps total aujourd\'hui',
            value: '${todayMinutes}min',
          ),
          const Divider(color: Color(0xFF2A2A3E), height: 24),
          _buildInfoRow(
            icon: Icons.star_outline,
            label: 'XP gagnés aujourd\'hui',
            value: '$todayXp',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7C3AED), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Historique',
            icon: Icons.history,
            onTap: () {
              Navigator.pushNamed(context, '/focus/history');
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            label: 'Statistiques',
            icon: Icons.bar_chart,
            onTap: () {
              Navigator.pushNamed(context, '/focus/stats');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF7C3AED), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
