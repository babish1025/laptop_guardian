import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/device_service.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  String? _pairingCode;
  DateTime? _expiresAt;
  bool _isLoading = false;
  String? _error;
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final deviceService = context.read<DeviceService>();
      final res = await deviceService.generatePairingCode();

      if (!mounted) return;

      if (res['success'] == true) {
        final code = (res['code'] ?? res['pairing_code']) as String?;
        final expStr = res['expires_at'] as String?;
        DateTime? exp;
        if (expStr != null) {
          exp = DateTime.tryParse(expStr)?.toLocal();
        }

        setState(() {
          _pairingCode = code;
          _expiresAt = exp ?? DateTime.now().add(const Duration(minutes: 10));
          _timeLeft = _expiresAt!.difference(DateTime.now());
          _isLoading = false;
        });

        _startCountdown();
      } else {
        setState(() {
          _error = res['error'] as String? ?? 'Failed to generate pairing code.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error connecting to server: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expiresAt == null) return;
      final diff = _expiresAt!.difference(DateTime.now());
      if (diff.isNegative) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _timeLeft = Duration.zero;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _timeLeft = diff;
          });
        }
      }
    });
  }

  void _copyCode() {
    if (_pairingCode == null) return;
    Clipboard.setData(ClipboardData(text: _pairingCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pairing code copied to clipboard!'),
        backgroundColor: AppTheme.online,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _timeLeft.inMinutes;
    final seconds = _timeLeft.inSeconds % 60;
    final isExpired = _pairingCode != null && _timeLeft.inSeconds <= 0;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Pair New Laptop'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code_2_rounded,
                      color: AppTheme.accent,
                      size: 40,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Pairing Code',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(color: AppTheme.accent),
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.offline),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      // Code Display Container
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.bgElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isExpired
                                ? AppTheme.offline
                                : AppTheme.accent.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          isExpired ? 'EXPIRED' : (_pairingCode ?? '------'),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                            color: isExpired
                                ? AppTheme.offline
                                : AppTheme.accent,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Countdown timer
                      if (!isExpired)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Expires in ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Buttons row: Copy & Refresh
                      Row(
                        children: [
                          if (!isExpired && _pairingCode != null) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.accent,
                                  side: const BorderSide(color: AppTheme.accent),
                                  minimumSize: const Size.fromHeight(44),
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                label: const Text('Copy Code'),
                                onPressed: _copyCode,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isExpired ? AppTheme.accent : AppTheme.bgElevated,
                                foregroundColor: isExpired ? Colors.black : AppTheme.textPrimary,
                                minimumSize: const Size.fromHeight(44),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('New Code'),
                              onPressed: _generateCode,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Instructions
              const Text(
                'How to pair your laptop',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              _buildInstructionStep(
                number: '1',
                title: 'Open Terminal on your Laptop',
                body: 'Navigate to your Laptop Guardian folder in PowerShell or Command Prompt.',
              ),
              _buildInstructionStep(
                number: '2',
                title: 'Run the Pairing Script',
                body: 'In your terminal, run:\npython register_device.py',
              ),
              _buildInstructionStep(
                number: '3',
                title: 'Enter the 6-Digit Code',
                body: 'When prompted by the terminal, enter the code shown above.',
              ),
              _buildInstructionStep(
                number: '4',
                title: 'Done!',
                body: 'Your laptop will securely link to your account and appear in your dashboard.',
                isLast: true,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required String number,
    required String title,
    required String body,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.accent,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
