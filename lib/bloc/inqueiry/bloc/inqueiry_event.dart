// lib/blocs/inquiry/inquiry_event.dart

abstract class InquiryEvent {}

class FetchInquiries extends InquiryEvent {}

class DeleteInquiry extends InquiryEvent {
  final String inquiryId;
  DeleteInquiry(this.inquiryId);
}
