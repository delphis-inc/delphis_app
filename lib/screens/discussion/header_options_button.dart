import 'package:delphis_app/widgets/pressable/pressable.dart';
import 'package:flutter/material.dart';

enum HeaderOption { logout }

typedef HeaderOptionsCallback(HeaderOption option);

class HeaderOptionsButton extends StatelessWidget {
  final double diameter;
  final HeaderOptionsCallback onPressed;

  const HeaderOptionsButton({
    @required this.diameter,
    @required this.onPressed,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<HeaderOption>(
      child: Container(
        width: this.diameter,
        height: this.diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2.0,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.more_horiz,
          size: this.diameter * 0.8,
          color: Color.fromRGBO(200, 200, 207, 1.0),
          semanticLabel: "More...",
        ),
      ),
      onSelected: this.onPressed,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<HeaderOption>>[
        const PopupMenuItem<HeaderOption>(
          value: HeaderOption.logout,
          child: Text('Logout'),
        ),
      ],
    );
  }
}