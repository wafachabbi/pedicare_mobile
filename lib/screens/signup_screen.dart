import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/gradient_button.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _agreedToTerms = false;
  String _selectedRole = 'parent';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError('Veuillez remplir tous les champs.');
      return;
    }
    if (password != confirm) {
      _showError('Les mots de passe ne correspondent pas.');
      return;
    }
    if (!_agreedToTerms) {
      _showError("Veuillez accepter les conditions d'utilisation.");
      return;
    }

    setState(() => _loading = true);
    final error = await AuthService.signup(
      name: name,
      email: email,
      password: password,
      role: _selectedRole,
    );
    if (mounted) setState(() => _loading = false);

    if (error != null) {
      _showError(error);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Compte créé avec succès ! Connectez-vous.'),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildTopBar(context),
                    const SizedBox(height: 28),
                    _buildHeader(),
                    const SizedBox(height: 28),
                    _buildRoleSelector(),
                    const SizedBox(height: 28),
                    _buildForm(),
                    const SizedBox(height: 20),
                    _buildTermsCheckbox(),
                    const SizedBox(height: 28),
                    GradientButton(
                      label: 'Créer mon compte',
                      onTap: _signup,
                      loading: _loading,
                    ),
                    const SizedBox(height: 36),
                    _buildLoginLink(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Text('🩺', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFF4DAAFF)],
          ).createShader(bounds),
          child: const Text(
            'PediCare AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Créer un compte ✨',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Rejoignez PediCare AI pour un suivi\npédiatrique simplifié et intelligent.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Je suis un :',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RoleButton(
                emoji: '👨‍👩‍👦',
                label: 'Parent',
                selected: _selectedRole == 'parent',
                onTap: () => setState(() => _selectedRole = 'parent'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleButton(
                emoji: '👨‍⚕️',
                label: 'Pédiatre',
                selected: _selectedRole == 'pediatre',
                onTap: () => setState(() => _selectedRole = 'pediatre'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        GlassTextField(
          hint: _selectedRole == 'parent' ? 'Nom complet' : 'Dr. Nom complet',
          icon: _selectedRole == 'parent'
              ? Icons.person_outline_rounded
              : Icons.medical_services_outlined,
          controller: _nameController,
        ),
        const SizedBox(height: 16),
        GlassTextField(
          hint: 'Adresse email',
          icon: Icons.mail_outline_rounded,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        GlassTextField(
          hint: 'Mot de passe',
          icon: Icons.lock_outline_rounded,
          controller: _passwordController,
          obscure: true,
        ),
        const SizedBox(height: 16),
        GlassTextField(
          hint: 'Confirmer le mot de passe',
          icon: Icons.lock_outline_rounded,
          controller: _confirmController,
          obscure: true,
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              gradient: _agreedToTerms
                  ? const LinearGradient(colors: AppColors.buttonGradient)
                  : null,
              color: _agreedToTerms ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _agreedToTerms
                    ? Colors.transparent
                    : AppColors.glassBorder,
                width: 1.5,
              ),
            ),
            child: _agreedToTerms
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: const TextSpan(
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13),
              children: [
                TextSpan(text: "J'accepte les "),
                TextSpan(
                  text: 'Conditions d\'utilisation',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' et la '),
                TextSpan(
                  text: 'Politique de confidentialité',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Déjà un compte ? ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Se connecter',
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0x221E6FDB) : AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.glassBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    selected ? AppColors.secondary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
