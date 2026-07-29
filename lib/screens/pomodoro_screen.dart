import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with SingleTickerProviderStateMixin {
  static const _workSeconds = 25 * 60;
  static const _breakSeconds = 5 * 60;

  int _remaining = _workSeconds;
  bool _isRunning = false;
  bool _isWork = true;
  int _completedCount = 0;
  Timer? _timer;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: _workSeconds));
  }

  String get _timeText {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _toggleTimer() {
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _animCtrl.stop();
        _isRunning = false;
      } else {
        _isRunning = true;
        _animCtrl.duration = Duration(seconds: _remaining);
        _animCtrl.forward(from: 0);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            if (_remaining > 0) {
              _remaining--;
            } else {
              _timer?.cancel();
              _isRunning = false;
              if (_isWork) {
                _completedCount++;
                setState(() { _isWork = false; _remaining = _breakSeconds; });
              } else {
                setState(() { _isWork = true; _remaining = _workSeconds; });
              }
              _animCtrl.reset();
            }
          });
        });
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() { _isRunning = false; _isWork = true; _remaining = _workSeconds; });
    _animCtrl.reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = _isWork ? (_workSeconds - _remaining) / _workSeconds : (_breakSeconds - _remaining) / _breakSeconds;
    final color = _isWork ? Colors.redAccent : Colors.green;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('番茄专注'), centerTitle: true, elevation: 0),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 220, height: 220, child: CircularProgressIndicator(value: pct, strokeWidth: 8, color: color)),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isWork ? '🍅 专注' : '☕ 休息', style: TextStyle(fontSize: 16, color: color)),
                  const SizedBox(height: 8),
                  Text(_timeText, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _toggleTimer,
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? '暂停' : '开始'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh), label: const Text('重置')),
            ],
          ),
          const SizedBox(height: 30),
          Text('✅ 今日完成 $_completedCount 个番茄', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
