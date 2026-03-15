import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

class MarkdownRenderer {
  final BuildContext context;
  final String currentUserId;
  final List<Map<String, dynamic>> channels;
  final List<Map<String, dynamic>> users;
  final Function(String)? onUserMention;
  final Function(String)? onChannelTap;

  MarkdownRenderer({
    required this.context,
    required this.currentUserId,
    this.channels = const [],
    this.users = const [],
    this.onUserMention,
    this.onChannelTap,
  });

  Widget render(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final parts = _splitCodeBlocks(text);
    final widgets = <Widget>[];

    for (var part in parts) {
      if (part.startsWith('```')) {
        final match = RegExp(r'```(\w+)?\n([\s\S]*?)```').firstMatch(part);
        if (match != null) {
          final lang = match.group(1) ?? '';
          final code = match.group(2) ?? '';
          widgets.add(_buildCodeBlock(code, lang, isDark));
        }
      } else {
        widgets.addAll(_buildInlineContent(part, isDark));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<String> _splitCodeBlocks(String text) {
    final parts = <String>[];
    final regex = RegExp(r'(```\w*\n[\s\S]*?```)');
    int lastIndex = 0;

    for (var match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        parts.add(text.substring(lastIndex, match.start));
      }
      parts.add(match.group(0)!);
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      parts.add(text.substring(lastIndex));
    }

    return parts.isEmpty ? [text] : parts;
  }

  Widget _buildCodeBlock(String code, String lang, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282828) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE0E0E0),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.isEmpty ? 'plaintext' : lang,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                Icon(
                  Icons.content_copy,
                  size: 18,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ],
            ),
          ),
          HighlightView(
            code,
            language: lang.isEmpty ? 'plaintext' : lang,
            theme: isDark ? monokaiSublimeTheme : githubTheme,
            padding: const EdgeInsets.all(12),
            textStyle: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInlineContent(String text, bool isDark) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      if (RegExp(r'^#{1,6} ').hasMatch(line)) {
        widgets.add(_buildHeading(line));
        i++;
      } else if (RegExp(r'^[-*] ').hasMatch(line)) {
        final listItems = <String>[];
        while (i < lines.length && RegExp(r'^[-*] ').hasMatch(lines[i])) {
          listItems.add(lines[i].replaceFirst(RegExp(r'^[-*] '), '').trim());
          i++;
        }
        widgets.add(_buildUnorderedList(listItems, isDark));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final listItems = <String>[];
        while (i < lines.length && RegExp(r'^\d+\.\s').hasMatch(lines[i])) {
          listItems.add(lines[i].replaceFirst(RegExp(r'^\d+\.\s'), '').trim());
          i++;
        }
        widgets.add(_buildOrderedList(listItems, isDark));
      } else if (RegExp(r'^-{3,}$').hasMatch(line.trim())) {
        widgets.add(const Divider(thickness: 1));
        i++;
      } else {
        if (line.trim().isNotEmpty) {
          widgets.add(_buildParagraph(line, isDark));
        }
        i++;
      }
    }

    return widgets;
  }

  Widget _buildHeading(String line) {
    final match = RegExp(r'^(#+) (.+)').firstMatch(line);
    if (match == null) return const SizedBox.shrink();

    final level = match.group(1)!.length;
    final content = match.group(2)!;
    final fontSize = [32.0, 28.0, 24.0, 20.0, 18.0, 16.0][level - 1];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        content,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUnorderedList(List<String> items, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: _buildRichText(item, isDark)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderedList(List<String> items, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$index. ', style: const TextStyle(fontSize: 16)),
                Expanded(child: _buildRichText(item, isDark)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildParagraph(String text, bool isDark) {
    if (text.startsWith('>')) {
      final quoteText = text.replaceFirst(RegExp(r'^> ?'), '');
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Theme.of(context).primaryColor, width: 3),
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: _buildRichText(quoteText, isDark),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: _buildRichText(text, isDark),
    );
  }

  Widget _buildRichText(String text, bool isDark) {
    final spans = <InlineSpan>[];
    
    text = _escapeHtml(text);
    
    text = _processLinks(text, spans, isDark);
    text = _processUrls(text, spans, isDark);
    text = _processFormatting(text, spans, isDark);
    text = _processMentions(text, spans, isDark);
    text = _processChannels(text, spans, isDark);
    text = _processTimestamps(text, spans, isDark);

    if (text.isNotEmpty) {
      spans.add(TextSpan(text: text));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _processLinks(String text, List<InlineSpan> spans, bool isDark) {
    final regex = RegExp(r'\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)');
    int lastIndex = 0;

    for (var match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        final before = text.substring(lastIndex, match.start);
        if (before.isNotEmpty) {
          spans.add(TextSpan(text: before));
        }
      }

      final linkText = match.group(1)!;
      final url = match.group(2)!;
      
      spans.add(TextSpan(
        text: linkText,
        style: const TextStyle(
          color: Color(0xFF895BF5),
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _launchUrl(url),
      ));

      lastIndex = match.end;
    }

    return lastIndex < text.length ? text.substring(lastIndex) : '';
  }

  String _processUrls(String text, List<InlineSpan> spans, bool isDark) {
    final regex = RegExp(r'(?<!["''>])(https?:\/\/[^\s<]+)');
    int lastIndex = 0;

    for (var match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        final before = text.substring(lastIndex, match.start);
        if (before.isNotEmpty) {
          spans.add(TextSpan(text: before));
        }
      }

      final url = match.group(1)!;
      
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(
          color: Color(0xFF895BF5),
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _launchUrl(url),
      ));

      lastIndex = match.end;
    }

    return lastIndex < text.length ? text.substring(lastIndex) : '';
  }

  String _processFormatting(String text, List<InlineSpan> spans, bool isDark) {
    text = _processBold(text, spans, isDark);
    text = _processItalic(text, spans, isDark);
    text = _processStrikethrough(text, spans, isDark);
    text = _processInlineCode(text, spans, isDark);
    return text;
  }

  String _processBold(String text, List<InlineSpan> spans, bool isDark) {
    final regex = RegExp(r'(?<!\\)\*\*(?!\*)([\s\S]+?)\*\*');
    int lastIndex = 0;

    for (var match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        final before = text.substring(lastIndex, match.start);
        if (before.isNotEmpty) {
          spans.add(TextSpan(text: before));
        }
      }

      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));

      lastIndex = match.end;
    }

    return lastIndex < text.length ? text.substring(lastIndex) : '';
  }

  String _processItalic(String text, List<InlineSpan> spans, bool isDark) {
    final regex = RegExp(r'(?<!\\)(\*|_)([\s\S]+?)\1');
    int lastIndex = 0;

    for (var match in regex.allMatches(text)) {
      final content = match.group(2)!;
      if (content.contains('**')) continue;

      if (match.start > lastIndex) {
        final before = text.substring(lastIndex, match.start);
        if (before.isNotEmpty) {
          spans.add(TextSpan(text: before));
        }
      }

      spans.add(TextSpan(
        text: content,
        style: const TextStyle(fontStyle: FontStyle.italic),
      ));

      lastIndex = match.end;
    }

    return lastIndex < text.length ? text.substring(lastIndex) : '';
  }

  String _processStrikethrough(String text, List<InlineSpan> spans, bool isDark) {
    final regex = RegExp(r'(?<!\\)~~([\s\S]+?)~~');
    int lastIndex = 0;

    for (var match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        final before = text.substring(lastIndex, match.start);
        if (before.isNotEmpty) {
          spans.add(TextSpan(text: before));
        }
      }

      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(decoration: TextDecoration.lineThrough),
      ));

      lastIndex = match.end;
    }

    return lastIndex < text.length ? text.substring(lastIndex) : '';
  }

  String _processInlineCode(String text, List<InlineSpan> spans, bool isDark) {
    final regex = RegExp(r'(?<!\\)`([^`\n]+)`');
    int lastIndex = 0;

    for (var match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        final before = text.substring(lastIndex, match.start);
        if (before.isNotEmpty) {
          spans.add(TextSpan(text: before));
        }
      }

      spans.add(WidgetSpan(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3B3B3B) : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            match.group(1)!,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ));

      lastIndex = match.end;
    }

    return lastIndex < text.length ? text.substring(lastIndex) : '';
  }

  String _processMentions(String text, List<InlineSpan> spans, bool isDark) {
    final regex = RegExp(r'&lt;@([^&]+)&gt;');
    int lastIndex = 0;

    for (var match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        final before = text.substring(lastIndex, match.start);
        if (before.isNotEmpty) {
          spans.add(TextSpan(text: before));
        }
      }

      final username = match.group(1)!.trim();
      final user = users.firstWhere(
        (u) => u['username']?.toString().toLowerCase() == username.toLowerCase(),
        orElse: () => {},
      );
      final userId = user['id']?.toString() ?? '';
      final isSelf = userId == currentUserId;

      spans.add(WidgetSpan(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFB691FA).withOpacity(0.3),
            borderRadius: BorderRadius.circular(5),
          ),
          child: GestureDetector(
            onTap: () => onUserMention?.call(userId),
            child: Text(
              '@$username',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ));

      lastIndex = match.end;
    }

    return lastIndex < text.length ? text.substring(lastIndex) : '';
  }

  String _processChannels(String text, List<InlineSpan> spans, bool isDark) {
    final regex = RegExp(r'#([^\s#<]+)');
    int lastIndex = 0;

    for (var match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        final before = text.substring(lastIndex, match.start);
        if (before.isNotEmpty) {
          spans.add(TextSpan(text: before));
        }
      }

      final channelName = match.group(1)!;
      final channel = channels.firstWhere(
        (c) => c['name']?.toString().toLowerCase() == channelName.toLowerCase(),
        orElse: () => {},
      );

      if (channel.isNotEmpty) {
        spans.add(WidgetSpan(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFB691FA).withOpacity(0.3),
              borderRadius: BorderRadius.circular(5),
            ),
            child: GestureDetector(
              onTap: () => onChannelTap?.call(channel['channel_id']?.toString() ?? ''),
              child: Text(
                '#$channelName',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(text: match.group(0)));
      }

      lastIndex = match.end;
    }

    return lastIndex < text.length ? text.substring(lastIndex) : '';
  }

  String _processTimestamps(String text, List<InlineSpan> spans, bool isDark) {
    final regex = RegExp(r'&lt;t:(\d+):(\w+)&gt;');
    int lastIndex = 0;

    for (var match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        final before = text.substring(lastIndex, match.start);
        if (before.isNotEmpty) {
          spans.add(TextSpan(text: before));
        }
      }

      final timestamp = int.parse(match.group(1)!);
      final type = match.group(2)!;
      final formatted = _formatTimestamp(timestamp, type);

      spans.add(WidgetSpan(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF303030) : const Color(0xFFF0F0F0),
            border: Border.all(
              color: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            formatted,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ));

      lastIndex = match.end;
    }

    return lastIndex < text.length ? text.substring(lastIndex) : '';
  }

  String _formatTimestamp(int timestamp, String type) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();

    switch (type) {
      case 'R':
        final diff = date.difference(now);
        if (diff.inDays.abs() > 0) {
          return '${diff.inDays} days ${diff.isNegative ? "ago" : "from now"}';
        } else if (diff.inHours.abs() > 0) {
          return '${diff.inHours} hours ${diff.isNegative ? "ago" : "from now"}';
        } else if (diff.inMinutes.abs() > 0) {
          return '${diff.inMinutes} minutes ${diff.isNegative ? "ago" : "from now"}';
        }
        return 'just now';
      case 'F':
        return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      case 'D':
        return '${date.day}/${date.month}/${date.year}';
      case 'T':
        return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      default:
        return date.toIso8601String();
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}