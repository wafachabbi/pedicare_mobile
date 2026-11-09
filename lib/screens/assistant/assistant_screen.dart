import 'package:flutter/material.dart';
import '../../models/assistant_models.dart';
import '../../models/enfant_model.dart';
import '../../services/assistant_ia_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';
import 'base_connaissances_screen.dart';
import 'chat_screen.dart';

/// Assistant IA pédiatrique : liste des conversations de l'enfant.
class AssistantScreen extends StatefulWidget {
  final EnfantModel enfant;
  const AssistantScreen({super.key, required this.enfant});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  static const _bleu = Color(0xFF4285F4);

  List<ConversationIA> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await AssistantIaService.getConversations(widget.enfant.id);
    if (!mounted) return;
    setState(() {
      _conversations = c;
      _loading = false;
    });
  }

  Future<void> _ouvrir([ConversationIA? c]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ChatScreen(enfant: widget.enfant, conversation: c)),
    );
    _load();
  }

  Future<void> _supprimer(ConversationIA c) async {
    final ok = await pcConfirmer(context,
        titre: 'Supprimer la conversation',
        message: 'Supprimer « ${c.titre} » et tous ses messages ?');
    if (!ok) return;
    await AssistantIaService.supprimerConversation(c.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return PcPage(
      titre: 'Assistant IA',
      sousTitre: 'Questions sur la santé de ${widget.enfant.prenom}',
      actions: [
        PcIconButton(
          icon: Icons.menu_book_rounded,
          tooltip: 'Base de connaissances',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BaseConnaissancesScreen()),
          ),
        ),
      ],
      fab: FloatingActionButton.extended(
        onPressed: _ouvrir,
        backgroundColor: _bleu,
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: const Text('Nouvelle question',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                const PcAvertissement(AssistantIaService.avertissement),
                if (_conversations.isEmpty)
                  const PcEmpty(
                    emoji: '🤖',
                    titre: 'Aucune conversation',
                    sousTitre:
                        'Posez une question générale : fièvre, sommeil, alimentation, '
                        'médicaments… Les réponses tiennent compte de l\'âge et des '
                        'allergies de l\'enfant.',
                  )
                else ...[
                  PcSectionTitle('Conversations (${_conversations.length})'),
                  for (final c in _conversations)
                    PcCard(
                      color: _bleu,
                      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                      onTap: () => _ouvrir(c),
                      child: Row(
                        children: [
                          const Text('💬', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.titre,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    '${pcJourRelatif(c.majLe)} · ${pcHeure(c.majLe)}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 19, color: AppColors.textSecondary),
                            onPressed: () => _supprimer(c),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
