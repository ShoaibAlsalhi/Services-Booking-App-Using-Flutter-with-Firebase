part of 'account_upgrade_cubit.dart';

abstract class AccountUpgradeState {
  const AccountUpgradeState();
}

class AccountUpgradeInitial extends AccountUpgradeState {}

class AccountUpgradeLoading extends AccountUpgradeState {}

class AccountUpgradeSuccess extends AccountUpgradeState {}

class AccountUpgradeError extends AccountUpgradeState {
  final String errorMessage;

  const AccountUpgradeError(this.errorMessage);
}
