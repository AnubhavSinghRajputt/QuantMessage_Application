import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // INTEGRATED
import 'package:intl/intl.dart'; // Required for date formatting (add to pubspec.yaml)

import '../core/app_theme.dart';

// Updated model to align with Supabase chat_messages table
class HistoryItem {
  final String conversationId;
  final String query;
  final DateTime createdAt;
  final String modelName;
  final IconData icon;

  HistoryItem({
    required this.conversationId,
    required this.query,
    required this.createdAt,
    required this.modelName,
    required this.icon,
  });

  // Helper to format date as "Today", "Yesterday", or "Oct 24"
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt).inDays;
    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    return DateFormat('MMM d').format(createdAt);
  }

  // Helper to format time as "2:45 PM"
  String get formattedTime => DateFormat('h:mm a').format(createdAt);
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<HistoryItem> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SUPABASE DATA INTEGRATION
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 1. Fetch messages sent by the user, ordered by newest first
      final data = await _supabase
          .from('chat_messages')
          .select('conversation_id, content, created_at, metadata')
          .eq('sender_uuid', user.id)
          .eq('role', 'user')
          .order('created_at', ascending: false);

      // 2. Group by conversation_id to avoid duplicate entries for the same chat
      final Map<String, HistoryItem> uniqueConversations = {};

      for (var msg in data) {
        final convId = msg['conversation_id'];
        if (!uniqueConversations.containsKey(convId)) {
          // Use a default icon based on content or a generic chat icon
          uniqueConversations[convId] = HistoryItem(
            conversationId: convId,
            query: msg['content'],
            createdAt: DateTime.parse(msg['created_at']),
            modelName: (msg['metadata'] as Map?)?['model'] ?? 'QuantCore',
            icon: _getIconForQuery(msg['content']),
          );
        }
      }

      setState(() {
        _historyItems = uniqueConversations.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching history: $e');
      setState(() => _isLoading = false);
    }
  }

  // Logic to assign icons based on keywords in the query
  IconData _getIconForQuery(String query) {
    final q = query.toLowerCase();
    if (q.contains('qr') || q.contains('scan')) return Icons.qr_code_scanner_rounded;
    if (q.contains('image') || q.contains('generate')) return Icons.brush_rounded;
    if (q.contains('weather') || q.contains('forecast')) return Icons.wb_sunny_rounded;
    if (q.contains('code') || q.contains('python') || q.contains('script')) return Icons.code_rounded;
    if (q.contains('analyze') || q.contains('chart')) return Icons.analytics_rounded;
    return Icons.chat_bubble_outline_rounded;
  }

  Future<void> _clearHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Delete all messages where the user was the sender
      await _supabase
          .from('chat_messages')
          .delete()
          .eq('sender_uuid', user.id);

      setState(() {
        _historyItems = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surfaceMedium,
          content: Text("History cleared successfully", style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
        ),
      );
    } catch (e) {
      debugPrint('Clear history error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Search History",
          style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withOpacity(0.05), height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.primaryRed, size: 22),
            onPressed: _clearHistory,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : _historyItems.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: _historyItems.length,
        itemBuilder: (context, index) {
          final item = _historyItems[index];
          return FadeInUp(
            duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 800)),
            child: _buildHistoryCard(item),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // INTEGRATED: This would navigate back to ChatScreen with the conversationId
            // Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(conversationId: item.conversationId)));
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryRed.withOpacity(0.2)),
                  ),
                  child: Icon(item.icon, color: AppTheme.primaryRed, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.query,
                        style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              item.modelName,
                              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${item.formattedDate} • ${item.formattedTime}",
                            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 60, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text("No Search History", style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text("Your past conversations will appear here.", style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
