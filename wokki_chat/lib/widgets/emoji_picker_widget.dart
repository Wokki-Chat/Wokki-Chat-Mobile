import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class EmojiPickerWidget extends StatelessWidget {
  final Function(String) onEmojiSelected;
  final bool isDark;

  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      width: 500,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF303030) : const Color(0xFFF0F0F0),
        border: Border.all(
          color: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
          ),
        ],
      ),
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          onEmojiSelected(emoji.emoji);
        },
        config: Config(
          height: 350,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            backgroundColor: isDark ? const Color(0xFF303030) : const Color(0xFFF0F0F0),
            columns: 9,
            emojiSizeMax: 24,
            verticalSpacing: 0,
            horizontalSpacing: 0,
            gridPadding: EdgeInsets.zero,
            recentsLimit: 28,
            replaceEmojiOnLimitExceed: false,
            buttonMode: ButtonMode.MATERIAL,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
            indicatorColor: const Color(0xFF895BF5),
            iconColor: isDark ? const Color(0xFFC4C4C4) : const Color(0xFF333333),
            iconColorSelected: isDark ? Colors.white : Colors.black,
            backspaceColor: const Color(0xFF895BF5),
            categoryIcons: const CategoryIcons(),
            tabIndicatorAnimDuration: kTabScrollDuration,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(
            enabled: false,
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
            hintText: 'Search emoji...',
          ),
          skinToneConfig: const SkinToneConfig(),
        ),
      ),
    );
  }
}

class EmojiPickerDialog extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const EmojiPickerDialog({
    super.key,
    required this.onEmojiSelected,
  });

  static Future<void> show(BuildContext context, Function(String) onEmojiSelected) {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => EmojiPickerDialog(onEmojiSelected: onEmojiSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned(
              bottom: 100,
              left: 20,
              child: GestureDetector(
                onTap: () {},
                child: EmojiPickerWidget(
                  onEmojiSelected: (emoji) {
                    onEmojiSelected(emoji);
                    Navigator.of(context).pop();
                  },
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}