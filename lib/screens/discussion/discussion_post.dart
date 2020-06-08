import 'package:delphis_app/data/repository/moderator.dart';
import 'package:delphis_app/data/repository/participant.dart';
import 'package:delphis_app/data/repository/post.dart';
import 'package:delphis_app/design/colors.dart';
import 'package:delphis_app/design/sizes.dart';
import 'package:delphis_app/widgets/anon_profile_image/anon_profile_image.dart';
import 'package:delphis_app/widgets/emoji_text/emoji_text.dart';
import 'package:delphis_app/widgets/profile_image/moderator_profile_image.dart';
import 'package:flutter/material.dart';

import 'post_title.dart';

class DiscussionPost extends StatelessWidget {
  final Post post;
  final Participant participant;
  final Moderator moderator;

  const DiscussionPost({
    Key key,
    @required this.participant,
    @required this.post,
    @required this.moderator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isModeratorAuthor = this.participant.participantID == 0;
    return Opacity(
      opacity: (this.post.isLocalPost ?? false) ? 0.4 : 1.0,
      child: Container(
        padding: EdgeInsets.only(
            left: SpacingValues.medium,
            top: SpacingValues.medium,
            bottom: SpacingValues.medium),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          // TODO: We need to hook this up to use the correct image for non-anonymous participants.
          children: <Widget>[
            Container(
              key: this.key == null
                  ? null
                  : Key(
                      '${this.key.toString()}-profile-image-padding-container'),
              padding: EdgeInsets.only(right: SpacingValues.medium),
              child: Container(
                key: this.key == null
                    ? null
                    : Key('${this.key.toString()}-profile-image-container'),
                width: 36.0,
                height: 36.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isModeratorAuthor
                      ? ChathamColors.gradients[moderatorGradientName]
                      : ChathamColors.gradients[gradientNameFromString(
                          this.participant.gradientColor)],
                  border: Border.all(color: Colors.transparent, width: 1.0),
                ),
                child: isModeratorAuthor
                    ? ModeratorProfileImage(
                        diameter: 36.0,
                        outerBorderWidth: 0.0,
                        profileImageURL:
                            this.moderator.userProfile.profileImageURL)
                    : AnonProfileImage(),
              ),
            ),
            Expanded(
                child: Container(
              child: Column(
                key: this.key == null
                    ? null
                    : Key('${this.key.toString()}-content-column'),
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  PostTitle(
                    moderator: this.moderator,
                    participant: this.participant,
                    height: 20.0,
                  ),
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(top: SpacingValues.xxSmall),
                          child: EmojiText(
                            text: '${this.post.content}',
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
