import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/widgets/social_brand_icons.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthScreen({super.key, this.onAuthSuccess});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Signup Controllers
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final nav = Navigator.of(context);

    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.login(
      _loginEmailController.text.trim(),
      _loginPasswordController.text,
    );

    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        await ref.read(settingsProvider.notifier).updateUserName(user.name);
        await ref.read(settingsProvider.notifier).completeOnboarding();
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${user?.name ?? 'User'}! 👋'),
          backgroundColor: primaryColor,
        ),
      );
      if (widget.onAuthSuccess != null) {
        widget.onAuthSuccess!();
      } else {
        nav.pop();
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (!_signupFormKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final nav = Navigator.of(context);

    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.signUp(
      _signupNameController.text.trim(),
      _signupEmailController.text.trim(),
      _signupPasswordController.text,
    );

    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        await ref.read(settingsProvider.notifier).updateUserName(user.name);
        await ref.read(settingsProvider.notifier).completeOnboarding();
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Account created! Welcome, ${user?.name ?? 'User'}! 🚀'),
          backgroundColor: primaryColor,
        ),
      );
      if (widget.onAuthSuccess != null) {
        widget.onAuthSuccess!();
      } else {
        nav.pop();
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final messenger = ScaffoldMessenger.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final nav = Navigator.of(context);

    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.signInWithGoogle();
    if (mounted) {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user != null && !user.isGuest) {
        await ref.read(settingsProvider.notifier).updateUserName(user.name);
        await ref.read(settingsProvider.notifier).completeOnboarding();
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('Signed in with Google! Welcome, ${user.name}! 🌟'),
            backgroundColor: primaryColor,
          ),
        );
        if (widget.onAuthSuccess != null) {
          widget.onAuthSuccess!();
        } else {
          nav.pop();
        }
      } else if (!success && authState.errorMessage != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    // Reactively listen to live Supabase OAuth redirect & Google account token
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null && !next.user!.isGuest) {
        ref.read(settingsProvider.notifier).updateUserName(next.user!.name);
        if (widget.onAuthSuccess != null) {
          widget.onAuthSuccess!();
        } else {
          Navigator.of(context).pop();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Access'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Branding Header
              Center(
                child: Column(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Focus Flow',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to sync your tasks and track your streaks',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error Banner
              if (authState.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Social Auth Button (Google)
              OutlinedButton(
                onPressed: authState.isLoading ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  backgroundColor: theme.colorScheme.surface,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GoogleLogo(size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Quick 1-Tap Instant Access Button
              FilledButton.tonalIcon(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        await ref.read(authProvider.notifier).continueAsGuest();
                        if (widget.onAuthSuccess != null) {
                          widget.onAuthSuccess!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: const Text(
                  '⚡ Quick Instant Access (Offline Mode)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR USE EMAIL',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Tab Bar Container
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form Area
              SizedBox(
                height: 320,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoginForm(theme, authState.isLoading),
                    _buildSignUpForm(theme, authState.isLoading),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(ThemeData theme, bool isLoading) {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter your email';
              if (!val.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscureLoginPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter your password';
              if (val.trim().length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Sign In',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(ThemeData theme, bool isLoading) {
    return Form(
      key: _signupFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _signupNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter your full name';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _signupEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter your email';
              if (!val.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _signupPasswordController,
            obscureText: _obscureSignupPassword,
            decoration: InputDecoration(
              labelText: 'Create Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscureSignupPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscureSignupPassword = !_obscureSignupPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Create a password';
              if (val.trim().length < 6) return 'At least 6 characters required';
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : _handleSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}
