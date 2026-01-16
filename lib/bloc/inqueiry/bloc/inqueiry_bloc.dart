import 'package:Texspin/bloc/inqueiry/bloc/inqueiry_event.dart';
import 'package:Texspin/bloc/inqueiry/bloc/inqueiry_state.dart';
import 'package:Texspin/services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InquiryBloc extends Bloc<InquiryEvent, InquiryState> {
  final ApiService _apiService;

  InquiryBloc({ApiService? apiService})
    : _apiService = apiService ?? ApiService(),
      super(InquiryInitial()) {
    on<FetchInquiries>(_onFetchInquiries);
    on<DeleteInquiry>(_onDeleteInquiry);
  }

  Future<void> _onFetchInquiries(
    FetchInquiries event,
    Emitter<InquiryState> emit,
  ) async {
    emit(InquiryLoading());

    try {
      final data = await _apiService.getInquiries();

      final inquiries = data['inquiries'] as List<dynamic>;
      emit(InquiryLoaded(inquiries));
    } catch (e) {
      emit(InquiryError(e.toString()));
    }
  }

  Future<void> _onDeleteInquiry(
    DeleteInquiry event,
    Emitter<InquiryState> emit,
  ) async {
    // Optimistically update UI if current state is Loaded
    if (state is InquiryLoaded) {
      final current = state as InquiryLoaded;
      final updatedList = current.inquiries
          .where(
            (item) => (item as Map<String, dynamic>)['id'] != event.inquiryId,
          )
          .toList();

      emit(InquiryLoaded(updatedList));
    }

    try {
      await _apiService.deleteInquiry(id: event.inquiryId);
      // If you want to re-fetch fresh data after delete, uncomment below:
      // add(FetchInquiries());
    } catch (e) {
      // Revert on error (optional – you may show a snackbar instead)
      add(FetchInquiries());
      // Or emit error state
      emit(InquiryError('Failed to delete inquiry: $e'));
    }
  }
}
