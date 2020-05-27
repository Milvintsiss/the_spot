import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:the_spot/app_localizations.dart';

class Gallery extends StatefulWidget {
  Gallery(this.imagesAddress, {Key key, this.height = 200, this.animate = true}) : super(key: key);

  final double height;

  final bool animate;

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
    initGallery();
  }

  @override
  void didUpdateWidget(Gallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    initGallery();
  }

  void initGallery() {
    galleryItems.clear();
    galleryItemsThumbnail.clear();

    if (widget.imagesAddress.length > 0) {
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
  }

  @override
  Widget build(BuildContext context) {
    if(galleryItemsThumbnail.length > 0) {
      return CarouselSlider.builder(
          itemCount: galleryItemsThumbnail.length,
          itemBuilder: (BuildContext context, int itemIndex) {
            return galleryItemsThumbnail[itemIndex];
          },
          options: CarouselOptions(
              autoPlay: widget.animate,
              autoPlayInterval: Duration(seconds: 2),
              enlargeCenterPage: true,
              viewportFraction: 0.4,
              aspectRatio: 1,
              height: widget.height
          ));
    }else{
      return Text(
        AppLocalizations.of(context).translate("You haven't added any pictures yet!")
      );
    }
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
                AppLocalizations.of(context).translate("Picture %DYNAMIC", dynamic: (currentIndex + 1).toString()),
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


class GalleryItem {
  GalleryItem({this.id, this.resource, this.isSvg = false});

  final String id;
  final String resource;
  final bool isSvg;
}

class GalleryItemThumbnail extends StatelessWidget {
  const GalleryItemThumbnail(
      {Key key, this.galleryItem, this.onTap})
      : super(key: key);

  final GalleryItem galleryItem;

  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: GestureDetector(
        onTap: onTap,
        child: ClipOval(
            child: Image.network(galleryItem.resource, fit: BoxFit.fitHeight)),
      ),
    );
  }
}
