import 'package:equatable/equatable.dart';

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordUserIdChanged extends ForgotPasswordEvent {
  final String userId;

  const ForgotPasswordUserIdChanged(this.userId);

  @override
  List<Object> get props => [userId];
}

class ForgotPasswordSubmitted extends ForgotPasswordEvent {
  const ForgotPasswordSubmitted();
}

class ForgotPasswordReset extends ForgotPasswordEvent {
  const ForgotPasswordReset();
}

