import 'package:flutter/material.dart';
import '../../models/assistant_models.dart';
import '../../models/enfant_model.dart';
import '../../services/assistant_ia_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';
import 'base_connaissances_screen.dart';

/// Conversation avec l'assistant IA pédiatrique.
class ChatScreen extends StatefulWidget {
  final EnfantModel enfant;

  /// Null = nouvelle conversation (créée au premier message).
  final ConversationIA? conversation;

  const ChatScreen({super.key, required this.enfant, this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _bleu = Color(0xFF4285F4);

  static const _suggestions = [
    'Mon enfant a de la fièvre, que faire ?',
    'Comment l\'aider à mieux dormir ?',
    'Que peut-il manger à son âge ?',
    'Il tousse depuis quelques jours.',
  ];

  final _saisie = TextEditingController();
  final _scroll = ScrollController();
  String? _conversationId;
  List<MessageIA> _messages = [];
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversation?.id;
    _load();
  }

  @override
  void dispose() {
    _saisie.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_conversationId == null) return;
    final m = await AssistantIaService.getMessages(_conversationId!);
    if (!mounted) return;
    setState(() => _messages = m);
    _defilerEnBas();
  }

  void _defilerEnBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _envoyer([String? texte]) async {
    final question = (texte ?? _saisie.text).trim();
    if (question.isEmpty || _envoi) return;
    _saisie.clear();
    setState(() {
      _envoi = true;
      // Affichage immédiat de la question en attendant la réponse.
      _messages = [
        ..._messages,
        MessageIA(
            id: '',
            conversationId: _conversationId ?? '',
            duParent: true,
            texte: question,
            date: DateTime.now()),
      ];
    });
    _defilerEnBas();
    try {
      _conversationId = await AssistantIaService.envoyer(
        enfant: widget.enfant,
        conversationId: _conversationId,
        question: question,
      );
      await _load();
    } catch (e) {
      if (mounted) pcSnack(context, 'Envoi impossible : $e', erreur: true);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PcPage(
      titre: widget.conversation?.titre ?? 'Nouvelle question',
      sousTitre: 'Assistant IA · ${widget.enfant.prenom}',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              children: [
                if (_messages.isEmpty) ...[
                  const PcAvertissement(AssistantIaService.avertissement),
                  const SizedBox(height: 6),
                  const Text('Exemples de questions :',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in _suggestions)
                        PcChip(label: s, color: _bleu, onTap: () => _envoyer(s)),
                    ],
                  ),
                ],
                for (final m in _messages) _bulle(m),
                if (_envoi)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _bleu)),
                        SizedBox(width: 10),
                        Text('L\'assistant rédige sa réponse…',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _saisie,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _envoyer(),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: pcInputDecoration('Votre question…'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _envoi ? null : _envoyer,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _envoi ? _bleu.withValues(alpha: 0.4) : _bleu,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulle(MessageIA m) {
    final couleur = m.duParent
        ? _bleu
        : (m.urgent ? AppColors.danger : AppColors.inputFill);
    return Align(
      alignment: m.duParent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: m.duParent ? couleur : couleur.withValues(alpha: m.urgent ? 0.2 : 1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(m.duParent ? 16 : 4),
            bottomRight: Radius.circular(m.duParent ? 4 : 16),
          ),
          border: m.duParent
              ? null
              : Border.all(
                  color: m.urgent ? AppColors.danger : AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.texte,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13.5, height: 1.4)),
            if (!m.duParent) ...[
              if (m.sources.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Sources',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                for (final s in m.sources)
                  GestureDetector(
                    onTap: () => ouvrirPassage(context, s.passageId),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text('[${s.numero}] ${s.titre} · ${s.source}',
                          style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 11,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.secondary)),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Text(
                  m.parIA
                      ? '✨ Réponse IA (RAG : fiches PediCare + dossier)'
                      : '📚 Réponse extraite des fiches PediCare (hors ligne)',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10.5)),
            ],
          ],
        ),
      ),
    );
  }
}
