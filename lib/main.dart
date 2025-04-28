import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cat Datting',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const CatHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CatHomePage extends StatefulWidget {
  const CatHomePage({super.key});

  @override
  State<CatHomePage> createState() => _CatHomePageState();
}

class _CatHomePageState extends State<CatHomePage>
    with SingleTickerProviderStateMixin {
  late String _catImageUrl;
  bool _loading = true;
  bool _error = false;
  final Random _random = Random();

  // Animation variables
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double _dragDx = 0.0;
  bool _isDragging = false;
  String? _swipeDirection; // 'right' or 'left'
  bool _showIcon = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fetchCat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fetchCat() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final int cacheBuster = _random.nextInt(1000000);
    final String url =
        'https://cataas.com/cat?width=600&height=400&_=$cacheBuster';
    final Image image = Image.network(url);
    final ImageStream stream = image.image.resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (ImageInfo info, bool syncCall) {
        setState(() {
          _catImageUrl = url;
          _loading = false;
        });
      },
      onError: (dynamic _, __) {
        setState(() {
          _error = true;
          _loading = false;
        });
      },
    );
    stream.addListener(listener);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDx += details.delta.dx;
      _isDragging = true;
      if (_dragDx > 0) {
        _swipeDirection = 'right';
      } else if (_dragDx < 0) {
        _swipeDirection = 'left';
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final double threshold = 120;
    if (_dragDx.abs() > threshold) {
      // Animate card off screen
      final bool isRight = _dragDx > 0;
      _slideAnimation = Tween<Offset>(
        begin: Offset(_dragDx / 400, 0),
        end: Offset(isRight ? 2.0 : -2.0, 0),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      setState(() {
        _showIcon = true;
      });
      _controller.forward().then((_) {
        setState(() {
          _dragDx = 0.0;
          _isDragging = false;
          _showIcon = false;
        });
        _controller.reset();
        _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
            .animate(_controller);
        _fetchCat();
      });
    } else {
      // Animate card back to center
      _slideAnimation = Tween<Offset>(
        begin: Offset(_dragDx / 400, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
      _controller.forward().then((_) {
        setState(() {
          _dragDx = 0.0;
          _isDragging = false;
          _showIcon = false;
        });
        _controller.reset();
        _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
            .animate(_controller);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Random Cat Viewer',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return GestureDetector(
                onHorizontalDragUpdate: _loading ? null : _onDragUpdate,
                onHorizontalDragEnd: _loading ? null : _onDragEnd,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SlideTransition(
                      position: _isDragging
                          ? AlwaysStoppedAnimation(Offset(_dragDx / 400, 0))
                          : _slideAnimation,
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple.shade100,
                                Colors.white
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: SizedBox(
                            width: 400,
                            child: _loading
                                ? SizedBox(
                                    height: 300,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  )
                                : _error
                                    ? SizedBox(
                                        height: 300,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.error_outline,
                                                  color: Colors.red, size: 48),
                                              const SizedBox(height: 12),
                                              const Text(
                                                  'Failed to load cat image.',
                                                  style:
                                                      TextStyle(fontSize: 18)),
                                              const SizedBox(height: 8),
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.refresh),
                                                label: const Text('Try Again'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.deepPurple,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16)),
                                                ),
                                                onPressed: _fetchCat,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image.network(
                                          _catImageUrl,
                                          key: ValueKey(_catImageUrl),
                                          fit: BoxFit.cover,
                                          height: 300,
                                          width: 400,
                                          loadingBuilder:
                                              (context, child, progress) {
                                            if (progress == null) return child;
                                            return SizedBox(
                                              height: 300,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: progress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? progress
                                                              .cumulativeBytesLoaded /
                                                          (progress
                                                                  .expectedTotalBytes ??
                                                              1)
                                                      : null,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.broken_image,
                                                      size: 80,
                                                      color: Colors.grey),
                                        ),
                                      ),
                          ),
                        ),
                      ),
                    ),
                    if (_showIcon && _swipeDirection != null)
                      Positioned(
                        left: _swipeDirection == 'left' ? 36 : null,
                        right: _swipeDirection == 'right' ? 36 : null,
                        child: AnimatedOpacity(
                          opacity: _showIcon ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _swipeDirection == 'right'
                                  ? Colors.green.withOpacity(0.8)
                                  : Colors.red.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Icon(
                              _swipeDirection == 'right'
                                  ? Icons.check
                                  : Icons.close,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
