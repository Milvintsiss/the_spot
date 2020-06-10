import 'package:flutter/material.dart';
import 'package:the_spot/services/library/blurhash_encoding.dart';

import '../../theme.dart';

class ProfilePicture extends StatefulWidget {
  final String downloadUrl;
  final String hash;
  final bool isAnUser;
  final double size;
  final Color borderColor;
  final double borderSize;
  final Color background;

  const ProfilePicture(
      {Key key,
      @required this.downloadUrl,
      this.hash,
      this.isAnUser = true,
      this.size = 50,
      this.borderColor = PrimaryColorDark,
      this.borderSize = 2,
      this.background = PrimaryColor})
      : super(key: key);

  @override
  _ProfilePictureState createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  @override
  Widget build(BuildContext context) {
    if (widget.downloadUrl != null && widget.downloadUrl != "")
      return SizedBox(
        height: widget.size,
        width: widget.size,
        child: Container(
          padding: EdgeInsets.all(widget.borderSize),
          decoration: BoxDecoration(
            color: widget.borderColor,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
              child: widget.hash != null
                  ? SizedBlurHash(
                      pictureDownloadUrl: widget.downloadUrl,
                      hashWithSize: widget.hash,
                    )
                  : Image.network(
                      widget.downloadUrl,
                      fit: BoxFit.fill,
                    )),
        ),
      );
    else
      return Container(
        height: widget.size,
        width: widget.size,
        decoration: BoxDecoration(color: widget.background, shape: BoxShape.circle),
        child: Icon(
          widget.isAnUser ? Icons.person : Icons.people,
          size: widget.size / 2,
        ),
      );
  }
}
