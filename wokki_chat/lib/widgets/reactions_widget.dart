import 'package:flutter/material.dart';
import '../models/message.dart';
import 'emoji_picker_widget.dart';

class ReactionsWidget extends StatelessWidget {
  final List<Reaction> reactions;
  final String currentUserId;
  final Function(String emoji) onReactionTap;
  final VoidCallback onAddReaction;

  const ReactionsWidget({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionTap,
    required this.onAddReaction,
  });

  @override
  Widget build(BuildContext context) {
    final groupedReactions = _groupReactions();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        ...groupedReactions.entries.map((entry) {
          final emoji = entry.key;
          final reactionList = entry.value;
          final count = reactionList.length;
          final isOwn = reactionList.any((r) => r.userId == currentUserId);

          return _ReactionBubble(
            emoji: emoji,
            count: count,
            isOwn: isOwn,
            isDark: isDark,
            onTap: () => onReactionTap(emoji),
          );
        }),
        _AddReactionButton(
          isDark: isDark,
          onTap: onAddReaction,
        ),
      ],
    );
  }

  Map<String, List<Reaction>> _groupReactions() {
    final Map<String, List<Reaction>> grouped = {};
    
    for (var reaction in reactions) {
      if (!grouped.containsKey(reaction.reaction)) {
        grouped[reaction.reaction] = [];
      }
      grouped[reaction.reaction]!.add(reaction);
    }
    
    return grouped;
  }
}

class _ReactionBubble extends StatefulWidget {
  final String emoji;
  final int count;
  final bool isOwn;
  final bool isDark;
  final VoidCallback onTap;

  const _ReactionBubble({
    required this.emoji,
    required this.count,
    required this.isOwn,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ReactionBubble> createState() => _ReactionBubbleState();
}

class _ReactionBubbleState extends State<_ReactionBubble> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isOwn
                ? const Color(0xFFB691FA).withOpacity(0.3)
                : (widget.isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0)),
            border: Border.all(
              color: widget.isOwn
                  ? const Color(0xFF895BF5)
                  : (_isHovered
                      ? (widget.isDark ? const Color(0xFF808080) : const Color(0xFF808080))
                      : Colors.transparent),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.emoji,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 5),
              Text(
                '${widget.count}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? const Color(0xFFB2B2B2) : const Color(0xFF4D4D4D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddReactionButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _AddReactionButton({
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AddReactionButton> createState() => _AddReactionButtonState();
}

class _AddReactionButtonState extends State<_AddReactionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
            border: Border.all(
              color: _isHovered
                  ? (widget.isDark ? const Color(0xFF808080) : const Color(0xFF808080))
                  : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.add_reaction_outlined,
            size: 19,
            color: widget.isDark ? const Color(0xFFB2B2B2) : const Color(0xFF4D4D4D),
          ),
        ),
      ),
    );
  }
}

class ReactionPickerOverlay {
  static void show(
    BuildContext context,
    Offset position,
    Function(String) onEmojiSelected,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () => overlayEntry.remove(),
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: position.dx,
            top: position.dy - 360,
            child: Material(
              color: Colors.transparent,
              child: EmojiPickerWidget(
                onEmojiSelected: (emoji) {
                  onEmojiSelected(emoji);
                  overlayEntry.remove();
                },
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(overlayEntry);
  }
}