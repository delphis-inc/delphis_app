import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:json_annotation/json_annotation.dart' as JsonAnnotation;

import 'package:delphis_app/bloc/gql_client/gql_client_bloc.dart';
import 'package:delphis_app/data/provider/mutations.dart';
import 'package:delphis_app/data/provider/queries.dart';
import 'package:delphis_app/data/repository/user_profile.dart';
import 'package:delphis_app/design/colors.dart';

import 'discussion.dart';
import 'entity.dart';
import 'flair.dart';
import 'post.dart';
import 'viewer.dart';

part 'participant.g.dart';

const MAX_ATTEMPTS = 3;
const BACKOFF = 1;

class ParticipantRepository {
  final GqlClientBloc clientBloc;

  const ParticipantRepository({@required this.clientBloc});

  Future<List<Participant>> getParticipantsForDiscussion(String discussionID,
      {int attempt = 1}) async {
    final client = this.clientBloc.getClient();

    if (client == null && attempt <= MAX_ATTEMPTS) {
      return Future.delayed(Duration(seconds: BACKOFF * attempt), () {
        return getParticipantsForDiscussion(discussionID, attempt: attempt + 1);
      });
    } else if (client == null) {
      throw Exception(
          "Failed to get discussion because backend connection is severed");
    }

    final query = ParticipantsForDiscussionQuery(discussionID: discussionID);

    final QueryResult result = await client.query(QueryOptions(
      documentNode: gql(query.query()),
      variables: {
        'id': discussionID,
      },
    ));

    if (result.hasException) {
      throw result.exception;
    }
    return query.parseResult(result.data);
  }

  Future<Participant> updateParticipant(
      {@required String discussionID,
      @required String participantID,
      GradientName gradientName,
      bool isAnonymous = false,
      bool isUnsetGradient = false,
      int attempt = 1}) async {
    final client = this.clientBloc.getClient();

    if (client == null && attempt <= MAX_ATTEMPTS) {
      return Future.delayed(Duration(seconds: BACKOFF * attempt), () {
        return updateParticipant(
            discussionID: discussionID,
            participantID: participantID,
            gradientName: gradientName,
            isAnonymous: isAnonymous,
            isUnsetGradient: isUnsetGradient,
            attempt: attempt + 1);
      });
    } else if (client == null) {
      throw Exception(
          "Failed to get discussion because backend connection is severed");
    }

    final mutation = UpdateParticipantGQLMutation(
        discussionID: discussionID,
        participantID: participantID,
        gradientName: gradientName,
        isAnonymous: isAnonymous,
        isUnsetGradient: isUnsetGradient);
    final QueryResult result = await client.mutate(
      MutationOptions(
        documentNode: gql(mutation.mutation()),
        variables: {
          'discussionID': discussionID,
          'participantID': participantID,
          'updateInput': mutation.createInputObject(),
        },
        update: (Cache cache, QueryResult result) {
          return cache;
        },
      ),
    );

    if (result.hasException) {
      throw result.exception;
    }

    return mutation.parseResult(result.data);
  }

  Future<Participant> participantJoinedDiscussion(
      {@required String discussionID,
      @required String participantID,
      int attempt = 1}) async {
    final client = this.clientBloc.getClient();

    if (client == null && attempt <= MAX_ATTEMPTS) {
      return Future.delayed(Duration(seconds: BACKOFF * attempt), () {
        return participantJoinedDiscussion(
            discussionID: discussionID,
            participantID: participantID,
            attempt: attempt + 1);
      });
    } else if (client == null) {
      throw Exception(
          "Failed to get discussion because backend connection is severed");
    }
    final mutation = UpdateParticipantGQLMutation(
        discussionID: discussionID,
        participantID: participantID,
        hasJoined: true);
    final QueryResult result = await client.mutate(
      MutationOptions(
        documentNode: gql(mutation.mutation()),
        variables: {
          'discussionID': discussionID,
          'participantID': participantID,
          'updateInput': mutation.createInputObject(),
        },
        update: (Cache cache, QueryResult result) {
          return cache;
        },
      ),
    );

    if (result.hasException) {
      throw result.exception;
    }

    return mutation.parseResult(result.data);
  }

  Future<Participant> addDiscussionParticipant(String discussionID,
      String userID, String gradientColor, bool hasJoined, bool isAnonymous,
      {int attempt = 1}) async {
    final client = this.clientBloc.getClient();

    if (client == null && attempt <= MAX_ATTEMPTS) {
      return Future.delayed(Duration(seconds: BACKOFF * attempt), () {
        return addDiscussionParticipant(
            discussionID, userID, gradientColor, hasJoined, isAnonymous,
            attempt: attempt + 1);
      });
    } else if (client == null) {
      throw Exception(
          "Failed to get discussion because backend connection is severed");
    }
    final mutation = AddDiscussionParticipantGQLMutation(
      discussionID: discussionID,
      userID: userID,
      gradientColor: gradientColor,
      hasJoined: hasJoined,
      isAnonymous: isAnonymous,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
          documentNode: gql(mutation.mutation()),
          variables: {
            'discussionID': discussionID,
            'userID': userID,
            'discussionParticipantInput': mutation.createInputObject(),
          },
          update: (Cache cache, QueryResult result) {
            return cache;
          }),
    );

    if (result.hasException) {
      throw result.exception;
    }

