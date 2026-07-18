import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  
  String _selectedPriorityFilter = 'All';
  bool _hideCompleted = false;
  bool _filterBySelectedDate = true; 

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagController = TextEditingController();
  final _collaboratorController = TextEditingController();
  
  String _selectedPriority = 'Normal';
  DateTime? _chosenDueDate = DateTime.now();
  TimeOfDay? _chosenDueTime;
  TimeOfDay? _chosenEndTime; 
  List<String> _tempCollaborators = [];

  final List<Color> _colorPalette = [
    const Color(0xFF7C3AED), // Purple
    const Color(0xFFEF4444), // Red
    const Color(0xFF10B981), // Emerald Green
    const Color(0xFF3B82F6), // Sky Blue
    const Color(0xFFF59E0B), // Amber Yellow
    const Color(0xFFEC4899), // Bubblegum Pink
  ];

  Color _selectedTagColor = const Color(0xFF10B981);
  Color _selectedTaskColor = const Color(0xFF1E293B);

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagController.dispose();
    _collaboratorController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent': return const Color(0xFFEF4444);
      case 'High': return const Color(0xFFF59E0B);
      case 'Normal': return const Color(0xFF3B82F6);
      case 'Low': return const Color(0xFF94A3B8);
      default: return const Color(0xFF64748B);
    }
  }

  String _formatTaskDuration(String? startStr, String? endStr) {
    if (startStr == null || startStr.isEmpty) return 'General';
    
    String formatTime(String timeStr) {
      try {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final dt = DateTime(2026, 1, 1, hour, minute);
        return DateFormat('h:mm a').format(dt);
      } catch (_) {
        return timeStr;
      }
    }

    String startFormatted = formatTime(startStr);
    if (endStr != null && endStr.isNotEmpty) {
      return '$startFormatted - ${formatTime(endStr)}';
    }
    return startFormatted;
  }

  // 🚀 UPDATED MODAL: Passing a DocumentSnapshot makes this function act as an "Edit Screen"
  void _showTaskFormSheet(BuildContext context, String userId, {DocumentSnapshot? existingTaskDoc}) {
    final isEditing = existingTaskDoc != null;

    if (isEditing) {
      final data = existingTaskDoc.data() as Map<String, dynamic>? ?? {};
      _titleController.text = data['title'] ?? '';
      _descController.text = data['description'] ?? '';
      _tagController.text = data['tagText'] ?? '';
      _selectedPriority = data['priority'] ?? 'Normal';
      _selectedTagColor = data['tagColorHex'] != null ? Color(data['tagColorHex']) : _colorPalette[2];
      _selectedTaskColor = data['taskColorHex'] != null ? Color(data['taskColorHex']) : const Color(0xFF1E293B);
      _tempCollaborators = List<String>.from(data['collaborators'] ?? []);
      
      if (data['dueDate'] != null) {
        _chosenDueDate = (data['dueDate'] as Timestamp).toDate();
      } else {
        _chosenDueDate = DateTime.now();
      }

      if (data['dueTime'] != null && data['dueTime'].toString().contains(':')) {
        final parts = data['dueTime'].toString().split(':');
        _chosenDueTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } else {
        _chosenDueTime = null;
      }

      if (data['endTime'] != null && data['endTime'].toString().contains(':')) {
        final parts = data['endTime'].toString().split(':');
        _chosenEndTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } else {
        _chosenEndTime = null;
      }
    } else {
      _tempCollaborators = [];
      _titleController.clear();
      _descController.clear();
      _tagController.clear();
      _selectedPriority = 'Normal';
      _selectedTagColor = _colorPalette[2]; 
      _selectedTaskColor = const Color(0xFF1E293B); 
      _chosenDueDate = _selectedDay ?? DateTime.now();
      _chosenDueTime = null;
      _chosenEndTime = null; 
    }

    _collaboratorController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24, left: 24, right: 24
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing ? 'Edit Task Details' : 'Add New Task', 
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Task Title')),
                    const SizedBox(height: 12),
                    TextField(controller: _descController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Notes / Details')),
                    const SizedBox(height: 16),
                    
                    Text('Custom Tag Name', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(controller: _tagController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('e.g. Chemistry, Coding')),
                    const SizedBox(height: 14),

                    Text('Pick Tag Color', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: _colorPalette.map((color) {
                        bool isSelected = _selectedTagColor.value == color.value;
                        return GestureDetector(
                          onTap: () => setModalState(() => _selectedTagColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    Text('Pick Task Card Background', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Color(0xFF1E293B),
                        const Color(0xFF0F172A),
                        const Color(0xFF2E1065),
                        const Color(0xFF064E3B),
                      ].map((cardBgColor) {
                        bool isSelected = _selectedTaskColor.value == cardBgColor.value;
                        return GestureDetector(
                          onTap: () => setModalState(() => _selectedTaskColor = cardBgColor),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected ? Border.all(color: const Color(0xFF7C3AED), width: 3) : Border.all(color: const Color(0xFF334155)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _collaboratorController, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Collaborator Email'))),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF7C3AED), size: 36),
                          onPressed: () {
                            if (_collaboratorController.text.contains('@')) {
                              setModalState(() {
                                _tempCollaborators.add(_collaboratorController.text.trim());
                                _collaboratorController.clear();
                              });
                            }
                          },
                        )
                      ],
                    ),
                    if (_tempCollaborators.isNotEmpty) Wrap(
                      spacing: 6,
                      children: _tempCollaborators.map((email) => Chip(
                        label: Text(email, style: const TextStyle(fontSize: 11, color: Colors.white)),
                        backgroundColor: const Color(0xFF0F172A),
                        onDeleted: () => setModalState(() => _tempCollaborators.remove(email)),
                      )).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    Text('Priority', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: ['Low', 'Normal', 'High', 'Urgent'].map((priority) {
                        bool isSel = _selectedPriority == priority;
                        return GestureDetector(
                          onTap: () => setModalState(() => _selectedPriority = priority),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? _getPriorityColor(priority).withOpacity(0.15) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSel ? _getPriorityColor(priority) : const Color(0xFF334155))
                            ),
                            child: Text(priority, style: GoogleFonts.outfit(color: isSel ? Colors.white : const Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(context: context, initialDate: _chosenDueDate ?? DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(2030));
                              if (picked != null) setModalState(() => _chosenDueDate = picked);
                            },
                            icon: const Icon(Icons.calendar_month, size: 14, color: Colors.white),
                            label: Text(_chosenDueDate == null ? 'Set Date' : DateFormat('MMM d').format(_chosenDueDate!), style: const TextStyle(color: Colors.white, fontSize: 12)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(context: context, initialTime: _chosenDueTime ?? TimeOfDay.now());
                              if (picked != null) setModalState(() => _chosenDueTime = picked);
                            },
                            icon: const Icon(Icons.access_time_filled, size: 14, color: Colors.white),
                            label: Text(_chosenDueTime == null ? 'Start Time' : _chosenDueTime!.format(context), style: const TextStyle(color: Colors.white, fontSize: 12)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(context: context, initialTime: _chosenEndTime ?? TimeOfDay.now());
                              if (picked != null) setModalState(() => _chosenEndTime = picked);
                            },
                            icon: const Icon(Icons.history_toggle_off_rounded, size: 14, color: Colors.white),
                            label: Text(_chosenEndTime == null ? 'End Time' : _chosenEndTime!.format(context), style: const TextStyle(color: Colors.white, fontSize: 12)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (_titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a task title!'), backgroundColor: Colors.redAccent)
                          );
                          return;
                        }

                        try {
                          if (isEditing) {
                            await _firestoreService.updateTask(
                              docId: existingTaskDoc.id,
                              title: _titleController.text.trim(),
                              description: _descController.text.trim(),
                              priority: _selectedPriority,
                              tagText: _tagController.text.trim().isEmpty ? 'General' : _tagController.text.trim(),
                              tagColorHex: _selectedTagColor.value,
                              taskColorHex: _selectedTaskColor.value,
                              collaborators: _tempCollaborators,
                              dueDate: _chosenDueDate,
                              dueTime: _chosenDueTime != null ? '${_chosenDueTime!.hour}:${_chosenDueTime!.minute}' : null,
                              endTime: _chosenEndTime != null ? '${_chosenEndTime!.hour}:${_chosenEndTime!.minute}' : null,
                            );
                          } else {
                            await _firestoreService.addTask(
                              userId: userId,
                              title: _titleController.text.trim(),
                              description: _descController.text.trim(),
                              priority: _selectedPriority,
                              tagText: _tagController.text.trim().isEmpty ? 'General' : _tagController.text.trim(),
                              tagColorHex: _selectedTagColor.value,
                              taskColorHex: _selectedTaskColor.value,
                              collaborators: _tempCollaborators,
                              dueDate: _chosenDueDate ?? DateTime.now(),
                              dueTime: _chosenDueTime != null ? '${_chosenDueTime!.hour}:${_chosenDueTime!.minute}' : null,
                              endTime: _chosenEndTime != null ? '${_chosenEndTime!.hour}:${_chosenEndTime!.minute}' : null, 
                            );
                          }
                          
                          _titleController.clear();
                          _descController.clear();
                          _tagController.clear();
                          
                          if (context.mounted) Navigator.pop(context);
                        } catch (error) {
                          print("🚨 FIRESTORE ACTION FAILED: $error");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(isEditing ? 'Update Task' : 'Save Task', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF334155))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF334155))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskFormSheet(context, user.uid),
        backgroundColor: const Color(0xFF7C3AED),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getTasks(user.uid, user.email ?? ''),
        builder: (context, snapshot) {
          int totalTasks = 0;
          int completedTasks = 0;
          List<DocumentSnapshot> displayTasks = [];

          if (snapshot.hasData) {
            final docs = snapshot.data!.docs;
            totalTasks = docs.length;
            completedTasks = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return data != null && data['isCompleted'] == true;
            }).length;

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) continue;
              bool isCompleted = data['isCompleted'] == true;
              String priority = data['priority'] ?? 'Normal';
              
              if (_hideCompleted && isCompleted) continue;
              if (_selectedPriorityFilter != 'All' && priority != _selectedPriorityFilter) continue;
              
              if (_filterBySelectedDate && _selectedDay != null) {
                if (data['dueDate'] != null) {
                  DateTime taskTargetDate = (data['dueDate'] as Timestamp).toDate();
                  DateTime checkTarget = DateTime(taskTargetDate.year, taskTargetDate.month, taskTargetDate.day);
                  DateTime selectedTarget = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
                  if (checkTarget != selectedTarget) continue;
                } else {
                  continue; 
                }
              }
              displayTasks.add(doc);
            }
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 70,
                pinned: true,
                backgroundColor: const Color(0xFF1E293B),
                title: Text('Workspace Dashboard', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard('Total Tasks', totalTasks.toString(), Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard('Completed', '$completedTasks/$totalTasks', const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('View Selected Date'),
                        selected: _filterBySelectedDate == true,
                        selectedColor: const Color(0xFF7C3AED),
                        backgroundColor: const Color(0xFF1E293B),
                        labelStyle: GoogleFonts.outfit(color: Colors.white),
                        onSelected: (val) { if (val) setState(() => _filterBySelectedDate = true); },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Show All Tasks'),
                        selected: _filterBySelectedDate == false,
                        selectedColor: const Color(0xFF7C3AED),
                        backgroundColor: const Color(0xFF1E293B),
                        labelStyle: GoogleFonts.outfit(color: Colors.white),
                        onSelected: (val) { if (val) setState(() => _filterBySelectedDate = false); },
                      ),
                      const SizedBox(width: 16),
                      Container(width: 1, height: 24, color: const Color(0xFF334155)),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('Hide Completed'),
                        selected: _hideCompleted,
                        selectedColor: const Color(0xFF7C3AED).withOpacity(0.3),
                        backgroundColor: const Color(0xFF1E293B),
                        labelStyle: GoogleFonts.outfit(color: _hideCompleted ? Colors.white : const Color(0xFF94A3B8)),
                        onSelected: (val) => setState(() => _hideCompleted = val),
                      ),
                      const SizedBox(width: 6),
                      ...['All', 'Urgent', 'High', 'Normal', 'Low'].map((pFilter) {
                        bool isSel = _selectedPriorityFilter == pFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(pFilter),
                            selected: isSel,
                            selectedColor: const Color(0xFF7C3AED),
                            backgroundColor: const Color(0xFF1E293B),
                            labelStyle: GoogleFonts.outfit(color: isSel ? Colors.white : const Color(0xFF94A3B8)),
                            onSelected: (val) { if (val) setState(() => _selectedPriorityFilter = pFilter); },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF334155))),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2025, 1, 1), lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay, calendarFormat: CalendarFormat.week,
                    headerStyle: HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) => setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; }),
                    calendarStyle: CalendarStyle(
                      todayDecoration: const BoxDecoration(color: Color(0xFF334155), shape: BoxShape.circle),
                      selectedDecoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle),
                      defaultTextStyle: GoogleFonts.outfit(color: Colors.white), weekendTextStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ),
              displayTasks.isEmpty
                  ? const SliverFillRemaining(child: Center(child: Text("No matching tasks found.", style: TextStyle(color: Colors.white70))))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          child: _buildTaskTile(displayTasks[idx], user.uid),
                        ),
                        childCount: displayTasks.length,
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskTile(DocumentSnapshot doc, String userId) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    bool isCompleted = data['isCompleted'] == true;
    String priority = data['priority'] ?? 'Normal';
    String tagText = data['tagText'] ?? 'General';
    Color tagColor = data['tagColorHex'] != null ? Color(data['tagColorHex']) : const Color(0xFF10B981);
    Color taskBgColor = data['taskColorHex'] != null ? Color(data['taskColorHex']) : const Color(0xFF1E293B);
    List<dynamic> collabs = data['collaborators'] ?? [];
    
    String durationLabel = _formatTaskDuration(data['dueTime'], data['endTime']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: taskBgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF334155))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Checkbox(value: isCompleted, activeColor: const Color(0xFF10B981), onChanged: (_) => _firestoreService.toggleTaskStatus(doc.id, isCompleted)),
        title: Text(data['title'] ?? 'Untitled', style: GoogleFonts.outfit(color: isCompleted ? const Color(0xFF64748B) : Colors.white, fontWeight: FontWeight.bold, fontSize: 15, decoration: isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['description'] != null && data['description'].isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2.0), child: Text(data['description'], style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13))),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: tagColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: tagColor.withOpacity(0.5))),
                  child: Text(tagText, style: GoogleFonts.outfit(color: tagColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                if (collabs.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.people, size: 14, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 4),
                  Text('${collabs.length} shared', style: GoogleFonts.outfit(color: const Color(0xFF7C3AED), fontSize: 12, fontWeight: FontWeight.bold)),
                ]
              ],
            )
          ],
        ),
        trailing: SizedBox(
          width: 155, // 🚀 Increased width slightly to accommodate longer text
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 🚀 Wrapped in Expanded + set maxLines/overflow so it shrinks or truncates instead of breaking the layout
              Expanded(
                child: Text(
                  durationLabel, 
                  style: GoogleFonts.outfit(color: _getPriorityColor(priority), fontSize: 11, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent, size: 22),
                onPressed: () => _showTaskFormSheet(context, userId, existingTaskDoc: doc),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: () => _firestoreService.deleteTask(doc.id),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), 
        borderRadius: BorderRadius.all(Radius.circular(20)), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            value, 
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}