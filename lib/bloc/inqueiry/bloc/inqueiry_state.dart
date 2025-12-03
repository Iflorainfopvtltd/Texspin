// lib/blocs/inquiry/inquiry_state.dart

abstract class InquiryState {}

class InquiryInitial extends InquiryState {}

class InquiryLoading extends InquiryState {}

class InquiryLoaded extends InquiryState {
  final List<dynamic> inquiries;
  InquiryLoaded(this.inquiries);
}

class InquiryError extends InquiryState {
  final String message;
  InquiryError(this.message);
}
