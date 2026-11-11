import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_button.dart';

class EditProfilScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  /// Callback appelé après une sauvegarde réussie avec l'utilisateur rafraîchi.
  final void Function(Map<String, dynamic> updatedUser)? onSaved;

  const EditProfilScreen({
    super.key,
    required this.user,
    this.onSaved,
  });

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _nameCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _specialiteCtrl = TextEditingController();
  final _ancienMdpCtrl = TextEditingController();
  final _nouveauMdpCtrl = TextEditingController();
  final _confirmMdpCtrl = TextEditingController();

  bool _loadingProfil = false;
  bool _loadingMdp = false;
  bool _showChangerMdp = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.user['name'] ?? '';
    _telephoneCtrl.text = widget.user['telephone'] ?? '';
    _adresseCtrl.text = widget.user['adresse'] ?? '';
    _specialiteCtrl.text = widget.user['specialite'] ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _telephoneCtrl.dispose();
    _adresseCtrl.dispose();
    _specialiteCtrl.dispose();
    _ancienMdpCtrl.dispose();
    _nouveauMdpCtrl.dispose();
    _confirmMdpCtrl.dispose();
    super.dispose();
  }

  String get _userId =>
      (widget.user['id'] ?? widget.user['uid'] ?? '').toString();
  bool get _isPediatre =>
      (widget.user['role'] ?? '').toString().toLowerCase() == 'pediatre';

  // ── Sauvegarde profil ──────────────────────────────────────────────────────
  Future<void> _sauvegarderProfil() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Le nom est obligatoire.');
      return;
    }
    setState(() => _loadingProfil = true);
    final err = await AuthService.updateProfil(
      userId: _userId,
      name: name,
      telephone: _telephoneCtrl.text.trim().isEmpty
          ? null
          : _telephoneCtrl.text.trim(),
      adresse: _adresseCtrl.text.trim().isEmpty
          ? null
          : _adresseCtrl.text.trim(),
      specialite: _isPediatre && _specialiteCtrl.text.trim().isNotEmpty
          ? _specialiteCtrl.text.trim()
          : null,
    );
    if (!mounted) return;
    setState(() => _loadingProfil = false);

    if (err != null) {
      _showError(err);
    } else {
      final updated = await AuthService.getLoggedInUser();
      _showSuccess('Profil mis à jour avec succès.');
      if (updated != null) widget.onSaved?.call(updated);
    }
  }

  // ── Changement mot de passe ────────────────────────────────────────────────
  Future<void> _changerMotDePasse() async {
    final ancien = _ancienMdpCtrl.text;
    final nouveau = _nouveauMdpCtrl.text;
    final confirm = _confirmMdpCtrl.text;

    if (ancien.isEmpty || nouveau.isEmpty || confirm.isEmpty) {
      _showError('Remplissez tous les champs de mot de passe.');
      return;
    }
    if (nouveau != confirm) {
      _showError('Les nouveaux mots de passe ne correspondent pas.');
      return;
    }
    if (nouveau.length < 6) {
      _showError('Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    setState(() => _loadingMdp = true);
    final err = await AuthService.changerMotDePasse(
      userId: _userId,
      ancienMdp: ancien,
      nouveauMdp: nouveau,
    );
    if (!mounted) return;
    setState(() => _loadingMdp = false);

    if (err != null) {
      _showError(err);
    } else {
      _ancienMdpCtrl.clear();
      _nouveauMdpCtrl.clear();
      _confirmMdpCtrl.clear();
      setState(() => _showChangerMdp = false);
      _showSuccess('Mot de passe modifié.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final initials = (_nameCtrl.text.isNotEmpty
            ? _nameCtrl.text[0]
            : (widget.user['name'] ?? 'U').toString()[0])
        .toUpperCase();
    final roleLabel = _isPediatre ? 'Pédiatre' : 'Parent';
    final roleEmoji = _isPediatre ? '👨‍⚕️' : '👨‍👩‍👦';

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Avatar ──────────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 88, height: 88,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: AppColors.buttonGradient),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x441E6FDB),
                                      blurRadius: 20,
                                      offset: Offset(0, 8)),
                                ],
                              ),
                              child: Center(
                                child: Text(initials,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(roleEmoji,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(roleLabel,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user['email'] ?? '',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Infos personnelles ──────────────────────────────
                      _sectionLabel('Informations personnelles'),
                      const SizedBox(height: 10),
                      _buildField(
                        hint: _isPediatre ? 'Dr. Nom complet' : 'Nom complet',
                        icon: _isPediatre
                            ? Icons.medical_services_outlined
                            : Icons.person_outline_rounded,
                        ctrl: _nameCtrl,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        hint: 'Téléphone',
                        icon: Icons.phone_outlined,
                        ctrl: _telephoneCtrl,
                        keyboard: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        hint: 'Adresse',
                        icon: Icons.location_on_outlined,
                        ctrl: _adresseCtrl,
                      ),
                      if (_isPediatre) ...[
                        const SizedBox(height: 12),
                        _buildField(
                          hint: 'Spécialité (ex. Pédiatrie générale)',
                          icon: Icons.local_hospital_outlined,
                          ctrl: _specialiteCtrl,
                        ),
                      ],
                      const SizedBox(height: 20),
                      GradientButton(
                        label: 'Enregistrer le profil',
                        onTap: _sauvegarderProfil,
                        loading: _loadingProfil,
                      ),

                      const SizedBox(height: 28),
                      _buildDivider(),
                      const SizedBox(height: 20),

                      // ── Changement mot de passe ─────────────────────────
                      GestureDetector(
                        onTap: () => setState(
                            () => _showChangerMdp = !_showChangerMdp),
                        child: Row(
                          children: [
                            const Text('🔑',
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Changer le mot de passe',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _showChangerMdp ? 0.25 : 0,
                              duration:
                                  const Duration(milliseconds: 200),
                              child: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary,
                                  size: 22),
                            ),
                          ],
                        ),
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 280),
                        crossFadeState: _showChangerMdp
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildField(
                              hint: 'Mot de passe actuel',
                              icon: Icons.lock_outline_rounded,
                              ctrl: _ancienMdpCtrl,
                              obscure: true,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              hint: 'Nouveau mot de passe',
                              icon: Icons.lock_reset_rounded,
                              ctrl: _nouveauMdpCtrl,
                              obscure: true,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              hint: 'Confirmer le nouveau mot de passe',
                              icon: Icons.lock_reset_rounded,
                              ctrl: _confirmMdpCtrl,
                              obscure: true,
                            ),
                            const SizedBox(height: 16),
                            GradientButton(
                              label: 'Changer le mot de passe',
                              onTap: _changerMotDePasse,
                              loading: _loadingMdp,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Infos compte (lecture seule) ─────────────────────
                      _sectionLabel('Mon compte'),
                      const SizedBox(height: 10),
                      _buildInfoTile(
                          '📧', 'Email', widget.user['email'] ?? '—'),
                      const SizedBox(height: 8),
                      _buildInfoTile('🎭', 'Rôle', roleLabel),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mon profil',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              Text('Modifier vos informations',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5));
  }

  Widget _buildField({
    required String hint,
    required IconData icon,
    required TextEditingController ctrl,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) {
    return _ObscurableField(
      hint: hint,
      icon: icon,
      ctrl: ctrl,
      keyboard: keyboard,
      obscure: obscure,
    );
  }

  Widget _buildInfoTile(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10)),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
            child: Container(height: 1, color: AppColors.glassBorder)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Sécurité',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ),
        Expanded(
            child: Container(height: 1, color: AppColors.glassBorder)),
      ],
    );
  }
}

// ── Champ avec toggle obscure ─────────────────────────────────────────────────
class _ObscurableField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final TextEditingController ctrl;
  final TextInputType keyboard;
  final bool obscure;

  const _ObscurableField({
    required this.hint,
    required this.icon,
    required this.ctrl,
    required this.keyboard,
    required this.obscure,
  });

  @override
  State<_ObscurableField> createState() => _ObscurableFieldState();
}

class _ObscurableFieldState extends State<_ObscurableField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: widget.ctrl,
        obscureText: widget.obscure && _hidden,
        keyboardType: widget.keyboard,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
              color: AppColors.textSecondary, fontSize: 15),
          prefixIcon:
              Icon(widget.icon, color: AppColors.textSecondary, size: 20),
          suffixIcon: widget.obscure
              ? IconButton(
                  icon: Icon(
                    _hidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _hidden = !_hidden),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
