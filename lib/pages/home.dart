import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:simple_gallery/constants/strings.dart';
import 'package:simple_gallery/pages/settings.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:video_player/video_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // controllers
  TransformationController controllerT = TransformationController();
  TapDownDetails? _doubleTapDetails;
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;

  List<Album>? _albums;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loading = true;
    initAsync();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _animation = Matrix4Tween(begin: controllerT.value, end: Matrix4.identity())
        .animate(_animationController);
    _animationController.addListener(() {
      controllerT.value = _animation.value;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> initAsync() async {
    if (await _promptPermissionSetting()) {
      List<Album> albums =
          await PhotoGallery.listAlbums(mediumType: MediumType.image);
      setState(() {
        _albums = albums;
        _loading = false;
      });
    }
    setState(() {
      _loading = false;
    });
  }

  Future<bool> _promptPermissionSetting() async {
    if (Platform.isIOS &&
            await Permission.storage.request().isGranted &&
            await Permission.photos.request().isGranted ||
        Platform.isAndroid && await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }

  void _handleDoubleTap() {
    if (controllerT.value != Matrix4.identity()) {
      _animation =
          Matrix4Tween(begin: controllerT.value, end: Matrix4.identity())
              .animate(_animationController);
      _animationController.forward(from: 0.0);
    } else {
      final position = _doubleTapDetails!.localPosition;
      // For a 3x zoom
      _animation = Matrix4Tween(
              begin: controllerT.value,
              end: Matrix4.identity()
                // ..translate(-position.dx * 2, -position.dy * 2)
                // ..scale(3.0);
                // Fox a 2x zoom
                ..translate(-position.dx, -position.dy)
                ..scale(2.0))
          .animate(_animationController);
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Colors.transparent,
        toolbarHeight: 100,
        // elevation: 0,
        title: const Text(
          Strings.homePageTitle,
          style: TextStyle(fontSize: 27),
        ),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const Settings()));
              },
              icon: const Icon(Icons.settings))
        ],
      ),
      // drawer: Drawer(
      //   child: ListView(
      //     // Important: Remove any padding from the ListView.
      //     padding: EdgeInsets.zero,
      //     children: [
      //       const DrawerHeader(
      //         decoration: BoxDecoration(
      //           color: Colors.blue,
      //         ),
      //         child: Text('Drawer Header'),
      //       ),
      //       ListTile(
      //         title: const Text('Item 1'),
      //         onTap: () {
      //           // Update the state of the app.
      //           // ...
      //         },
      //       ),
      //       ListTile(
      //         title: const Text('Item 2'),
      //         onTap: () {
      //           // Update the state of the app.
      //           // ...
      //         },
      //       ),
      //     ],
      //   ),
      // ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                double gridWidth = (constraints.maxWidth - 20) / 3;
                double gridHeight = gridWidth + 33;
                double ratio = gridWidth / gridHeight;
                return Container(
                  padding: const EdgeInsets.all(5),
                  child: GridView.count(
                    childAspectRatio: ratio,
                    crossAxisCount: 3,
                    mainAxisSpacing: 5.0,
                    crossAxisSpacing: 5.0,
                    children: <Widget>[
                      ...?_albums?.map(
                        (album) => GestureDetector(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => AlbumPage(album))),
                          child: Column(
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  // borderRadius:
                                  // BorderRadius.circular(15.0)
                                ),
                                height: gridWidth,
                                width: gridWidth,
                                child: ClipRRect(
                                  // borderRadius: BorderRadius.circular(15.0),
                                  child: FadeInImage(
                                    fit: BoxFit.cover,
                                    placeholder: MemoryImage(kTransparentImage),
                                    image: AlbumThumbnailProvider(
                                      albumId: album.id,
                                      mediumType: album.mediumType,
                                      highQuality: true,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                alignment: Alignment.topLeft,
                                padding: const EdgeInsets.only(left: 2.0),
                                child: Text(
                                  album.name ?? "Unnamed Album",
                                  maxLines: 1,
                                  textAlign: TextAlign.start,
                                  style: const TextStyle(
                                    height: 1.2,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                alignment: Alignment.topLeft,
                                padding: const EdgeInsets.only(left: 2.0),
                                child: Text(
                                  album.count.toString(),
                                  textAlign: TextAlign.start,
                                  style: const TextStyle(
                                    height: 1.2,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class AlbumPage extends StatefulWidget {
  final Album album;

  const AlbumPage(this.album, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AlbumPageState();
}

class AlbumPageState extends State<AlbumPage> {
  List<Medium>? _media;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  void initAsync() async {
    MediaPage mediaPage = await widget.album.listMedia();
    setState(() {
      _media = mediaPage.items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 100,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.album.name ?? "Unnamed Album",
            style: const TextStyle(color: Colors.black, fontSize: 27),
          ),
        ),
        body: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 5.0,
          crossAxisSpacing: 5.0,
          padding: const EdgeInsets.all(5),
          children: <Widget>[
            ...?_media?.map(
              (medium) => GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ViewerPage(medium))),
                child: Container(
                  // ignore: prefer_const_literals_to_create_immutables
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    // ignore: prefer_const_literals_to_create_immutables
                    // boxShadow: [
                    //   BoxShadow(
                    //     offset: Offset(2, 2),
                    //     blurRadius: 5,
                    //     color: Color.fromRGBO(0, 0, 0, 0.2),
                    //   ),
                    // ],
                    border: Border.all(color: Colors.grey),
                    // borderRadius: BorderRadius.circular(15.0),
                  ),

                  child: ClipRRect(
                    // borderRadius: BorderRadius.circular(15.0),
                    child: FadeInImage(
                      fit: BoxFit.fitWidth,
                      fadeInDuration: const Duration(milliseconds: 375),
                      placeholder: MemoryImage(kTransparentImage),
                      image: ThumbnailProvider(
                        mediumId: medium.id,
                        mediumType: medium.mediumType,
                        highQuality: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewerPage extends StatefulWidget {
  final Medium medium;

  const ViewerPage(this.medium, {Key? key}) : super(key: key);

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> with TickerProviderStateMixin {
  // controllers
  TransformationController controllerT = TransformationController();

  TapDownDetails? _doubleTapDetails;

  late AnimationController _animationController;

  late Animation<Matrix4> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _animation = Matrix4Tween(begin: controllerT.value, end: Matrix4.identity())
        .animate(_animationController);
    _animationController.addListener(() {
      controllerT.value = _animation.value;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (controllerT.value != Matrix4.identity()) {
      _animation =
          Matrix4Tween(begin: controllerT.value, end: Matrix4.identity())
              .animate(_animationController);
      _animationController.forward(from: 0.0);
    } else {
      final position = _doubleTapDetails!.localPosition;
      // For a 3x zoom
      _animation = Matrix4Tween(
              begin: controllerT.value,
              end: Matrix4.identity()
                // ..translate(-position.dx * 2, -position.dy * 2)
                // ..scale(3.0);
                // Fox a 2x zoom
                ..translate(-position.dx, -position.dy)
                ..scale(2.0))
          .animate(_animationController);
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? date = widget.medium.creationDate ?? widget.medium.modifiedDate;
    PhotoProvider imgprovider = PhotoProvider(mediumId: widget.medium.id);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
        title: date != null
            ? Text(
                date.toLocal().toString(),
                style: const TextStyle(color: Colors.black),
              )
            : null,
      ),
      // body: Container(
      //   alignment: Alignment.center,
      //   child: medium.mediumType == MediumType.image
      //       ? FadeInImage(
      //           fit: BoxFit.cover,
      //           placeholder: MemoryImage(kTransparentImage),
      //           image: PhotoProvider(mediumId: medium.id),
      //         )
      //       : VideoProvider(
      //           mediumId: medium.id,
      //         ),
      // ),
      body: GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          // boundaryMargin: const EdgeInsets.all(80),
          panEnabled: true,
          scaleEnabled: true,
          minScale: 1.0,
          maxScale: 2.2,
          transformationController: controllerT,
          child: Expanded(
            child: Container(
              alignment: Alignment.center,
              child: widget.medium.mediumType == MediumType.image
                  ?
                  // FadeInImage(
                  //     fit: BoxFit.cover,
                  //     // placeholder: MemoryImage(kTransparentImage),
                  //     placeholder: imgprovider,
                  //     image: PhotoProvider(mediumId: widget.medium.id),
                  //   )

                  Image(
                      image: PhotoProvider(mediumId: widget.medium.id),
                    )
                  : VideoProvider(
                      mediumId: widget.medium.id,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class VideoProvider extends StatefulWidget {
  final String mediumId;

  const VideoProvider({
    Key? key,
    required this.mediumId,
  }) : super(key: key);

  @override
  _VideoProviderState createState() => _VideoProviderState();
}

class _VideoProviderState extends State<VideoProvider> {
  VideoPlayerController? _controller;
  File? _file;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initAsync();
    });
    super.initState();
  }

  Future<void> initAsync() async {
    try {
      _file = await PhotoGallery.getFile(mediumId: widget.mediumId);
      _controller = VideoPlayerController.file(_file!);
      _controller?.initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
    } catch (e) {
      debugPrint("Failed : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return _controller == null || !_controller!.value.isInitialized
        ? Container()
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _controller!.value.isPlaying
                        ? _controller!.pause()
                        : _controller!.play();
                  });
                },
                child: Icon(
                  _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
            ],
          );
  }
}
