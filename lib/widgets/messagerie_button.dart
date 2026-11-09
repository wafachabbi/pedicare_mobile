import 'dart:async';
import 'package:flutter/material.dart';
import '../services/message_notification_service.dart';
import '../theme/app_colors.dart';
import '../screens/messagerie/conversations_screen.dart';

/// Bouton 💬 de l'accueil : badge des non lus + notifications en temps réel
class MessagerieButton extends StatefulWidget {
  final Map<String, dynamic> user;
  const MessagerieButton({super.key, required this.user});

  @override
  State<MessagerieButton> createState() => _MessagerieButtonState();
}

class _MessagerieButtonState extends State<MessagerieButton> {
  int _nonLus = 0;
  Timer? _timer;

  String get _userId => (widget.user['id'] ?? widget.user['uid'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _verifier();
    // Vérifie les nouveaux messages toutes les 5 secondes
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _verifier());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifier() async {
    final n = await MessageNotificationService.verifier(_userId);
    if (mounted && n != _nonLus) setState(() => _nonLus = n);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => ConversationsScreen(user: widget.user),
        ));
        _verifier(); // mettre à jour le badge au retour
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
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.textPrimary, size: 18),
          ),
          if (_nonLus > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFF0A1628), width: 2),
                ),
                child: Text(_nonLus > 9 ? '9+' : '$_nonLus',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}