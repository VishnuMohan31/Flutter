// Entry Card Widget - Beautiful card to display each entry

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/entry_model.dart';
import '../providers/category_provider.dart';

class EntryCard extends StatelessWidget {
  final EntryModel entry;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onMarkComplete;

  const EntryCard({
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: categoryColor.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and actions
              Row(
                children: [
                  // Type icon
                  _buildTypeIcon(),
                  const SizedBox(width: 8),
                  // Title
                  Expanded(
                    child: Text(
                      entry.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: entry.status == 'completed'
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Favorite icon
                  IconButton(
                    icon: Icon(
                      entry.isFavorite ? Icons.star : Icons.star_border,
                      color: entry.isFavorite ? Colors.amber : Colors.grey,
                    ),
                    onPressed: onToggleFavorite,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  // More options
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      if (entry.type == 'task' && entry.status != 'completed')
                        const PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 20),
                              SizedBox(width: 8),
                              Text('Mark Complete'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
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
              const SizedBox(height: 8),
              // Content preview
              Text(
                entry.content,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Footer with metadata
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Category chip
                  if (category != null)
                    Chip(
                      label: Text(
                        category.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: categoryColor.withOpacity(0.2),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  // Priority badge
                  _buildPriorityBadge(),
                  // Status badge
                  if (entry.type == 'task')
                    _buildStatusBadge(),
                  // Date
                  Chip(
                    label: Text(
                      _formatDate(entry.eventDate ?? entry.createdAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;

    switch (entry.type) {
      case 'event':
        icon = Icons.event;
        color = Colors.orange;
        break;
      case 'task':
        icon = Icons.task_alt;
        color = Colors.green;
        break;
      case 'note':
        icon = Icons.lightbulb;
        color = Colors.amber;
        break;
      default:
        icon = Icons.note;
        color = Colors.blue;
    }

    return Icon(icon, color: color, size: 24);
  }

  Widget _buildPriorityBadge() {
    Color color;
    String label;

    switch (entry.priority) {
      case 'urgent':
        color = Colors.red;
        label = 'URGENT';
        break;
      case 'high':
        color = Colors.orange;
        label = 'HIGH';
        break;
      case 'medium':
        color = Colors.blue;
        label = 'MEDIUM';
        break;
      default:
        color = Colors.grey;
        label = 'LOW';
    }

    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: color.withOpacity(0.2),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;
    IconData icon;

    switch (entry.status) {
      case 'completed':
        color = Colors.green;
        label = 'DONE';
        icon = Icons.check_circle;
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'IN PROGRESS';
        icon = Icons.pending;
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'CANCELLED';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = 'PENDING';
        icon = Icons.schedule;
    }

    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      avatar: Icon(icon, size: 16, color: color),
      backgroundColor: color.withOpacity(0.2),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (entryDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
