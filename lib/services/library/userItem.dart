import 'package:flutter/material.dart';

import '../../theme.dart';
import 'library.dart';
import 'userProfile.dart';

class UserItem extends StatefulWidget {
  final UserProfile user;
  final double sizeReference;
  final double textSizeReference;
  final bool isDeletable;
  final bool isClickable;
  final void Function(UserProfile) deleteCallback;
  final void Function(UserProfile) clickCallback;
  final Color background;
  final Color pseudoColor;
  final FontWeight pseudoFontWeight;
  final double borderSize;
  final Color borderColor;

  const UserItem({
    Key key,
    @required this.user,
    @required this.sizeReference,
    @required this.textSizeReference,
    this.isDeletable = false,
    this.isClickable = false,
    this.deleteCallback,
    this.clickCallback,
    this.background = SecondaryColorDark,
    this.pseudoColor = Colors.white70,
    this.pseudoFontWeight = FontWeight.bold,
    this.borderSize,
    this.borderColor = SecondaryColorLight,
  }) : super(key: key);

  @override
  _UserItemState createState() => _UserItemState();
}

class _UserItemState extends State<UserItem> {

  double borderSize;
  @override
  Widget build(BuildContext context) {
    borderSize = widget.borderSize ?? widget.sizeReference / 300;
    return GestureDetector(
      onTap: () => Feedback.wrapForTap(() => widget.clickCallback(widget.user), context).call(),
      child: SizedBox(
        height: widget.sizeReference / 13,
        child: Container(
          padding: EdgeInsets.all(widget.sizeReference / 120),
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(widget.sizeReference / 20),
            border: Border.all(width: borderSize, color: widget.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfilePicture(widget.user.profilePictureDownloadPath,
                  size: widget.sizeReference / 20, borderSize: 0.5),
              Divider(
                indent: widget.sizeReference / 120,
              ),
              Text(
                widget.user.pseudo,
                style: TextStyle(
                    color: widget.pseudoColor,
                    fontWeight: widget.pseudoFontWeight,
                    fontSize: 14 * widget.textSizeReference),
              ),
              widget.isDeletable
                  ? SizedBox(
                height: widget.sizeReference / 25,
                width: widget.sizeReference / 25,
                child: IconButton(
                  icon: Icon(
                    Icons.cancel,
                    color: widget.borderColor,
                  ),
                  padding: EdgeInsets.zero,
                  iconSize: widget.sizeReference / 25,
                  onPressed: () => widget.deleteCallback(widget.user),
                ),
              )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
