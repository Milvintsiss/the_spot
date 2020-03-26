import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:the_spot/services/library/gallery_item.dart';

class Gallery extends StatefulWidget {
  Gallery(this.imagesAddress, {Key key, this.height = 200}) : super(key: key);

  final double height;

  final List<String> imagesAddress;

  @override
  _GalleryState createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  List<GalleryItem> galleryItems = List();

  List<GalleryItemThumbnail> galleryItemsThumbnail = List();

  @override
  void initState() {
    super.initState();

    widget.imagesAddress.forEach((element) {
      galleryItems.add(GalleryItem(
        id: widget.imagesAddress.indexOf(element).toString(),
        resource: element,
      ));
    });

    galleryItems.forEach((element) {
      galleryItemsThumbnail.add(GalleryItemThumbnail(
        galleryItem: element,
        onTap: () => open(context, galleryItems.indexOf(element)),
      ));
    });
  }
  @override
  void didUpdateWidget(Gallery oldWidget) {
    super.didUpdateWidget(oldWidget);

    galleryItems.clear();
    galleryItemsThumbnail.clear();

    setState(() {
      widget.imagesAddress.forEach((element) {
        galleryItems.add(GalleryItem(
          id: widget.imagesAddress.indexOf(element).toString(),
          resource: element,
        ));
      });

      galleryItems.forEach((element) {
        galleryItemsThumbnail.add(GalleryItemThumbnail(
          galleryItem: element,
          onTap: () => open(context, galleryItems.indexOf(element)),
        ));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: widget.height,
        child: ListView.builder(
          itemCount: galleryItemsThumbnail.length,
          itemBuilder: (BuildContext context, int Itemindex) {
            return galleryItemsThumbnail[Itemindex];
          },
          scrollDirection: Axis.horizontal,
        ));
  }

  void open(BuildContext context, final int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryPhotoViewWrapper(
          galleryItems: galleryItems,
          backgroundDecoration: const BoxDecoration(
            color: Colors.black,
          ),
          initialIndex: index,
          scrollDirection: Axis.horizontal,
        ),
      ),
    );
  }
}

class GalleryPhotoViewWrapper extends StatefulWidget {
  GalleryPhotoViewWrapper({
    this.loadingBuilder,
    this.backgroundDecoration,
    this.minScale,
    this.maxScale,
    this.initialIndex,
    @required this.galleryItems,
    this.scrollDirection = Axis.horizontal,
  }) : pageController = PageController(initialPage: initialIndex);

  final LoadingBuilder loadingBuilder;
  final Decoration backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final int initialIndex;
  final PageController pageController;
  final List<GalleryItem> galleryItems;
  final Axis scrollDirection;

  @override
  State<StatefulWidget> createState() {
    return _GalleryPhotoViewWrapperState();
  }
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  int currentIndex;

  @override
  void initState() {
    currentIndex = widget.initialIndex;
    super.initState();
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: widget.backgroundDecoration,
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: <Widget>[
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: _buildItem,
              itemCount: widget.galleryItems.length,
              loadingBuilder: widget.loadingBuilder,
              backgroundDecoration: widget.backgroundDecoration,
              pageController: widget.pageController,
              onPageChanged: onPageChanged,
              scrollDirection: widget.scrollDirection,
            ),
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Image ${currentIndex + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17.0,
                  decoration: null,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final GalleryItem item = widget.galleryItems[index];
    return item.isSvg
        ? PhotoViewGalleryPageOptions.customChild(
            child: Container(
              width: 300,
              height: 300,
              child: SvgPicture.asset(
                item.resource,
                height: 200.0,
              ),
            ),
            childSize: const Size(300, 300),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * (0.5 + index / 10),
            maxScale: PhotoViewComputedScale.covered * 1.1,
            heroAttributes: PhotoViewHeroAttributes(tag: item.id),
          )
        : PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(item.resource),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * (0.5 + index / 10),
            maxScale: PhotoViewComputedScale.covered * 1.1,
            heroAttributes: PhotoViewHeroAttributes(tag: item.id),
          );
  }
}
