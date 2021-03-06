import 'package:delphis_app/data/repository/discussion.dart';
import 'package:delphis_app/data/repository/participant.dart';
import 'package:delphis_app/data/repository/user.dart';
import 'package:delphis_app/design/colors.dart';
import 'package:delphis_app/widgets/anon_profile_image/anon_profile_image.dart';
import 'package:delphis_app/widgets/pressable/pressable.dart';
import 'package:delphis_app/widgets/profile_image/moderator_profile_image.dart';
import 'package:delphis_app/widgets/profile_image/profile_image.dart';
import 'package:delphis_app/widgets/profile_image/profile_image_and_inviter.dart';
import 'package:flutter/material.dart';

class ProfileImageWithGradient extends StatelessWidget {
  final User me;
  final Participant participant;
  final Discussion discussion;
  final bool isModerator;
  final bool anonymousOverride;
  final double width;
  final double height;
  final bool isPressable;
  final VoidCallback onPressed;
  final GradientName gradientNameOverride;

  const ProfileImageWithGradient({
    @required this.participant,
    @required this.discussion,
    @required this.width,
    @required this.height,
    this.anonymousOverride,
    this.me,
    this.isPressable = false,
    this.onPressed,
    this.isModerator = false,
    this.gradientNameOverride,
  })  : assert(
            !isModerator || me != null, 'A moderator must pass a `me` object'),
        assert(!isPressable || onPressed != null,
            'If pressable, must pass onPressed'),
        super();

  bool get showAnonymous => anonymousOverride != null
      ? anonymousOverride
      : this.participant.isAnonymous;

  @override
  Widget build(BuildContext context) {
    final participantID =
        this.participant == null ? 0 : this.participant.participantID;
    var gradient = ChathamColors.gradients[
        anonymousGradients[participantID % anonymousGradients.length]];
    if (this.gradientNameOverride != null) {
      gradient = ChathamColors.gradients[this.gradientNameOverride];
    } else if (this.participant.gradientColor != null) {
      gradient = ChathamColors
          .gradients[gradientNameFromString(this.participant.gradientColor)];
    }

    if(!this.showAnonymous) {
      gradient = ChathamColors.whiteGradient;
    }
    final borderRadius = this.width / 3.0;
    final profileImage = this._getProfileImage(borderRadius);
    final moderatorMargin = 3.0;
    // This stinks but currently argument explosion doesn't exist.
    var toRender;
    if (this.isPressable) {
      toRender =  Pressable(
        onPressed: this.onPressed,
        width: isModerator ? this.width + moderatorMargin : this.width,
        height: isModerator ? this.height + moderatorMargin : this.height,
        decoration: BoxDecoration(
          gradient: isModerator ? null : gradient,
          shape: BoxShape.circle,
          border: this.isModerator
              ? null
              : Border.all(
                  color: Colors.transparent,
                  width: 1.5,
                ),
        ),
        child: profileImage,
      );
    }
    else {
      toRender =  Container(
        width: isModerator ? this.width + moderatorMargin : this.width,
        height: isModerator ? this.height + moderatorMargin : this.height,
        decoration: BoxDecoration(
          gradient: isModerator ? null : gradient,
          shape: this.isModerator ? BoxShape.circle : BoxShape.rectangle,
          border: this.isModerator
              ? null
              : Border.all(
                  color: Colors.transparent,
                  width: 1.5,
                ),
          borderRadius: this.isModerator
              ? null
              : BorderRadius.all(Radius.circular(borderRadius)),
        ),
        child: profileImage,
      );
    }

    var inviterParticipant = this.discussion.participants.firstWhere((p) => p.id == this.participant?.inviter?.id, orElse: () => null);
    if(!this.isModerator && this.showAnonymous && inviterParticipant != null) {
      var imageUrl = inviterParticipant?.userProfile?.profileImageURL;

      if(inviterParticipant?.id == this.participant?.id || imageUrl == null) {
        imageUrl = this.discussion?.moderator?.userProfile?.profileImageURL;
      }

      return ProfileImageAndInviter(
        size: 24,
        child: toRender,
        inviterImageURL: imageUrl,
        gradient: inviterParticipant.isAnonymous ? ChathamColors.gradients[inviterParticipant.gradientColor] : ChathamColors.whiteGradient
      );
    }

    return toRender;
  }

  Widget _getProfileImage(double borderRadius) {
    if (this.isModerator) {
      // Me is the moderator
      return ModeratorProfileImage(
        starTopLeftMargin: this.width * 0.67,
        starSize: this.width * 0.35,
        diameter: this.width,
        profileImageURL: this.me.profile.profileImageURL,
        showAnonymous: this.showAnonymous,
      );
    }
    // Is anonymous
    if (this.showAnonymous) {
      return AnonProfileImage(
        width: this.width,
        height: this.height,
        borderShape: BoxShape.circle,
        borderRadius: borderRadius,
      );
    } else {
      // Is not anonymous
      return ProfileImage(
        width: this.width,
        height: this.height,
        profileImageURL: this.me.profile.profileImageURL,
      );
    }
  }
}
