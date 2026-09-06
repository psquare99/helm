import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../../domain/models/github_device_code.dart';
import '../state/project_manager_controller.dart';

/// Modal dialog that implements GitHub OAuth Device Authorization Flow (RFC 8628).
/// Guides users through authorizing via github.com/login/device without any secrets.
class GitHubDeviceLoginDialog extends StatefulWidget {
  final ProjectManagerController controller;

  const GitHubDeviceLoginDialog({super.key, required this.controller});

  static Future<bool?> show(BuildContext context, ProjectManagerController controller) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GitHubDeviceLoginDialog(controller: controller),
    );
  }

  @override
  State<GitHubDeviceLoginDialog> createState() => _GitHubDeviceLoginDialogState();
}

class _GitHubDeviceLoginDialogState extends State<GitHubDeviceLoginDialog>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isLoading = true;
  String? _errorMessage;
  GitHubDeviceCode? _deviceCode;
  bool _isSuccess = false;
  String? _authenticatedUserLogin;
  int _secondsRemaining = 900;
  int _currentInterval = 5;
  Timer? _countdownTimer;
  bool _isPolling = false;
  bool _isCheckingNow = false;
  bool _copied = false;
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initDeviceFlow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _isPolling = false;
    _pulseAnim.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _deviceCode != null && !_isSuccess) {
      // User returned from browser; immediately verify authorization!
      _pollOnce();
    }
  }

  Future<void> _initDeviceFlow() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSuccess = false;
      _copied = false;
    });

    final code = await widget.controller.gitHubService.requestDeviceCode();
    if (!mounted) return;

    if (code == null || code.userCode.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not request device authorization from GitHub. Check your network connection.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _deviceCode = code;
      _secondsRemaining = code.expiresIn;
      _currentInterval = code.interval > 0 ? code.interval : 5;
    });

    // Automatically copy code to clipboard for user convenience
    await Clipboard.setData(ClipboardData(text: code.userCode));
    if (mounted) setState(() => _copied = true);

    _startCountdown();
    _startPolling(code);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _errorMessage = 'Authorization code expired. Please request a new code.';
          _isPolling = false;
        });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _startPolling(GitHubDeviceCode code) async {
    _isPolling = true;
    _currentInterval = code.interval > 0 ? code.interval : 5;

    while (_isPolling && mounted) {
      await Future.delayed(Duration(seconds: _currentInterval));
      if (!_isPolling || !mounted) break;

      await _pollOnce();
    }
  }

  Future<void> _pollOnce() async {
    if (_deviceCode == null || _isSuccess || !mounted || _isCheckingNow) return;
    setState(() => _isCheckingNow = true);

    try {
      final res = await widget.controller.gitHubService.pollDeviceToken(
        deviceCode: _deviceCode!.deviceCode,
      );

      if (!mounted) return;

      if (res.status == GitHubTokenStatus.success && res.accessToken != null) {
        _countdownTimer?.cancel();
        _isPolling = false;

        // Fully log in with token so profile, avatar, and telemetry load
        await widget.controller.loginWithGitHubToken(res.accessToken!);

        if (!mounted) return;

        setState(() {
          _isSuccess = true;
          _authenticatedUserLogin = widget.controller.currentUser?.login;
        });

        // Show success briefly then close
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else if (res.status == GitHubTokenStatus.slowDown) {
        _currentInterval += 5;
      } else if (res.status == GitHubTokenStatus.accessDenied) {
        _countdownTimer?.cancel();
        _isPolling = false;
        setState(() {
          _errorMessage = 'Authorization was cancelled on GitHub.';
        });
      } else if (res.status == GitHubTokenStatus.expired) {
        _countdownTimer?.cancel();
        _isPolling = false;
        setState(() {
          _errorMessage = 'Authorization code expired. Please request a new code.';
        });
      }
      // If pending or transient network hiccup, keep polling without dying!
    } finally {
      if (mounted) {
        setState(() => _isCheckingNow = false);
      }
    }
  }

  Future<void> _copyAndOpen() async {
    if (_deviceCode == null) return;
    await Clipboard.setData(ClipboardData(text: _deviceCode!.userCode));
    if (mounted) setState(() => _copied = true);

    final uri = Uri.parse(_deviceCode!.verificationUri);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {}
    }
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CommandColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isSuccess) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: CommandColors.signalEmerald.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: CommandColors.signalEmerald, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Successfully Connected!',
            style: TextStyle(
              fontFamily: CommandTheme.fontSans,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CommandColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _authenticatedUserLogin != null
                ? 'Signed in as @$_authenticatedUserLogin'
                : 'GitHub account linked to Helm',
            style: const TextStyle(
              fontFamily: CommandTheme.fontMono,
              fontSize: 13,
              color: CommandColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    if (_isLoading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24),
          CircularProgressIndicator(strokeWidth: 2, color: CommandColors.signalIce),
          SizedBox(height: 20),
          Text(
            'Requesting device code from GitHub...',
            style: TextStyle(
              fontFamily: CommandTheme.fontMono,
              fontSize: 13,
              color: CommandColors.textSecondary,
            ),
          ),
          SizedBox(height: 24),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: CommandColors.signalCoral, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Authorization Failed',
                style: TextStyle(
                  fontFamily: CommandTheme.fontSans,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CommandColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontFamily: CommandTheme.fontSans,
              fontSize: 13.5,
              color: CommandColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _initDeviceFlow,
                style: FilledButton.styleFrom(
                  backgroundColor: CommandColors.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ],
      );
    }

    final code = _deviceCode!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CommandColors.surfaceRaised,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: CommandColors.borderSubtle),
              ),
              child: const Icon(Icons.hub_rounded, size: 18, color: CommandColors.signalIce),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Sign in with GitHub',
                style: TextStyle(
                  fontFamily: CommandTheme.fontSans,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CommandColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),

        const SizedBox(height: 16),

        const Text(
          '1. Go to github.com/login/device in your browser\n'
          '2. Enter the code below and tap Authorize',
          style: TextStyle(
            fontFamily: CommandTheme.fontSans,
            fontSize: 13,
            color: CommandColors.textSecondary,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 16),

        // Big Code Display Card
        InkWell(
          onTap: _copyAndOpen,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: CommandColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: CommandColors.signalIce.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  code.userCode,
                  style: const TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    color: CommandColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      size: 13,
                      color: _copied ? CommandColors.signalEmerald : CommandColors.signalIce,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _copied ? 'Code copied to clipboard!' : 'Tap to copy & open browser',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _copied ? CommandColors.signalEmerald : CommandColors.signalIce,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Primary Action: Copy & Open
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _copyAndOpen,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text(
              'OPEN GITHUB & AUTHORIZE',
              style: TextStyle(
                fontFamily: CommandTheme.fontMono,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: CommandColors.textPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Secondary Action: Immediate manual verification button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isCheckingNow ? null : _pollOnce,
            icon: _isCheckingNow
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: CommandColors.signalIce),
                  )
                : const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              _isCheckingNow ? 'VERIFYING WITH GITHUB...' : 'I\'VE AUTHORIZED — VERIFY NOW',
              style: const TextStyle(
                fontFamily: CommandTheme.fontMono,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: CommandColors.textPrimary,
              side: const BorderSide(color: CommandColors.borderMedium),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Polling Indicator
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isCheckingNow
                      ? CommandColors.signalIce
                      : CommandColors.signalAmber.withValues(alpha: 0.4 + (_pulseAnim.value * 0.6)),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isCheckingNow ? 'Verifying authorization...' : 'Waiting for approval in browser...',
              style: TextStyle(
                fontFamily: CommandTheme.fontMono,
                fontSize: 11,
                color: _isCheckingNow ? CommandColors.signalIce : CommandColors.textMuted,
              ),
            ),
            const Spacer(),
            Text(
              'Expires in ${_formatTimer(_secondsRemaining)}',
              style: const TextStyle(
                fontFamily: CommandTheme.fontMono,
                fontSize: 11,
                color: CommandColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
