enum UserRole { admin, branch_manager, staff }

extension UserRoleX on UserRole {
  String get label => switch (this) {
    UserRole.admin          => 'Admin',
    UserRole.branch_manager => 'Branch Manager',
    UserRole.staff          => 'Staff',
  };

  bool get isAdmin   => this == UserRole.admin;
  bool get isManager => this == UserRole.branch_manager;
  bool get canWrite  => this == UserRole.admin || this == UserRole.branch_manager;
}
