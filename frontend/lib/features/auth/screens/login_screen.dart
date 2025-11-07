import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/auth_provider.dart';

/// A premium, responsive login screen designed for Flutter Web (desktop-first)
/// - Two-column split on wide viewports (immersive branding on left, form on right)
/// - Collapses to a centered single-column layout on narrow screens
/// - Animated left-panel background using a lightweight CustomPainter
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.black87,
      ),
    );
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Use your Riverpod auth provider here.
      // The project already has an auth provider in core/providers/auth_provider.dart.
      final auth = ref.read(authServiceProvider);
      // Expectation: signInWithEmail returns a user or null (adapt as needed)
      final user = await auth.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);
      if (user == null) {
        _showMessage('Login failed — check your credentials.', isError: true);
      } else {
        _showMessage('Welcome back!');
        // Navigation happens via app router/state — do not navigate here unless desired.
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Login error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _onGoogleSignInPressed() async {
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      final user = await auth.signInWithGoogle();
      setState(() => _isLoading = false);
      if (user == null) {
        _showMessage('Google Sign-In failed.', isError: true);
      } else {
        _showMessage('Signed in with Google');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Google sign-in error: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3740FF);
    const accent = Color(0xFF00C2A8);
    const background = Color(0xFFF6F7FB);
    const muted = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= 900;

            if (isWide) {
              return Row(
                children: [
                  // Left: branding + animated background
                  Expanded(
                    child: Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: Size.infinite,
                              painter: _AnimatedBackgroundPainter(
                                progress: _animationController.value,
                                primary: primary,
                                accent: accent,
                              ),
                            );
                          },
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 64.0,
                              vertical: 48.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top-left logo and brand name
                                Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(
                                          (0.16 * 255).round(),
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(
                                              (0.08 * 255).round(),
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'CV',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'CourseVerse',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 48.0,
                                    right: 40,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Your Future, Redefined.',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 44,
                                          height: 1.02,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: 520,
                                        child: Text(
                                          'A next-generation learning platform that connects ambitious learners with industry-leading content, mentors, and projects. Beautiful learning starts here.',
                                          style: TextStyle(
                                            color: Colors.white.withAlpha(
                                              (0.9 * 255).round(),
                                            ),
                                            fontSize: 16,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      ElevatedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.lightbulb_outline,
                                          color: Colors.black,
                                        ),
                                        label: const Text('Explore Courses'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 20,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right: login form
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40.0,
                          vertical: 48.0,
                        ),
                        child: Card(
                          elevation: 18,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: _buildForm(primary, accent, muted),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Narrow screens: banner + centered card
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 36,
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: Size.infinite,
                              painter: _AnimatedBackgroundPainter(
                                progress: _animationController.value,
                                primary: primary,
                                accent: accent,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: _buildForm(primary, accent, muted),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildForm(Color primary, Color accent, Color muted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header: centered title and subtitle
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to continue to CourseVerse',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: muted),
            ),
            const SizedBox(height: 20),
          ],
        ),

        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  labelText: 'Email address',
                  hintText: 'you@domain.com',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onLoginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Login'),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: Colors.black54)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _onGoogleSignInPressed,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Image.asset(
                          'assets/images/google_g.png',
                          width: 32,
                          height: 32,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.g_translate,
                                size: 28,
                                color: Colors.redAccent,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Sign in with Google',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lightweight animated background painter used in the branding column.
class _AnimatedBackgroundPainter extends CustomPainter {
  final double progress; // 0.0..1.0 loop
  final Color primary;
  final Color accent;

  _AnimatedBackgroundPainter({
    required this.progress,
    required this.primary,
    required this.accent,
  }) : super(repaint: AlwaysStoppedAnimation(progress));

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradientColor1 = primary.withAlpha((0.95 * 255).round());
    final lerped = Color.lerp(primary, accent, 0.9)!;
    final gradientColor2 = lerped.withAlpha((0.9 * 255).round());
    final gradient = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [
      gradientColor1,
      gradientColor2,
    ]);

    final paint = Paint()..shader = gradient;
    canvas.drawRect(rect, paint);

    final blobPaint = Paint()..blendMode = BlendMode.plus;
    final blobs = [
      _BlobConfig(radius: size.shortestSide * 0.28, speed: 0.18, seed: 1),
      _BlobConfig(radius: size.shortestSide * 0.16, speed: 0.32, seed: 2),
      _BlobConfig(radius: size.shortestSide * 0.10, speed: 0.48, seed: 3),
      _BlobConfig(radius: size.shortestSide * 0.06, speed: 0.36, seed: 4),
    ];

    for (var i = 0; i < blobs.length; i++) {
      final b = blobs[i];
      final t = (progress * (1 + b.speed) + (b.seed * 0.23)) % 1.0;
      final dx = size.width * (0.3 + 0.4 * sin(2 * pi * t + b.seed));
      final dy = size.height * (0.3 + 0.35 * cos(2 * pi * t * (1.0 + b.speed)));
      final base = (i % 2 == 0 ? Colors.white : accent);
      final op = 0.08 + 0.04 * sin(2 * pi * t);
      final color = base.withAlpha((op * 255).clamp(0, 255).round());
      blobPaint.color = color;
      canvas.drawCircle(Offset(dx, dy), b.radius, blobPaint);
    }

    final dotPaint = Paint()
      ..color = Colors.white.withAlpha((0.02 * 255).round());
    final step = size.shortestSide * 0.06;
    for (double y = 0; y < size.height; y += step * 1.6) {
      for (double x = 0; x < size.width; x += step * 1.6) {
        final jitter = 2.0 * sin(progress * pi * 2 + x * 0.01);
        canvas.drawCircle(Offset(x + jitter, y + jitter), 0.9, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedBackgroundPainter old) =>
      old.progress != progress ||
      old.primary != primary ||
      old.accent != accent;
}

class _BlobConfig {
  final double radius;
  final double speed;
  final int seed;
  _BlobConfig({required this.radius, required this.speed, required this.seed});
}