    return mutation.parseResult(result.data);
  }

  Future<Participant> banParticipant(
      Discussion discussion, Participant participant,
      {int attempt = 1}) async {
    final client = this.clientBloc.getClient();

    if (client == null && attempt <= MAX_ATTEMPTS) {
      return Future.delayed(Duration(seconds: BACKOFF * attempt), () {
        return banParticipant(discussion, participant, attempt: attempt + 1);
      });
    } else if (client == null) {
      throw Exception(
          "Failed to banParticipant to discussion because backend connection is severed");
    }

    final mutation = BanParticipantMutation(
        discussionID: discussion.id, participantID: participant.id);
    final QueryResult result = await client.mutate(
      MutationOptions(
        documentNode: gql(mutation.mutation()),
        variables: {
          'discussionID': discussion.id,
          'participantID': participant.id,
        },
      ),
    );

    if (result.hasException) {
      throw result.exception;
    }
    return mutation.parseResult(result.data);
  }

  Future<List<Participant>> muteParticipants(
      Discussion discussion, List<Participant> participants, int muteForSeconds,
      {int attempt = 1}) async {
    final client = this.clientBloc.getClient();

    if (client == null && attempt <= MAX_ATTEMPTS) {
      return Future.delayed(Duration(seconds: BACKOFF * attempt), () {
        return muteParticipants(discussion, participants, muteForSeconds,
            attempt: attempt + 1);
      });
    } else if (client == null) {
      throw Exception(
          "Failed to muteParticipants to discussion because backend connection is severed");
    }

    var idList = participants.map((e) => e.id).toList();
    final mutation = MuteParticipantsMutation(
      discussionID: discussion.id,
      participantIDs: idList,
      muteForSeconds: muteForSeconds,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        documentNode: gql(mutation.mutation()),
        variables: {
          'discussionID': discussion.id,
          'participantIDs': idList,
          'mutedForSeconds': muteForSeconds,
        },
      ),
    );

    if (result.hasException) {
      throw result.exception;
    }
    return mutation.parseResult(result.data);
  }

  Future<List<Participant>> unmuteParticipants(
      Discussion discussion, List<Participant> participants,
      {int attempt = 1}) async {
    final client = this.clientBloc.getClient();

    if (client == null && attempt <= MAX_ATTEMPTS) {
      return Future.delayed(Duration(seconds: BACKOFF * attempt), () {
        return unmuteParticipants(discussion, participants,
            attempt: attempt + 1);
      });
    } else if (client == null) {
      throw Exception(
          "Failed to unmuteParticipants to discussion because backend connection is severed");
    }

    var idList = participants.map((e) => e.id).toList();
    final mutation = UnmuteParticipantsMutation(
        discussionID: discussion.id, participantIDs: idList);
    final QueryResult result = await client.mutate(
      MutationOptions(
        documentNode: gql(mutation.mutation()),
        variables: {
          'discussionID': discussion.id,
          'participantIDs': idList,
        },
      ),
    );

    if (result.hasException) {
      throw result.exception;
    }
    return mutation.parseResult(result.data);
  }
}

@JsonAnnotation.JsonSerializable()
class Participant extends Equatable implements Entity {
  final String id;
  final int participantID;
  final Discussion discussion;
  final Viewer viewer;
  final List<Post> posts;
  final bool isAnonymous;
  final bool isBanned;
  final String gradientColor;
  final bool hasJoined;
  final UserProfile userProfile;
  final Participant inviter;
  final DateTime mutedUntil;
  final String anonDisplayName;

  List<Object> get props =>
      [participantID, discussion, viewer, posts, hasJoined, anonDisplayName];

  const Participant({
    this.id,
    this.participantID,
    this.discussion,
    this.viewer,
    this.posts,
    this.isAnonymous,
    this.gradientColor,
    this.hasJoined,
    this.userProfile,
    this.inviter,
    this.isBanned,
    this.anonDisplayName,
    this.mutedUntil,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    var parsed = _$ParticipantFromJson(json);
    if (json['mutedForSeconds'] != null) {
      var seconds = json['mutedForSeconds'] as int;
      return parsed.copyWith(
        mutedUntil: DateTime.now().add(Duration(seconds: seconds)),
      );
    }
    return parsed;
  }

  Map<String, dynamic> toJSON() {
    return _$ParticipantToJson(this);
  }

  Participant copyWith({
    String id,
    int participantID,
    Discussion discussion,
    Viewer viewer,
    List<Post> posts,
    bool isAnonymous,
    bool isBanned,
    String gradientColor,
    bool hasJoined,
    UserProfile userProfile,
    Participant inviter,
    String anonDisplayName,
    DateTime mutedUntil,
  }) {
    return Participant(
      id: id ?? this.id,
      participantID: participantID ?? this.participantID,
      discussion: discussion ?? this.discussion,
      viewer: viewer ?? this.viewer,
      posts: posts ?? this.posts,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isBanned: isBanned ?? this.isBanned,
      gradientColor: gradientColor ?? this.gradientColor,
      hasJoined: hasJoined ?? this.hasJoined,
      userProfile: userProfile ?? this.userProfile,
      inviter: inviter ?? this.inviter,
      anonDisplayName: anonDisplayName ?? this.anonDisplayName,
      mutedUntil: mutedUntil ?? this.mutedUntil,
    );
  }

  bool get isMuted => mutedUntil != null && mutedUntil.isAfter(DateTime.now());
}
