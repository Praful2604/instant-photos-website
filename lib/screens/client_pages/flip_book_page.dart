import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FlipBookPage extends StatefulWidget {
  final String qrCode;
  const FlipBookPage({super.key, required this.qrCode});

  @override
  State<FlipBookPage> createState() => _FlipBookPageState();
}

class _FlipBookPageState extends State<FlipBookPage> with TickerProviderStateMixin {
  List<String> _imageUrls = [];
  List<Map<String, String>> _pagePairs = [];
  bool _loading = true;
  bool _isFlipping = false;
  bool _isNextPage = true;
  int _currentPage = 0;

  late AnimationController _pageController;
  late Animation<double> _pageRotation;

  Map<String, String>? _flippingFrontPage;
  Map<String, String>? _flippingBackPage;

  final String proxyBaseUrl =
      'https://us-central1-instant-photos-9a258.cloudfunctions.net/proxyImage';

  String proxyImageUrl(String path) => '$proxyBaseUrl?path=$path';

  @override
  void initState() {
    super.initState();
    _loadFavoriteImages();
  }

  Future<void> _loadFavoriteImages() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(widget.qrCode)
          .collection('imgs')
          .get();

      final urls = snapshot.docs
          .map((doc) => doc.data()['path'] as String? ?? '')
          .where((path) => path.isNotEmpty)
          .map(proxyImageUrl)
          .toList()
        ..sort();

      // Pair images as left + right pages
      _pagePairs = [];
      for (int i = 0; i < urls.length; i += 2) {
        final left = urls[i];
        final right = (i + 1 < urls.length) ? urls[i + 1] : urls[i];
        _pagePairs.add({'left': left, 'right': right});
      }

      _pageController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );

      _pageRotation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _pageController, curve: Curves.easeInOut),
      );

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _turnPage(int direction) async {
    if (_isFlipping || _pagePairs.isEmpty) return;
    final newPage = _currentPage + direction;
    if (newPage < 0 || newPage >= _pagePairs.length) return;

    setState(() {
      _isFlipping = true;
      _isNextPage = direction > 0;
      _flippingFrontPage = _pagePairs[_currentPage];
      _flippingBackPage = _pagePairs[newPage];
    });

    await _pageController.forward();

    if (mounted) {
      setState(() {
        _currentPage = newPage;
        _isFlipping = false;
        _pageController.reset();
        _flippingFrontPage = null;
        _flippingBackPage = null;
      });
    }
  }

  Widget _buildPage(String imageUrl,
      {required double width, required double height, required bool isLeftPage}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: isLeftPage ? const Radius.circular(10) : Radius.zero,
          bottomLeft: isLeftPage ? const Radius.circular(10) : Radius.zero,
          topRight: !isLeftPage ? const Radius.circular(10) : Radius.zero,
          bottomRight: !isLeftPage ? const Radius.circular(10) : Radius.zero,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(2, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: isLeftPage ? const Radius.circular(10) : Radius.zero,
          bottomLeft: isLeftPage ? const Radius.circular(10) : Radius.zero,
          topRight: !isLeftPage ? const Radius.circular(10) : Radius.zero,
          bottomRight: !isLeftPage ? const Radius.circular(10) : Radius.zero,
        ),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildPageFlip({
    required double width,
    required double height,
    required String frontImage,
    required String backImage,
    required double rotation,
    required bool isLeftPageFlip,
  }) {
    return Stack(
      children: [
        Transform(
          alignment: isLeftPageFlip ? Alignment.centerRight : Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(isLeftPageFlip ? pi : -pi),
          child: _buildPage(backImage,
              width: width, height: height, isLeftPage: isLeftPageFlip),
        ),
        Transform(
          alignment: isLeftPageFlip ? Alignment.centerRight : Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(rotation * (isLeftPageFlip ? -pi : pi)),
          child: _buildPage(frontImage,
              width: width, height: height, isLeftPage: isLeftPageFlip),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pagePairs.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No favorite photos found for this QR code.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bookWidth = (screenWidth * 0.9).clamp(300.0, 1200.0);
    final pageHeight = (screenHeight * 0.6).clamp(200.0, 800.0);
    final pageWidth = bookWidth / 2;

    final leftPage = _pagePairs[_currentPage]['left']!;
    final rightPage = _pagePairs[_currentPage]['right']!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(' Flipbook', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007bff), Color(0xFF0db3be)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Book background
              Container(
                width: bookWidth,
                height: pageHeight,
                decoration: BoxDecoration(
                  color: Colors.brown[600],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 4,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
              ),
              // Left and right pages
              Positioned(
                left: 0,
                child: _buildPage(leftPage,
                    width: pageWidth, height: pageHeight, isLeftPage: true),
              ),
              Positioned(
                left: pageWidth,
                child: _buildPage(rightPage,
                    width: pageWidth, height: pageHeight, isLeftPage: false),
              ),
              // Animated flipping
              if (_isFlipping && _flippingFrontPage != null && _flippingBackPage != null)
                AnimatedBuilder(
                  animation: _pageRotation,
                  builder: (context, child) {
                    return Positioned(
                      left: _isNextPage ? pageWidth : 0,
                      child: _buildPageFlip(
                        width: pageWidth,
                        height: pageHeight,
                        frontImage: _isNextPage
                            ? _flippingFrontPage!['right']!
                            : _flippingFrontPage!['left']!,
                        backImage: _isNextPage
                            ? _flippingBackPage!['left']!
                            : _flippingBackPage!['right']!,
                        rotation: _pageRotation.value,
                        isLeftPageFlip: !_isNextPage,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.blueGrey[50],
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _currentPage > 0 && !_isFlipping
                  ? () => _turnPage(-1)
                  : null,
            ),
            Text(
              'Page ${_currentPage + 1} / ${_pagePairs.length}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _currentPage < _pagePairs.length - 1 && !_isFlipping
                  ? () => _turnPage(1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
