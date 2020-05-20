
import 'package:flutter/material.dart';

import '../../theme.dart';

class SearchBar extends StatefulWidget{
  final double sizeFactor;
  final double textSize;
  final void Function(String) onSearch;

  const SearchBar(this.onSearch,{Key key, this.sizeFactor, this.textSize, }) : super(key: key);
  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar>{

  final searchBarController =
  TextEditingController.fromValue(TextEditingValue.empty);
  bool userIsSearching = false;
  bool userIsTyping = false;
  String query;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: widget.sizeFactor,
        decoration: BoxDecoration(
            color: PrimaryColor,
            borderRadius: BorderRadius.all(Radius.circular(100))),
        child: Padding(
          padding: EdgeInsets.fromLTRB(widget.sizeFactor / 2, 0, widget.sizeFactor / 4, 0),
          child: Center(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: TextField(
                    controller: searchBarController,
                    onChanged: (String value) {
                      query = value.trim();
                      setState(() {
                        userIsTyping = true;
                      });
                    },
                    style: TextStyle(color: Colors.white, fontSize: widget.textSize),
                    textInputAction: TextInputAction.search,
                    onEditingComplete: () => widget.onSearch.call(query),
                    decoration: InputDecoration(
                      hintText: "Search...",
                      hintStyle:
                      TextStyle(color: Colors.white70, fontSize: widget.textSize),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    userIsTyping && query.length > 0
                        ? SizedBox(
                      height: widget.sizeFactor * 2/3,
                      width: widget.sizeFactor * 2/3,
                      child: IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: PrimaryColorDark,
                            size: widget.sizeFactor / 2,
                          ),
                          onPressed: () {
                            query = "";
                            searchBarController.clear();
                            userIsSearching = false;
                            userIsTyping = false;
                            widget.onSearch.call(query);
                          }),
                    )
                        : Container(),
                    Padding(
                      padding: EdgeInsets.only(right: widget.sizeFactor / 3),
                      child: SizedBox(
                        height: widget.sizeFactor * 2/3,
                        width: widget.sizeFactor * 2/3,
                        child: IconButton(
                          icon: Icon(
                            Icons.search,
                            color: PrimaryColorDark,
                            size: widget.sizeFactor * 2/3,
                          ),
                          onPressed: () => widget.onSearch.call(query),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ));
  }
}