import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/focus_session_model.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';
import 'category_provider.dart';

class FocusState {
  final int totalDurationSeconds;
  final int secondsRemaining;
  final bool isRunning;
  final bool isPaused;
  final TaskModel? selectedTask;

  const FocusState({
    required this.totalDurationSeconds,
    required this.secondsRemaining,
    this.isRunning = false,
    this.isPaused = false,
    this.selectedTask,
  });

  double get progress => totalDurationSeconds > 0
      ? (totalDurationSeconds - secondsRemaining) / totalDurationSeconds
      : 0.0;

  FocusState copyWith({
    int? totalDurationSeconds,
    int? secondsRemaining,
    bool? isRunning,
    bool? isPaused,
    TaskModel? selectedTask,
    bool clearTask = false,
  }) {
    return FocusState(
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      selectedTask: clearTask ? null : (selectedTask ?? this.selectedTask),
    );
  }
}

class FocusNotifier extends StateNotifier<FocusState> {
  final Ref ref;
  Timer? _timer;
  DateTime? _startedAt;

  FocusNotifier(this.ref)
      : super(const FocusState(
          totalDurationSeconds: 25 * 60,
          secondsRemaining: 25 * 60,
        ));

  void selectTask(TaskModel? task) {
    state = state.copyWith(selectedTask: task, clearTask: task == null);
  }

  void setDuration(int minutes) {
    _timer?.cancel();
    state = FocusState(
      totalDurationSeconds: minutes * 60,
      secondsRemaining: minutes * 60,
      selectedTask: state.selectedTask,
    );
  }

  void startTimer() {
    if (state.isRunning && !state.isPaused) return;

    _startedAt ??= DateTime.now();
    state = state.copyWith(isRunning: true, isPaused: false);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining > 1) {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      } else {
        _onTimerComplete();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void resumeTimer() {
    startTimer();
  }

  void resetTimer() {
    _timer?.cancel();
    _startedAt = null;
    state = FocusState(
      totalDurationSeconds: state.totalDurationSeconds,
      secondsRemaining: state.totalDurationSeconds,
      selectedTask: state.selectedTask,
    );
  }

  Future<void> completeSession() async {
    _timer?.cancel();
    final endedAt = DateTime.now();
    final started = _startedAt ?? endedAt.subtract(Duration(seconds: state.totalDurationSeconds - state.secondsRemaining));

    final session = FocusSessionModel(
      id: const Uuid().v4(),
      taskId: state.selectedTask?.id,
      taskTitle: state.selectedTask?.title ?? 'General Focus Session',
      durationMinutes: (state.totalDurationSeconds / 60).round(),
      completed: true,
      startedAt: started,
      endedAt: endedAt,
    );

    final repo = ref.read(repositoryProvider);
    await repo.insertFocusSession(session);

    await NotificationService.instance.showInstantNotification(
      id: 9999,
      title: '🎯 Focus Session Completed!',
      body: 'Great job staying focused on ${session.taskTitle}. Take a short break!',
    );

    resetTimer();
  }

  void _onTimerComplete() {
    completeSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final focusProvider =
    StateNotifierProvider<FocusNotifier, FocusState>((ref) {
  return FocusNotifier(ref);
});

final focusSessionsProvider = FutureProvider<List<FocusSessionModel>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getFocusSessions();
});
