import 'package:delphis_app/data/repository/participant.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import 'discussion.dart';

@JsonSerializable()
class Entity extends Equatable {

  final String id;

  const Entity({
    @required this.id
  });

  @override
  List<Object> get props => [this.id];

  factory Entity.fromJson(Map<String, dynamic> json) {
    /* Is it a discussion ? */
    try {
      var res = Discussion.fromJson(json);
      if(res.title.length > 0)
        return res;
    } catch (e) { }

    /* It must be a participant */
    return Participant.fromJson(json);
  }
}