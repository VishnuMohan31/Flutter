// Modern Entry Card - Beautiful, Professional, Attractive Design
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/entry_model.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';

class ModernEntryCard extends StatelessWidget {
  final EntryModel entry;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onMarkComplete;

  const ModernEntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
    this.onMarkComplete,
  });

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categoryColor = categoryProvider.getCategoryColor(entry.categoryId);
    final category = entry.categoryId != null
        ? categoryProvider.getCategoryById(entry.categoryId!)
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: categoryColor.withOpacity(isDark ? 0.5 : 0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark
                    ? categoryColor.withOpacity(0.1)
                    : categoryColor.withOpacity(0.05),
                isDark ? Colors.transparent : categoryColor.withOpacity(0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    // Type Icon with gradient background
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getTypeColor(),
                            _getTypeColor().withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getTypeColor().withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getTypeIcon(),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              decoration: entry.status == 'completed'
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(entry.eventDate ?? entry.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Favorite Star
                    Container(
                      decoration: BoxDecoration(
                        color: entry.isFavorite
                            ? AppTheme.accentAmber.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          entry.isFavorite ? Icons.star : Icons.star_border,
                          color: entry.isFavorite
                              ? AppTheme.accentAmber
                              : Colors.grey,
                          size: 24,
                        ),
                        onPressed: onToggleFavorite,
                      ),
                    ),
                    // More Menu
                    PopupMenuButton(
                      icon:
                          Icon(Icons.more_vert, color: AppTheme.textSecondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded,
                                  size: 20, color: AppTheme.primaryBlue),
                              const SizedBox(width: 12),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                        if (entry.type == 'task' && entry.status != 'completed')
                          PopupMenuItem(
                            value: 'complete',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 20, color: AppTheme.successGreen),
                                const SizedBox(width: 12),
                                const Text('Mark Complete'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded,
                                  size: 20, color: AppTheme.errorRed),
                              const SizedBox(width: 12),
                              Text('Delete',
                                  style: TextStyle(color: AppTheme.errorRed)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                        if (value == 'complete' && onMarkComplete != null) {
                          onMarkComplete!();
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  entry.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Footer with badges
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Category Badge
                    if (category != null)
                      _buildBadge(
                        category.name,
                        categoryColor,
                        Icons.folder_rounded,
                      ),
                    // Priority Badge
                    _buildPriorityBadge(),
                    // Status Badge
                    if (entry.type == 'task') _buildStatusBadge(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    Color color;
    String label;
    IconData icon;

    switch (entry.priority) {
      case 'urgent':
        color = AppTheme.priorityUrgent;
        label = 'URGENT';
        icon = Icons.priority_high_rounded;
        break;
      case 'high':
        color = AppTheme.priorityHigh;
        label = 'HIGH';
        icon = Icons.arrow_upward_rounded;
        break;
      case 'medium':
        color = AppTheme.priorityMedium;
        label = 'MEDIUM';
        icon = Icons.remove_rounded;
        break;
      default:
        color = AppTheme.priorityLow;
        label = 'LOW';
        icon = Icons.arrow_downward_rounded;
    }

    return _buildBadge(label, color, icon);
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;
    IconData icon;

    switch (entry.status) {
      case 'completed':
        color = AppTheme.successGreen;
        label = 'DONE';
        icon = Icons.check_circle_rounded;
        break;
      case 'in_progress':
        color = AppTheme.infoBlue;
        label = 'IN PROGRESS';
        icon = Icons.pending_rounded;
        break;
      case 'cancelled':
        color = AppTheme.errorRed;
        label = 'CANCELLED';
        icon = Icons.cancel_rounded;
        break;
      default:
        color = AppTheme.textSecondary;
        label = 'PENDING';
        icon = Icons.schedule_rounded;
    }

    return _buildBadge(label, color, icon);
  }

  IconData _getTypeIcon() {
    switch (entry.type) {
      case 'event':
        return Icons.event_rounded;
      case 'task':
        return Icons.task_alt_rounded;
      case 'note':
        return Icons.lightbulb_rounded;
      default:
        return Icons.note_rounded;
    }
  }

  Color _getTypeColor() {
    switch (entry.type) {
      case 'event':
        return AppTheme.accentOrange;
      case 'task':
        return AppTheme.accentGreen;
      case 'note':
        return AppTheme.accentAmber;
      default:
        return AppTheme.primaryBlue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today, ${DateFormat('HH:mm').format(date)}';
    } else if (entryDate == yesterday) {
      return 'Yesterday, ${DateFormat('HH:mm').format(date)}';
    } else if (now.difference(entryDate).inDays < 7) {
      return DateFormat('EEEE, HH:mm').format(date);
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
