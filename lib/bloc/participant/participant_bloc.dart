import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:delphis_app/bloc/discussion/discussion_bloc.dart';
import 'package:delphis_app/data/repository/flair.dart';
import 'package:delphis_app/data/repository/participant.dart';
import 'package:delphis_app/design/colors.dart';
import 'package:delphis_app/tracking/constants.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_segment/flutter_segment.dart';

part 'participant_event.dart';
part 'participant_state.dart';

class ParticipantBloc extends Bloc<ParticipantEvent, ParticipantState> {
  final ParticipantRepository repository;
  final DiscussionBloc discussionBloc;

  StreamSubscription<DiscussionState> discussionBlocSubscription;

  ParticipantBloc({
    @required this.repository,
    @required this.discussionBloc,
  }) : super(ParticipantInitial()) {
    if (!(this.discussionBloc.state is DiscussionLoadedState) ||
        this.discussionBloc.state.getDiscussion() == null) {
      discussionBlocSubscription =
          this.discussionBloc.listen((DiscussionState state) {
        if (state is DiscussionLoadedState) {
          this.add(ParticipantEventReceivedParticipant(
              participant: state.getDiscussion().meParticipant));
          discussionBlocSubscription.cancel();
        }
      });
    } else if (this.discussionBloc.state.getDiscussion() != null) {
      this.add(
        ParticipantEventReceivedParticipant(
            participant:
                this.discussionBloc.state.getDiscussion().meParticipant),
      );
    } else {
      // Error state..
    }
  }

  void dispose() {
    this.discussionBlocSubscription.cancel();
  }

  @override
  Stream<ParticipantState> mapEventToState(
    ParticipantEvent event,
  ) async* {
    final currentState = this.state;
    if (event is ParticipantEventReceivedParticipant) {
      yield ParticipantLoaded(
          participant: event.participant, isUpdating: false);
    } else if (event is ParticipantEventUpdateParticipant &&
        !(currentState is ParticipantLoaded && currentState.isUpdating)) {
      yield ParticipantLoaded(
          participant: currentState.participant, isUpdating: true);
      var updatedParticipant;
      try {
        updatedParticipant = await this.repository.updateParticipant(
              discussionID: discussionBloc.state.getDiscussion()?.id,
              participantID: currentState.participant.id,
              gradientName: event.gradientName,
              isAnonymous:
                  event.isAnonymous ?? currentState.participant.isAnonymous,
              isUnsetGradient: event.isUnsetGradient ?? false,
            );
      } catch (err) {
        // What to do about this error?
        yield ParticipantLoaded(
            participant: currentState.participant, isUpdating: false);
        if (event.onError != null) event.onError(err);
        return;
      }
      this
          .discussionBloc
          .add(MeParticipantUpdatedEvent(meParticipant: updatedParticipant));
      yield ParticipantLoaded(
        participant: updatedParticipant,
        isUpdating: false,
      );
      if (event.onSuccess != null) event.onSuccess();
    } else if (event is ParticipantEventAddParticipant) {
      yield ParticipantLoaded(participant: null, isUpdating: true);
      final addedParticipant = await this.repository.addDiscussionParticipant(
          event.discussionID,
          event.userID,
          gradientColorFromGradientName(event.gradientName),
          event.hasJoined,
          event.isAnonymous);

      this
          .discussionBloc
          .add(MeParticipantUpdatedEvent(meParticipant: addedParticipant));
      yield ParticipantLoaded(
        participant: addedParticipant,
        isUpdating: false,
      );
    } else if (event is ParticipantJoinedDiscussion) {
      yield ParticipantLoaded(
          participant: currentState.participant, isUpdating: true);
      var updatedParticipant;
      try {
        updatedParticipant = await this.repository.participantJoinedDiscussion(
              discussionID: discussionBloc.state.getDiscussion()?.id,
              participantID: event.participant.id,
            );
        Segment.track(
            eventName: ChathamTrackingEventNames.PARTICIPANT_JOINED_DISCUSSION,
            properties: {
              'discussionID': discussionBloc.state.getDiscussion()?.id,
              'participantID': event.participant.id,
              'numParticipants':
                  discussionBloc.state.getDiscussion().participants.length,
            });
      } catch (err) {
        Segment.track(
            eventName:
                ChathamTrackingEventNames.PARTICIPANT_JOINED_DISCUSSION_FAILURE,
            properties: {
              'discussionID': discussionBloc.state.getDiscussion()?.id,
              'participantID': event.participant.id,
            });
        yield ParticipantLoaded(
            participant: currentState.participant, isUpdating: false);
        return;
      }
      this
          .discussionBloc
          .add(MeParticipantUpdatedEvent(meParticipant: updatedParticipant));
      yield ParticipantLoaded(
          participant: updatedParticipant, isUpdating: false);
    }
  }
}
