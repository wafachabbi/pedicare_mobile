import 'package:flutter/material.dart';
import '../models/enfant_model.dart';
import '../services/auth_service.dart';
import '../services/enfant_service.dart';
import '../services/vaccin_service.dart';
import '../services/rendezvous_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'enfant/add_enfant_screen.dart';
import 'enfant/enfant_detail_screen.dart';
import 'notifications_screen.dart';

class HomeParentScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomeParentScreen({super.key, required this.user});

  @override
  State<HomeParentScreen> createState() => _HomeParentScreenState();
}

class _HomeParentScreenState extends State<HomeParentScreen> {
  List<EnfantModel> _enfants = [];
  bool _loading = true;
  int _notifCount = 0;

  @override
  void initState() {
    super.initState();
    _loadEnfants();
  }

  Future<void> _loadEnfants() async {
    setState(() => _loading = true);
    final parentId = (widget.user['id'] ?? widget.user['uid'] ?? '1').toString();
    final enfants = await EnfantService.getEnfants(parentId);
    if (mounted) {
      setState(() {
        _enfants = enfants;
        _loading = false;
      });
      _loadNotifCount(enfants);
    }
  }

  Future<void> _loadNotifCount(List<EnfantModel> enfants) async {
    int count = 0;
    for (final e in enfants) {
      final v = await VaccinService.getProchainesEcheances(e.id);
      final r = await RendezVousService.getProchains(e.id);
      count += v.length + r.length;
    }
    if (mounted) setState(() => _notifCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name'] ?? 'Parent';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    final parentId = (widget.user['id'] ?? widget.user['uid'] ?? '1').toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🩺', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Colors.white, Color(0xFF4DAAFF)],
                          ).createShader(b),
                          child: const Text('PediCare AI',
                              style: TextStyle(color: Colors.white,
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildBellBtn(context, parentId),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _logout(context),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: AppColors.buttonGradient),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Center(
                              child: Text(initials,
                                  style: const TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Banner
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E6FDB), Color(0xFF4DAAFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x441E6FDB), blurRadius: 20, offset: Offset(0, 8))
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bonjour, $name 👋',
                                style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 4),
                            const Text('Espace Parent',
                                style: TextStyle(color: Colors.white,
                                    fontSize: 22, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const Text('👨‍👩‍👦', style: TextStyle(fontSize: 50)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Section title + add button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mes enfants',
                        style: TextStyle(color: AppColors.textPrimary,
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AddEnfantScreen(parentId: parentId),
                        ));
                        _loadEnfants();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.buttonGradient),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Ajouter',
                                style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Liste des enfants
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                    : _enfants.isEmpty
                        ? _buildEmpty(context, parentId)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: _enfants.length,
                            itemBuilder: (context, index) {
                              final enfant = _enfants[index];
                              return _EnfantCard(
                                enfant: enfant,
                                onTap: () async {
                                  await Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => EnfantDetailScreen(
                                      enfant: enfant,
                                      onDelete: _loadEnfants,
                                    ),
                                  ));
                                  _loadEnfants();
                                },
                                onDelete: () async {
                                  await EnfantService.deleteEnfant(enfant.id);
                                  _loadEnfants();
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, String parentId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👶', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Aucun enfant ajouté',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Commencez par ajouter le profil de votre enfant',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddEnfantScreen(parentId: parentId),
              ));
              _loadEnfants();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.buttonGradient),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Ajouter un enfant',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBellBtn(BuildContext context, String parentId) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => NotificationsScreen(parentId: parentId),
        ));
        _loadEnfants(); // refresh le badge au retour
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary, size: 18),
          ),
          if (_notifCount > 0)
            Positioned(
              top: -4, right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _notifCount > 9 ? '9+' : '$_notifCount',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Voulez-vous vous déconnecter ?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
            child: const Text('Déconnecter',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Carte enfant ──────────────────────────────────────────────────────────────
class _EnfantCard extends StatelessWidget {
  final EnfantModel enfant;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EnfantCard({
    required this.enfant,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isFille = enfant.sexe == 'F';
    final color = isFille ? const Color(0xFFE91E8C) : const Color(0xFF1E6FDB);
    final emoji = isFille ? '👧' : '👦';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.4), width: 2),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(enfant.nomComplet,
                      style: const TextStyle(color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    '${enfant.age} ans · ${isFille ? "Fille" : "Garçon"}',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  if (enfant.groupeSanguin != null)
                    Text('Groupe sanguin : ${enfant.groupeSanguin}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger, size: 17),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.buttonGradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Supprimer le profil de ${enfant.nomComplet} ?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
