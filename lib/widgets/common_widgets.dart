import 'package:flutter/material.dart';

/// 搜索高亮文本组件
class HighlightText extends StatelessWidget {
  final String text;
  final String? highlight;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int maxLines;

  const HighlightText({
    super.key,
    required this.text,
    this.highlight,
    this.style,
    this.highlightStyle,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight == null || highlight!.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }

    final highlightLower = highlight!.toLowerCase();
    final textLower = text.toLowerCase();
    
    // 找到所有匹配位置
    final matches = <String, List<int>>{};
    var start = 0;
    while (true) {
      final index = textLower.indexOf(highlightLower, start);
      if (index == -1) break;
      
      if (!matches.containsKey(highlightLower)) {
        matches[highlightLower] = [];
      }
      matches[highlightLower]!.add(index);
      start = index + 1;
    }

    if (matches.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }

    // 构建带高亮的文本
    final spans = <TextSpan>[];
    var currentIndex = 0;

    for (final matchStart in matches[highlightLower]!) {
      // 添加匹配前的文本
      if (currentIndex < matchStart) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, matchStart),
          style: style,
        ));
      }

      // 添加匹配文本
      spans.add(TextSpan(
        text: text.substring(matchStart, matchStart + highlight!.length),
        style: highlightStyle ?? style?.copyWith(backgroundColor: Colors.yellow, color: Colors.black),
      ));

      currentIndex = matchStart + highlight!.length;
    }

    // 添加剩余文本
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: style,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// 标签芯片组件（带删除功能）
class TagChip extends StatelessWidget {
  final String tag;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Color? color;

  const TagChip({
    super.key,
    required this.tag,
    this.selected = false,
    this.onTap,
    this.onDelete,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? (selected ? Colors.blue : Colors.grey[200]);
    final textColor = color != null ? Colors.white : (selected ? Colors.white : Colors.grey[800]);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(16),
          border: selected ? null : BorderSide(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: TextStyle(color: textColor, fontSize: 12),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 笔记统计卡片
class StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? color;

  const StatsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color ?? Colors.blue),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空状态组件
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}
