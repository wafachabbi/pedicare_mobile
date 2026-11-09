import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Petits composants partagés par les écrans PediPharma et Nutrition,
/// dans le style « verre sombre » du reste de l'application.

/// Page avec fond dégradé, en-tête (retour + titre) et contenu.
class PcPage extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final Widget child;
  final Widget? fab;
  final List<Widget> actions;

  const PcPage({
    super.key,
    required this.titre,
    this.sousTitre,
    required this.child,
    this.fab,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      floatingActionButton: fab,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    PcIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                          if (sousTitre != null)
                            Text(sousTitre!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class PcIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String? tooltip;

  const PcIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = AppColors.textPrimary,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Carte « verre » teintée.
class PcCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;

  const PcCard({
    super.key,
    required this.child,
    this.color = AppColors.secondary,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 10),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: child,
      ),
    );
  }
}

class PcSectionTitle extends StatelessWidget {
  final String texte;
  final Widget? trailing;

  const PcSectionTitle(this.texte, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(texte,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class PcEmpty extends StatelessWidget {
  final String emoji;
  final String titre;
  final String sousTitre;

  const PcEmpty({
    super.key,
    required this.emoji,
    required this.titre,
    required this.sousTitre,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(titre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(sousTitre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Champ texte au style de l'application.
class PcTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const PcTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: pcInputDecoration(label, icon: icon),
      ),
    );
  }
}

InputDecoration pcInputDecoration(String label, {IconData? icon}) {
  OutlineInputBorder bord(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    prefixIcon:
        icon == null ? null : Icon(icon, color: AppColors.textSecondary, size: 19),
    filled: true,
    fillColor: AppColors.inputFill,
    enabledBorder: bord(AppColors.glassBorder),
    focusedBorder: bord(AppColors.secondary),
    errorBorder: bord(AppColors.danger),
    focusedErrorBorder: bord(AppColors.danger),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

/// Pastille sélectionnable.
class PcChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  const PcChip({
    super.key,
    required this.label,
    this.selected = false,
    this.color = AppColors.secondary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.25)
              : AppColors.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : AppColors.glassBorder),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }
}

/// Bouton principal plein largeur.
class PcPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const PcPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Bandeau d'avertissement (contraintes médicales du cahier des charges).
class PcAvertissement extends StatelessWidget {
  final String texte;
  const PcAvertissement(this.texte, {super.key});

  @override
  Widget build(BuildContext context) {
    return PcCard(
      color: const Color(0xFFE67E22),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ℹ️', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texte,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11.5, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

// ── Dialogues & messages ───────────────────────────────────────────────────

Future<bool> pcConfirmer(
  BuildContext context, {
  required String titre,
  required String message,
  String confirmer = 'Supprimer',
  Color couleur = AppColors.danger,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF0D2D5E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(titre,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700)),
      content: Text(message,
          style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary))),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmer,
                style: TextStyle(color: couleur, fontWeight: FontWeight.w700))),
      ],
    ),
  );
  return ok == true;
}

void pcSnack(BuildContext context, String message, {bool erreur = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: erreur ? AppColors.danger : const Color(0xFF00A88B),
    behavior: SnackBarBehavior.floating,
  ));
}

/// Thème sombre pour les sélecteurs de date et d'heure.
Widget pcPickerTheme(BuildContext context, Widget? child) => Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.secondary,
          surface: Color(0xFF0D2D5E),
        ),
      ),
      child: child!,
    );

// ── Formatage ──────────────────────────────────────────────────────────────

String pcDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String pcHeure(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String pcJourRelatif(DateTime d) {
  final now = DateTime.now();
  final a = DateTime(now.year, now.month, now.day);
  final b = DateTime(d.year, d.month, d.day);
  final diff = a.difference(b).inDays;
  if (diff == 0) return 'Aujourd\'hui';
  if (diff == 1) return 'Hier';
  return pcDate(d);
}
