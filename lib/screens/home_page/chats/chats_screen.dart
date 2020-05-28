import 'package:delphis_app/bloc/discussion_list/discussion_list_bloc.dart';
import 'package:delphis_app/data/repository/discussion.dart';
import 'package:delphis_app/screens/home_page/chats/chat_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatsScreen extends StatefulWidget {
  final DiscussionRepository discussionRepository;

  const ChatsScreen({@required this.discussionRepository}) : super();

  @override
  State<StatefulWidget> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DiscussionListBloc>(
      lazy: true,
      create: (context) =>
          DiscussionListBloc(repository: this.widget.discussionRepository),
      child: ChatList(),
    );
  }
}
