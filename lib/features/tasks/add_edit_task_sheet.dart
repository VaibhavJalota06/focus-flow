import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/task_model.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/task_provider.dart';

class AddEditTaskSheet extends ConsumerStatefulWidget {
  final TaskModel? taskToEdit;
  final bool initialIsInbox;
  final DateTime? initialDate;

  const AddEditTaskSheet({
    super.key,
    this.taskToEdit,
    this.initialIsInbox = false,
    this.initialDate,
  });

  @override
  ConsumerState<AddEditTaskSheet> createState() => _AddEditTaskSheetState();
}

class _AddEditTaskSheetState extends ConsumerState<AddEditTaskSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _notesController;
  final TextEditingController _subtaskInputController = TextEditingController();

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  late DateTime _selectedDate;
  String? _startTime;
  String? _dueTime;
  late TaskPriority _priority;
  late String _categoryId;
  String? _reminderTime;
  String? _recurrenceRule;
  late bool _isInbox;
  List<SubtaskModel> _subtasks = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    final t = widget.taskToEdit;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _notesController = TextEditingController(text: t?.notes ?? '');

    _selectedDate = t?.date ?? widget.initialDate ?? DateTime.now();
    _startTime = t?.startTime;
    _dueTime = t?.dueTime;
    _priority = t?.priority ?? TaskPriority.medium;
    _categoryId = t?.categoryId ?? 'other';
    _reminderTime = t?.reminderTime;
    _recurrenceRule = t?.recurrenceRule;
    _isInbox = t?.isInbox ?? widget.initialIsInbox;
    _subtasks = t?.subtasks != null ? List.from(t!.subtasks) : [];
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('[SpeechToText] Status: $status');
          if (status == 'notListening' || status == 'done') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          debugPrint('[SpeechToText] Error: ${errorNotification.errorMsg}');
          if (mounted) {
            setState(() => _isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speech error: ${errorNotification.errorMsg}'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[SpeechToText] Init failed: $e');
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      if (!_speechEnabled) {
        await _initSpeech();
      }
      if (_speechEnabled) {
        if (mounted) setState(() => _isListening = true);
        await _speechToText.listen(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          onResult: (result) {
            if (mounted && result.recognizedWords.isNotEmpty) {
              setState(() {
                _titleController.text = result.recognizedWords;
                _titleController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _titleController.text.length),
                );
              });
            }
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎙️ Voice dictation unavailable on this device or platform'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    _subtaskInputController.dispose();
    super.dispose();
  }

  void _saveTask() {
    FocusScope.of(context).unfocus();
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final finalReminderTime =
        (_dueTime != null && _reminderTime == null) ? 'EXACT' : _reminderTime;

    final notifier = ref.read(taskProvider.notifier);

    // Dismiss sheet immediately for 0ms perceptible lag
    Navigator.of(context).pop();

    if (widget.taskToEdit != null) {
      final updated = widget.taskToEdit!.copyWith(
        title: title,
        description: _descController.text.trim(),
        date: _selectedDate,
        startTime: _startTime,
        clearStartTime: _startTime == null,
        dueTime: _dueTime,
        clearDueTime: _dueTime == null,
        priority: _priority,
        categoryId: _categoryId,
        reminderTime: finalReminderTime,
        clearReminderTime: finalReminderTime == null,
        recurrenceRule: _recurrenceRule,
        clearRecurrenceRule: _recurrenceRule == null,
        notes: _notesController.text.trim(),
        clearNotes: _notesController.text.trim().isEmpty,
        isInbox: _isInbox,
        subtasks: _subtasks,
      );
      notifier.updateTask(updated).ignore();
    } else {
      notifier.addTask(
        title: title,
        description: _descController.text.trim(),
        date: _selectedDate,
        startTime: _startTime,
        dueTime: _dueTime,
        priority: _priority,
        categoryId: _categoryId,
        reminderTime: finalReminderTime,
        recurrenceRule: _recurrenceRule,
        notes: _notesController.text.trim(),
        isInbox: _isInbox,
        subtasks: _subtasks,
      ).ignore();
    }
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime({required bool isDue}) async {
    FocusScope.of(context).unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isDue) {
          _dueTime = formatted;
          _reminderTime ??= 'EXACT';
        } else {
          _startTime = formatted;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
              // Sheet Header handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Action bar (Title + Save)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.taskToEdit == null ? 'Create New Task' : 'Edit Task',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (_isListening)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.graphic_eq_rounded, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '🎙️ Listening... Speak your task title now!',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Task Title Input (Autofocused)
                    TextField(
                      controller: _titleController,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _saveTask(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Listening... Speak now!' : 'What needs to be done?',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                            color: _isListening ? Colors.red : theme.colorScheme.primary,
                          ),
                          tooltip: 'Dictate Task Title',
                          onPressed: _toggleListening,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Description Input
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Add description or details...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subtasks / Checklist
                    Text(
                      'Subtasks / Checklist',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_subtasks.isNotEmpty)
                      Column(
                        children: _subtasks.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final subtask = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: subtask.isCompleted,
                                  onChanged: (val) {
                                    setState(() {
                                      _subtasks[idx] = subtask.copyWith(isCompleted: val ?? false);
                                    });
                                  },
                                  activeColor: theme.colorScheme.primary,
                                ),
                                Expanded(
                                  child: Text(
                                    subtask.title,
                                    style: TextStyle(
                                      decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _subtasks.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subtaskInputController,
                            decoration: InputDecoration(
                              hintText: 'Add a step/subtask...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onSubmitted: (text) {
                              if (text.trim().isNotEmpty) {
                                setState(() {
                                  _subtasks.add(SubtaskModel(
                                    id: const Uuid().v4(),
                                    title: text.trim(),
                                  ));
                                  _subtaskInputController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () {
                            final text = _subtaskInputController.text.trim();
                            if (text.isNotEmpty) {
                              setState(() {
                                _subtasks.add(SubtaskModel(
                                  id: const Uuid().v4(),
                                  title: text,
                                ));
                                _subtaskInputController.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Date & Time pickers
                    Text(
                      'Schedule & Reminder',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today_rounded, size: 18),
                            label: Text(DateFormat('E, MMM d').format(_selectedDate)),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickTime(isDue: true),
                            icon: const Icon(Icons.access_time_rounded, size: 18),
                            label: Text(_dueTime ?? 'Due Time'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Priority Selector Chips
                    Text(
                      'Priority Level',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      children: TaskPriority.values.map((p) {
                        final isSelected = _priority == p;
                        return ChoiceChip(
                          showCheckmark: false,
                          selectedColor: theme.colorScheme.primary,
                          label: Text(p.label),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _priority = p);
                          },
                          avatar: Icon(
                            Icons.circle,
                            size: 12,
                            color: isSelected ? Colors.white : p.color,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Category Dropdown/Selector
                    Text(
                      'Category',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final isSelected = _categoryId == cat.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              showCheckmark: false,
                              selectedColor: theme.colorScheme.primary,
                              label: Text(cat.name),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                              avatar: Icon(
                                cat.icon,
                                size: 16,
                                color: isSelected ? Colors.white : cat.color,
                              ),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) setState(() => _categoryId = cat.id);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Recurrence Selector
                    DropdownButtonFormField<String>(
                      initialValue: _recurrenceRule,
                      decoration: InputDecoration(
                        labelText: 'Repeat Task',
                        prefixIcon: Icon(Icons.repeat_rounded, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('No Repeat (One-time)')),
                        DropdownMenuItem(value: 'DAILY', child: Text('Every Day 🔁')),
                        DropdownMenuItem(value: 'WEEKDAYS', child: Text('Weekdays (Mon-Fri) 📅')),
                        DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly 📆')),
                        DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly 🗓️')),
                        DropdownMenuItem(value: 'CUSTOM:1,3,5', child: Text('Mon + Wed + Fri ⭐')),
                      ],
                      onChanged: (val) => setState(() => _recurrenceRule = val),
                    ),

                    const SizedBox(height: 16),

                    // Reminder Selector
                    DropdownButtonFormField<String>(
                      initialValue: _reminderTime,
                      decoration: InputDecoration(
                        labelText: 'Reminder Alert',
                        prefixIcon: Icon(Icons.notifications_active_rounded, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('No Reminder')),
                        DropdownMenuItem(value: 'EXACT', child: Text('At exact due time ⏰')),
                        DropdownMenuItem(value: '10_MIN_BEFORE', child: Text('10 minutes before 🔔')),
                        DropdownMenuItem(value: '30_MIN_BEFORE', child: Text('30 minutes before 🔔')),
                        DropdownMenuItem(value: '1_HOUR_BEFORE', child: Text('1 hour before 🔔')),
                      ],
                      onChanged: (val) => setState(() => _reminderTime = val),
                    ),

                    const SizedBox(height: 16),

                    // Notes Section
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
  }
}
