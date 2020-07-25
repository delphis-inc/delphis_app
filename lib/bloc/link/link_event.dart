part of 'link_bloc.dart';

abstract class LinkEvent extends Equatable {
  const LinkEvent();
}

class LinkChangeEvent extends LinkEvent {
  final String newLink;
  final DateTime nonce;

  LinkChangeEvent({
    @required this.newLink,
  })  : nonce = DateTime.now(),
        super();

  @override
  List<Object> get props => [newLink, nonce];
}
