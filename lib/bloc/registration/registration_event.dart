import 'package:equatable/equatable.dart';

abstract class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => [];
}

class RegistrationNameChanged extends RegistrationEvent {
  final String name;

  const RegistrationNameChanged(this.name);

  @override
  List<Object> get props => [name];
}

class RegistrationIdChanged extends RegistrationEvent {
  final String id;

  const RegistrationIdChanged(this.id);

  @override
  List<Object> get props => [id];
}

class RegistrationPasswordChanged extends RegistrationEvent {
  final String password;

  const RegistrationPasswordChanged(this.password);

  @override
  List<Object> get props => [password];
}

class RegistrationSubmitted extends RegistrationEvent {
  const RegistrationSubmitted();
}

class RegistrationReset extends RegistrationEvent {
  const RegistrationReset();
}

