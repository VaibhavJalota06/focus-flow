import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/widgets/social_brand_icons.dart';
import '../../core/widgets/user_avatar_widget.dart';
import '../navigation/main_navigation_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Animation Controllers for Welcome Page
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Auth Tab Controller
  late TabController _authTabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // Signup Controllers
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  bool _obscureSignupPassword = true;

  // Profile Edit Controllers
  late TextEditingController _nameController;
  int _dailyGoal = 5;
  String _selectedAvatar = '🚀';

  final List<String> _avatarOptions = [
    '🚀',
    '👨‍💻',
    '👩‍🎨',
    '⚡',
    '🌟',
    '🎯',
    '🦁',
    '🦊',
  ];

  @override
  void initState() {
    super.initState();
    _authTabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: 'Productive User');

    // Floating Hero Icon Animation
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Radiating Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial Staggered Entry Animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    _pageController.dispose();
    _authTabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(
          _loginEmailController.text.trim(),
          _loginPasswordController.text,
        );
    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _nameController.text = user.name;
      }
      _goToPage(2); // Move to Profile Setup
    }
  }

  Future<void> _handleSignUp() async {
    if (!_signupFormKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).signUp(
          _signupNameController.text.trim(),
          _signupEmailController.text.trim(),
          _signupPasswordController.text,
        );
    if (success && mounted) {
      _nameController.text = _signupNameController.text.trim();
      _goToPage(2); // Move to Profile Setup
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await ref.read(authProvider.notifier).signInWithGoogle();
    if (mounted) {
      final user = ref.read(authProvider).user;
      if (user != null && !user.isGuest) {
        // Automatically save profile info and enter app directly
        await ref.read(settingsProvider.notifier).updateUserName(user.name);
        await ref.read(settingsProvider.notifier).completeOnboarding();
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  Future<void> _handleSaveProfileAndFinish() async {
    final finalName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Productive User';

    final currentUser = ref.read(authProvider).user;
    final finalAvatar = _selectedAvatar.isNotEmpty
        ? _selectedAvatar
        : (currentUser?.avatarUrl ?? '🚀');

    await ref.read(authProvider.notifier).updateProfile(
          name: finalName,
          avatarUrl: finalAvatar,
        );
    await ref.read(settingsProvider.notifier).updateUserName(finalName);
    await ref.read(settingsProvider.notifier).updateDailyGoal(_dailyGoal);

    // Request permissions safely
    try {
      await [
        Permission.notification,
        Permission.microphone,
      ].request();
    } catch (e) {
      debugPrint('Permission request handled: $e');
    }

    // Complete onboarding and enter main app
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Reactively listen to live Supabase OAuth redirect & Google account token
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null && !next.user!.isGuest) {
        if (_nameController.text.isEmpty ||
            _nameController.text == 'Productive User' ||
            _nameController.text == 'Google User') {
          _nameController.text = next.user!.name;
        }
        if (next.user!.avatarUrl != null && next.user!.avatarUrl!.isNotEmpty) {
          setState(() {
            _selectedAvatar = next.user!.avatarUrl!;
          });
        }
        if (_currentPage == 1) {
          _goToPage(2);
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Step Progress Indicator (Hidden on Welcome Page)
            if (_currentPage > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step $_currentPage of 2',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        2,
                        (index) {
                          final isActive = (_currentPage - 1) == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildAnimatedWelcomeStep(theme),
                  _buildAuthStep(theme),
                  _buildProfileSetupStep(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 1: ANIMATED WELCOME PAGE
  // ==========================================
  Widget _buildAnimatedWelcomeStep(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Animated Hero Badge with Floating + Pulsing Glow
              AnimatedBuilder(
                animation: Listenable.merge([_floatingAnimation, _pulseAnimation]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatingAnimation.value),
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Center(
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Clean App Title
              Text(
                'Focus Flow',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Friendly Tagline & Subtitle
              Text(
                'Organize your day with effortless flow',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Stay focused, build daily streaks, and achieve your goals.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36),

              // Clean, friendly visual benefit cards
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    _buildBenefitRow(
                      theme,
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFFFF9F0A),
                      title: 'Quick Capture',
                      subtitle: 'Add tasks in seconds with text or voice',
                    ),
                    Divider(height: 1, indent: 56, endIndent: 20, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                    _buildBenefitRow(
                      theme,
                      icon: Icons.timer_rounded,
                      color: const Color(0xFF0A84FF),
                      title: 'Focus Timer',
                      subtitle: 'Work in distraction-free intervals',
                    ),
                    Divider(height: 1, indent: 56, endIndent: 20, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                    _buildBenefitRow(
                      theme,
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFFF453A),
                      title: 'Daily Streaks',
                      subtitle: 'Celebrate progress and stay consistent',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Modern "Get Started" CTA Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _goToPage(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: SIGN IN & SIGN UP PAGE
  // ==========================================
  Widget _buildAuthStep(ThemeData theme) {
    final authState = ref.watch(authProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Account Access',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in with Google to sync your tasks to the cloud, or use email.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Error Banner
          if (authState.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                authState.errorMessage!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13),
              ),
            ),

          // Primary Social Auth Button (Google)
          OutlinedButton(
            onPressed: authState.isLoading ? null : _handleGoogleSignIn,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              backgroundColor: theme.colorScheme.surface,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GoogleLogo(size: 22),
                SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
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

          // Sign In / Sign Up Segmented Tabs
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _authTabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              tabs: const [
                Tab(text: 'Sign In'),
                Tab(text: 'Sign Up'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Auth Form Views with dynamic sizing
          AnimatedBuilder(
            animation: _authTabController,
            builder: (context, _) {
              if (_authTabController.index == 0) {
                return _buildLoginForm(theme, authState.isLoading);
              } else {
                return _buildSignUpForm(theme, authState.isLoading);
              }
            },
          ),
          const SizedBox(height: 24),
        ],
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
              if (val == null || val.trim().isEmpty) return 'Enter email';
              if (!val.contains('@')) return 'Enter valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
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
              if (val == null || val.trim().isEmpty) return 'Enter password';
              if (val.trim().length < 6) return 'At least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 18),
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
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sign In & Continue',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
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
              if (val == null || val.trim().isEmpty) return 'Enter your name';
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _signupEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter email';
              if (!val.contains('@')) return 'Enter valid email';
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _signupPasswordController,
            obscureText: _obscureSignupPassword,
            decoration: InputDecoration(
              labelText: 'Password',
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
              if (val == null || val.trim().isEmpty) return 'Create password';
              if (val.trim().length < 6) return 'At least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
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
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Create Account & Continue',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        setState(() {
          _selectedAvatar = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  // ==========================================
  // STEP 3: USER PROFILE EDIT (PHOTO & NAME)
  // ==========================================
  Widget _buildProfileSetupStep(ThemeData theme) {
    final authState = ref.watch(authProvider);
    final hasPhoto = _selectedAvatar.startsWith('http') ||
        _selectedAvatar.contains('/') ||
        _selectedAvatar.contains('\\');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Up Your Profile',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasPhoto
                ? 'Your profile photo is ready! You can change it or keep it.'
                : 'Choose your profile avatar and set your daily goals.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Selected Avatar Display with clickable Pencil badge
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: UserAvatarWidget(
                    avatarUrl: _selectedAvatar,
                    fallbackName: _nameController.text,
                    size: 90,
                    fontSize: 46,
                  ),
                ),
                GestureDetector(
                  onTap: _pickImageFromGallery,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Gallery Pick Button
          Center(
            child: OutlinedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.photo_library_rounded, size: 18),
              label: Text(
                hasPhoto ? 'Change Photo from Gallery' : 'Upload from Gallery',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Avatar Options Grid (Shown as alternatives)
          if (!hasPhoto || authState.user?.isGuest == true) ...[
            Text(
              'Or Choose an Avatar Emoji:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _avatarOptions.map((avatar) {
                final isSelected = _selectedAvatar == avatar;
                return InkWell(
                  onTap: () => setState(() => _selectedAvatar = avatar),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      avatar,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),

          // Full Name Input Field
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Display Name',
              hintText: 'Enter your name',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
            ),
          ),

          const SizedBox(height: 20),

          // Daily Target Slider
          Text(
            'Daily Task Target: $_dailyGoal tasks',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: _dailyGoal.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: '$_dailyGoal tasks',
            onChanged: (val) => setState(() => _dailyGoal = val.round()),
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _handleSaveProfileAndFinish,
            icon: const Icon(Icons.rocket_launch_rounded),
            label: const Text(
              'Save Profile & Enter App 🚀',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
            ),
          ),
        ],
      ),
    );
  }
}
