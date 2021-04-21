import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fluttersaurus/search/models/models.dart';
import 'package:fluttersaurus/search/search.dart';
import 'package:thesaurus_repository/thesaurus_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._thesaurusRepository)
      : assert(_thesaurusRepository != null),
        super(const SearchState.initial());

  final ThesaurusRepository _thesaurusRepository;

  @override
  Stream<Transition<SearchEvent, SearchState>> transformEvents(
    Stream<SearchEvent> events,
    transitionFn,
  ) {
    return events
        .debounceTime(const Duration(milliseconds: 300))
        .switchMap(transitionFn);
  }

  @override
  Stream<SearchState> mapEventToState(
    SearchEvent event,
  ) async* {
    if (event is SearchTermChanged) {
      if (event.term.isEmpty) {
        yield const SearchState.initial();
        return;
      }

      if (state.status != SearchStatus.success) {
        yield const SearchState.loading();
      }

      try {
        final results = await _thesaurusRepository.search(term: event.term);

        final suggestions =
            results.map((result) => Suggestion(result)).toList();

        yield SearchState.success(suggestions);
      } on Exception {
        yield const SearchState.failure();
      }
    }
  }
}
