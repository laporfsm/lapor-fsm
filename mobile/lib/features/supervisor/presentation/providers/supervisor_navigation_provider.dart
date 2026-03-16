import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupervisorNavigationState {
  final int bottomNavIndex;

  const SupervisorNavigationState({
    this.bottomNavIndex = 0,
  });

  SupervisorNavigationState copyWith({
    int? bottomNavIndex,
  }) {
    return SupervisorNavigationState(
      bottomNavIndex: bottomNavIndex ?? this.bottomNavIndex,
    );
  }
}

class SupervisorNavigationNotifier extends Notifier<SupervisorNavigationState> {
  @override
  SupervisorNavigationState build() {
    return const SupervisorNavigationState();
  }

  void setBottomNavIndex(int index) {
    state = state.copyWith(bottomNavIndex: index);
  }
}

final supervisorNavigationProvider =
    NotifierProvider<SupervisorNavigationNotifier, SupervisorNavigationState>(
      SupervisorNavigationNotifier.new,
    );
