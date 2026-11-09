import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/conversation_model.dart';
import '../../models/pediatre_model.dart';
import '../../services/message_service.dart';
import '../../services/pediatre_service.dart';
import '../../theme/app_colors.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ConversationsScreen({super.key, required this.user});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<ConversationModel> _conversations = [];
  bool _loading = true;
  Timer? _timer;

  String get _userId => (widget.user['id'] ?? widget.user['uid'] ?? '').toString();
  bool get _isParent => (widget.user['role'] ?? 'parent') == 'parent';

  @override
  void initState() {
    super.initState();
    _load();
    // Actualisation automatique toutes les 5 secondes
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final convs = await MessageService.getConversations(_userId);
    if (mounted) setState(() { _conversations = convs; _loading = false; });
  }

  Future<void> _openChat(String contactId, String contactName, String role) async {
    _timer?.cancel();
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(
        userId: _userId,
        contactId: contactId,
        contactName: contactName,
        contactRole: role,
      ),
    ));
    _load(silent: true);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  // ── Choisir un pédiatre (nouvelle conversation, côté parent) ──────────────
  Future<void> _pickPediatre() async {
    final pediatres = await PediatreService.getPediatres();
    if (!mounted) return;
    final selected = await showModalBottomSheet<PediatreModel>(
      context: context,
      backgroundColor: const Color(0xFF0D2D5E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PediatrePicker(pediatres: pediatres),
    );
    if (selected != null) _openChat(selected.id, selected.name, 'pediatre');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      floatingActionButton: _isParent
          ? FloatingActionButton.extended(
        onPressed: _pickPediatre,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text('Nouveau message',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      )
          : null,
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
              _buildHeader(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                    : _conversations.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ConversationTile(
                      conv: _conversations[i],
                      userId: _userId,
                      onTap: () => _openChat(
                        _conversations[i].contactId,
                        _conversations[i].contactName,
                        _conversations[i].contactRole,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text('Messagerie',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 22, fontWeight: FontWeight.w700)),
          const Spacer(),
          const Icon(Icons.lock_outline_rounded, color: AppColors.accent, size: 16),
          const SizedBox(width: 4),
          const Text('Sécurisée',
              style: TextStyle(color: AppColors.accent, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💬', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Aucune conversation',
                style: TextStyle(color: AppColors.textPrimary,
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              _isParent
                  ? 'Écrivez à un pédiatre pour poser vos questions'
                  : 'Les messages des parents apparaîtront ici',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte d'une conversation ────────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final ConversationModel conv;
  final String userId;
  final VoidCallback onTap;
  const _ConversationTile({required this.conv, required this.userId, required this.onTap});

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isPediatre = conv.contactRole == 'pediatre';
    final unread = conv.nonLus > 0;
    final prefix = conv.lastSenderId == userId ? 'Vous : ' : '';
    final apercu = conv.lastType == 'bilan' ? '📊 Bilan de développement' : conv.lastMessage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: conv.urgent
              ? AppColors.danger.withOpacity(0.15)
              : unread ? AppColors.primary.withOpacity(0.18) : AppColors.glassWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: conv.urgent
                  ? AppColors.danger.withOpacity(0.7)
                  : unread ? AppColors.secondary.withOpacity(0.5) : AppColors.glassBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isPediatre
                  ? AppColors.accent.withOpacity(0.25)
                  : AppColors.secondary.withOpacity(0.25),
              child: Text(isPediatre ? '👨‍⚕️' : '👨‍👩‍👦', style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(isPediatre ? 'Dr. ${conv.contactName}' : conv.contactName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textPrimary,
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      if (conv.urgent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('🔴 Urgent',
                              style: TextStyle(color: Colors.white,
                                  fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$prefix$apercu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: unread ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: unread ? FontWeight.w600 : FontWeight.normal)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatDate(conv.lastDate),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 6),
                if (unread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${conv.nonLus}',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Liste des pédiatres (bottom sheet) ──────────────────────────────────────
class _PediatrePicker extends StatelessWidget {
  final List<PediatreModel> pediatres;
  const _PediatrePicker({required this.pediatres});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Choisir un pédiatre',
                style: TextStyle(color: AppColors.textPrimary,
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (pediatres.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Aucun pédiatre disponible',
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pediatres.length,
                  itemBuilder: (_, i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accent.withOpacity(0.25),
                      child: const Text('👨‍⚕️'),
                    ),
                    title: Text('Dr. ${pediatres[i].name}',
                        style: const TextStyle(color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(pediatres[i].email,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
                    onTap: () => Navigator.pop(context, pediatres[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}