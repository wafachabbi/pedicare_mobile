import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../services/message_service.dart';
import '../../theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String contactId;
  final String contactName;
  final String contactRole; // 'parent' ou 'pediatre'

  const ChatScreen({
    super.key,
    required this.userId,
    required this.contactId,
    required this.contactName,
    required this.contactRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<MessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _timer;

  bool get _isPediatre => widget.contactRole == 'pediatre';

  @override
  void initState() {
    super.initState();
    _fetch(initial: true);
    // Récupère les nouveaux messages toutes les 3 secondes
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool initial = false}) async {
    final msgs = await MessageService.getMessages(widget.userId, widget.contactId);
    if (!mounted) return;
    final nouveau = msgs.length != _messages.length;
    setState(() {
      _messages = msgs;
      _loading = false;
    });
    if (nouveau || initial) _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final error = await MessageService.envoyer(
      senderId: widget.userId,
      receiverId: widget.contactId,
      content: text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }
    _controller.clear();
    _fetch();

    // IA de tri : si le parent décrit une situation urgente
    if (_isPediatre &&
        MessageService.analyserUrgence(text) == NiveauUrgence.urgent &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          content: Text('⚠️ Message détecté comme urgent : il sera signalé en priorité au pédiatre.\n'
              "En cas d'urgence vitale, appelez immédiatement le 190 (SAMU)."),
        ),
      );
    }
  }

  Future<void> _confirmDelete(MessageModel msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        title: const Text('Supprimer le message ?',
            style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Supprimer', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    final deleted = await MessageService.supprimer(msg.id, widget.userId);
    if (deleted && mounted) setState(() => _messages.removeWhere((m) => m.id == msg.id));
  }

  @override
  Widget build(BuildContext context) {
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
              _buildHeader(),
              const Divider(color: AppColors.glassBorder, height: 1),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                    : _messages.isEmpty
                    ? const Center(
                    child: Text('Commencez la conversation 👋',
                        style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    final showDay = i == 0 ||
                        !_sameDay(_messages[i - 1].date, msg.date);
                    return Column(
                      children: [
                        if (showDay) _DaySeparator(date: msg.date),
                        _MessageBubble(
                          msg: msg,
                          mine: msg.isMine(widget.userId),
                          onLongPress: msg.isMine(widget.userId)
                              ? () => _confirmDelete(msg)
                              : null,
                        ),
                      ],
                    );
                  },
                ),
              ),
              _buildInput(),
            ],
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: _isPediatre
                ? AppColors.accent.withOpacity(0.25)
                : AppColors.secondary.withOpacity(0.25),
            child: Text(_isPediatre ? '👨‍⚕️' : '👨‍👩‍👦', style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isPediatre ? 'Dr. ${widget.contactName}' : widget.contactName,
                    style: const TextStyle(color: AppColors.textPrimary,
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text(_isPediatre ? 'Pédiatre' : 'Parent',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Écrire un message…',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.inputFill,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.secondary),
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 48, height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: AppColors.buttonGradient),
              ),
              child: _sending
                  ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bulle de message ────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool mine;
  final VoidCallback? onLongPress;
  const _MessageBubble({required this.msg, required this.mine, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final time =
        '${msg.date.hour.toString().padLeft(2, '0')}:${msg.date.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            gradient: msg.estBilan
                ? const LinearGradient(colors: [Color(0xFF00855A), Color(0xFF00C9A7)])
                : mine
                ? const LinearGradient(colors: AppColors.buttonGradient)
                : null,
            color: (mine || msg.estBilan) ? null : AppColors.glassWhite,
            border: (mine || msg.estBilan) ? null : Border.all(color: AppColors.glassBorder),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.estBilan)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('📊 Bilan de développement (IA)',
                        style: TextStyle(color: Colors.white,
                            fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(msg.content,
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    Icon(msg.lu ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 14, color: Colors.white70),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Séparateur de jour ("Aujourd'hui", "08/11/2026") ───────────────────────
class _DaySeparator extends StatelessWidget {
  final DateTime date;
  const _DaySeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final label = isToday
        ? "Aujourd'hui"
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ),
    );
  }
}