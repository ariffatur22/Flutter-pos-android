import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pos_kasir/core/constants/app_constants.dart';
import 'package:flutter_pos_kasir/core/theme/app_theme.dart';
import 'package:flutter_pos_kasir/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── Mode ────────────────────────────────────────────────────────────────────
  bool _isPinMode = true;
  String _enteredPin = '';

  // ── Email mode ───────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  // ── Shake animation ──────────────────────────────────────────────────────────
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onPinKey(String key) {
    if (_enteredPin.length >= AppConstants.pinLength) return;
    setState(() => _enteredPin += key);
    if (_enteredPin.length == AppConstants.pinLength) {
      _submitPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(
          () => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
    }
  }

  Future<void> _submitPin() async {
    final success =
        await ref.read(authProvider.notifier).loginWithPin(_enteredPin);
    if (!mounted) return;
    if (success) {
      context.go(AppConstants.routeHome);
    } else {
      _shakeCtrl.forward(from: 0);
      setState(() => _enteredPin = '');
    }
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref
        .read(authProvider.notifier)
        .loginWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (success) {
      context.go(AppConstants.routeHome);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= AppConstants.breakpointDesktop;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
              child: Padding(
                padding: EdgeInsets.all(isWide ? 40 : 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 24),
                    _buildModeToggle(),
                    const SizedBox(height: 28),
                    if (_isPinMode)
                      _buildPinSection(auth)
                    else
                      _buildEmailSection(auth),
                    if (auth.error != null) ...[
                      const SizedBox(height: 12),
                      _buildErrorBanner(auth.error!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6))
            ],
          ),
          child: const Icon(Icons.point_of_sale, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 14),
        Text(AppConstants.appName, style: AppTheme.heading2),
        const SizedBox(height: 4),
        Text('Point of Sale Kasir', style: AppTheme.caption),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
              child: _toggleBtn('Login Kasir (PIN)', true,
                  icon: Icons.dialpad_rounded)),
          Expanded(
              child: _toggleBtn('Login Admin', false,
                  icon: Icons.admin_panel_settings_outlined)),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool isPin, {required IconData icon}) {
    final isActive = _isPinMode == isPin;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPinMode = isPin;
          _enteredPin = '';
          ref.read(authProvider.notifier).clearError();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: isActive ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: AppTheme.caption.copyWith(
                    color: isActive ? Colors.white : AppTheme.textSecondary,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildPinSection(AuthState auth) {
    return Column(
      children: [
        Text('Masukkan PIN ${AppConstants.pinLength} digit',
            style: AppTheme.body2.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) {
            final offset = math.sin(_shakeAnim.value * math.pi * 4) * 10;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: _buildPinDots(),
        ),
        const SizedBox(height: 28),
        _buildNumpad(auth.isLoading),
        const SizedBox(height: 12),
        TextButton(
          onPressed: auth.isLoading
              ? null
              : () => context.go(AppConstants.routeRegister),
          child: const Text('Belum punya akun? Daftar sekarang'),
        ),
      ],
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(AppConstants.pinLength, (i) {
        final filled = i < _enteredPin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppTheme.primaryColor : Colors.transparent,
            border: Border.all(
                color: filled ? AppTheme.primaryColor : AppTheme.dividerColor,
                width: 2),
          ),
        );
      }),
    );
  }

  Widget _buildNumpad(bool isLoading) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      );
    }
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: keys.map((row) {
        return Row(
          children: row.map((key) {
            if (key.isEmpty) return const Expanded(child: SizedBox());
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Material(
                  color: key == '⌫'
                      ? AppTheme.errorColor.withOpacity(0.1)
                      : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    onTap: () => key == '⌫' ? _onBackspace() : _onPinKey(key),
                    child: SizedBox(
                      height: 56,
                      child: Center(
                        child: key == '⌫'
                            ? Icon(Icons.backspace_outlined,
                                color: AppTheme.errorColor)
                            : Text(key,
                                style: AppTheme.heading3
                                    .copyWith(color: AppTheme.primaryColor)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildEmailSection(AuthState auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Admin',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: auth.isLoading ? null : _submitEmail,
              icon: auth.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login),
              label:
                  Text(auth.isLoading ? 'Memproses...' : 'Login sebagai Admin'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(error,
                  style: AppTheme.caption.copyWith(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
