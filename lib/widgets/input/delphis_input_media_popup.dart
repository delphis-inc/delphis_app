import 'dart:async';
import 'dart:io';

import 'package:delphis_app/bloc/discussion/discussion_bloc.dart';
import 'package:delphis_app/data/repository/discussion.dart';
import 'package:delphis_app/data/repository/media.dart';
import 'package:delphis_app/data/repository/participant.dart';
import 'package:delphis_app/design/sizes.dart';
import 'package:delphis_app/widgets/input/media_input_snippet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import 'delphis_input.dart';

class DelphisInputMediaPopupWidget extends StatefulWidget {
  final Discussion discussion;
  final Participant participant;
  final ScrollController parentScrollController;
  final TextEditingController textController;
  final FocusNode inputFocusNode;
  final Function(String, File, MediaContentType) onSubmit;
  final Function(File, MediaContentType) onMediaTap;
  final VoidCallback onParticipantMentionPressed;
  final VoidCallback onDiscussionMentionPressed;
  final VoidCallback onModeratorButtonPressed;

  const DelphisInputMediaPopupWidget(
      {Key key,
      @required this.discussion,
      @required this.participant,
      @required this.parentScrollController,
      @required this.textController,
      @required this.inputFocusNode,
      @required this.onSubmit,
      @required this.onParticipantMentionPressed,
      @required this.onDiscussionMentionPressed,
      @required this.onMediaTap,
      @required this.onModeratorButtonPressed})
      : super(key: key);

  @override
  _DelphisInputMediaPopupWidgetState createState() =>
      _DelphisInputMediaPopupWidgetState();
}

class _DelphisInputMediaPopupWidgetState
    extends State<DelphisInputMediaPopupWidget>
    with SingleTickerProviderStateMixin {
  final ImagePicker imagePicker = ImagePicker();
  File mediaFile;
  MediaContentType mediaType;

  @override
  Widget build(BuildContext context) {
    var bar = Container();
    if (mediaFile != null && mediaType != null) {
      bar = Container(
        padding: EdgeInsets.only(
            top: SpacingValues.medium,
            left: SpacingValues.small,
            right: SpacingValues.small),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MediaInputSnippetWidget(
                  mediaFile: mediaFile,
                  mediaType: mediaType,
                  onCancelTap: (file, type) {
                    setState(() {
                      this.mediaFile = null;
                      this.mediaType = null;
                    });
                  },
                  onTap: this.widget.onMediaTap)
            ]),
      );
    }

    var render = AnimatedSize(
        vsync: this,
        duration: Duration(milliseconds: 200),
        reverseDuration: Duration(milliseconds: 50),
        curve: Curves.decelerate,
        child: Column(
          children: [
            bar,
            DelphisInput(
              discussion: widget.discussion,
              participant: widget.participant,
              parentScrollController: widget.parentScrollController,
              inputFocusNode: this.widget.inputFocusNode,
              textController: this.widget.textController,
              onParticipantMentionPressed:
                  this.widget.onParticipantMentionPressed,
              onDiscussionMentionPressed:
                  this.widget.onDiscussionMentionPressed,
              onGalleryPressed: () {
                BlocProvider.of<DiscussionBloc>(context).add(
                    DiscussionImagePickEvent(
                        discussionID: this.widget.discussion.id,
                        isPicking: true,
                        nonce: DateTime.now()));
                SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                  this.selectGalleryMedia();
                });
              },
              onImageCameraPressed: () {
                BlocProvider.of<DiscussionBloc>(context).add(
                    DiscussionImagePickEvent(
                        discussionID: this.widget.discussion.id,
                        isPicking: true,
                        nonce: DateTime.now()));
                SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                  this.selectCameraImage();
                });
              },
              onVideoCameraPressed: this.selectCameraVideo,
              onModeratorButtonPressed: this.widget.onModeratorButtonPressed,
              mediaFile: this.mediaFile,
              onSubmit: (text) {
                this.widget.onSubmit(text, this.mediaFile, this.mediaType);

                // Maybe we can interact with DiscussionBloc to catch errors and not discard the image
                setState(() {
                  this.mediaFile = null;
                  this.mediaType = null;
                });
              },
            )
          ],
        ));
    return Platform.isAndroid
        ? FutureBuilder(
            future: retrieveLostData(),
            builder: (context, snapshot) => render,
          )
        : render;
  }

  void selectGalleryMedia() async {
    File mediaFile = await FilePicker.getFile(type: FileType.image);
    if (mediaFile != null) {
      String mimeStr = lookupMimeType(mediaFile.path);
      var fileType = mimeStr.split('/')[0].toLowerCase() == "image"
          ? MediaContentType.IMAGE
          : MediaContentType.VIDEO;
      setState(() {
        this.mediaFile = mediaFile;
        this.mediaType = fileType;
      });
    }
    FocusScope.of(context).unfocus();
    Timer(const Duration(milliseconds: 1), () {
      FocusScope.of(context).requestFocus(this.widget.inputFocusNode);
    });
  }

  void selectCameraImage() async {
    final pickedFile = await imagePicker.getImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        this.mediaFile = File(pickedFile.path);
        this.mediaType = MediaContentType.IMAGE;
      });
    }
    FocusScope.of(context).unfocus();
    Timer(const Duration(milliseconds: 1), () {
      FocusScope.of(context).requestFocus(this.widget.inputFocusNode);
    });
  }

  void selectCameraVideo() async {
    final pickedFile = await imagePicker.getVideo(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        this.mediaFile = File(pickedFile.path);
        this.mediaType = MediaContentType.VIDEO;
      });
    }
  }

  Future<void> retrieveLostData() async {
    final LostData response = await imagePicker.getLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      var mediaType = MediaContentType.IMAGE;
      if (response.type == RetrieveType.video) {
        mediaType = MediaContentType.VIDEO;
      }
      setState(() {
        this.mediaFile = File(response.file.path);
        this.mediaType = mediaType;
      });
    } else {
      //response.exception.code;
      // Maybe catch errors ?
    }
  }
}
