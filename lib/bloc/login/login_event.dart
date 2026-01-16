import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginUserIdChanged extends LoginEvent {
  final String userId;

  const LoginUserIdChanged(this.userId);

  @override
  List<Object> get props => [userId];
}

class LoginPasswordChanged extends LoginEvent {
  final String password;

  const LoginPasswordChanged(this.password);

  @override
  List<Object> get props => [password];
}

class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}

class LoginRememberMeChanged extends LoginEvent {
  final bool rememberMe;

  const LoginRememberMeChanged(this.rememberMe);

  @override
  List<Object> get props => [rememberMe];
}

class LoginLoadSavedCredentials extends LoginEvent {
  const LoginLoadSavedCredentials();
}

class LoginReset extends LoginEvent {
  const LoginReset();
}

