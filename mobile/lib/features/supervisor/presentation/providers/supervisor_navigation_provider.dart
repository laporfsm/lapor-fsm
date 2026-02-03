import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupervisorNavigationState {
  final int bottomNavIndex;
  final int staffTabIndex;

  const SupervisorNavigationState({
    this.bottomNavIndex = 0,
    this.staffTabIndex = 0,
  });

  SupervisorNavigationState copyWith({
    int? bottomNavIndex,
    int? staffTabIndex,
  }) {
    return SupervisorNavigationState(
      bottomNavIndex: bottomNavIndex ?? this.bottomNavIndex,
      staffTabIndex: staffTabIndex ?? this.staffTabIndex,
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

  void setStaffTabIndex(int index) {
    state = state.copyWith(staffTabIndex: index);
  }

  void navigateToActivityLog() {
    // Index 1 = Staff, Tab 0 = Activity Log (assuming layout)
    // Adjust logic if needed based on SupervisorTechnicianMainPage tabs
    state = state.copyWith(bottomNavIndex: 1, staffTabIndex: 0);
  }
}

final supervisorNavigationProvider =
    NotifierProvider<SupervisorNavigationNotifier, SupervisorNavigationState>(
      SupervisorNavigationNotifier.new,
    );
