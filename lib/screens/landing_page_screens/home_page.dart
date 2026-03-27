import 'package:flutter/material.dart';
import 'package:major_project_website/screens/landing_page_screens/subscription_info_page.dart';
import 'about.dart';
import 'call_to_action_section.dart';
import 'e_album_section.dart';
import 'faq_section.dart';
import 'features_section.dart';
import 'footer_section.dart';
import 'hero_section.dart';

import 'key_benefits_page.dart';
import 'testmonial_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final scrollController = ScrollController();

  final heroKey = GlobalKey();
  final featuresKey = GlobalKey();
  final ctaKey = GlobalKey();
  final testimonialKey = GlobalKey();
  final footerKey = GlobalKey();
  final galleryKey = GlobalKey();
  final ealbumKey = GlobalKey();
  final pricingKey = GlobalKey();
  final aboutKey = GlobalKey();
  final faqKey = GlobalKey();
  final benefitsKey = GlobalKey();
  final subKey = GlobalKey();


  bool isScrolled = false;
  bool showHelp = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      final scrolled = scrollController.offset > 50;
      if (isScrolled != scrolled) {
        setState(() {
          isScrolled = scrolled;
        });
      }
    });
  }

  void scrollToSection(GlobalKey key, bool isMobile) {
    final context = key.currentContext;
    if (context != null) {
      if (isMobile) {
        Navigator.of(context).pop(); // Closes drawer on mobile
      }
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      drawer: isMobile
          ? Drawer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.lightBlueAccent, Colors.pinkAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: Colors.teal.shade700.withOpacity(0.6),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/lock.gif',
                            width: 40,
                            height: 40,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Instant Photos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...getNavButtons(true),
                  ],
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                HeroSection(key: heroKey),
                FeaturesSection(key: featuresKey),
                KeyBenefitsSection(key: benefitsKey),
                EmpoweringPhotographersSection(key: aboutKey),
                EAlbumSection(key: ealbumKey),
                CallToActionSection(key: ctaKey),
                TestimonialSection(key: testimonialKey),
                Divider(),
                SubscriptionInfoPage(key: subKey,),
                FooterSection(key: footerKey),



              ],
            ),
          ),

          // Top Navbar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 70,
            decoration: BoxDecoration(
              color: isScrolled ? Colors.white : Colors.transparent,
              boxShadow: isScrolled
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: isScrolled ? Colors.black : Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                child: const Text('Instant Photos'),
              ),
              iconTheme: IconThemeData(
                color: isScrolled ? Colors.black : Colors.white,
              ),
              leading: isMobile
                  ? Builder(
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: GestureDetector(
                            onTap: () => Scaffold.of(context).openDrawer(),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Colors.teal, Colors.tealAccent],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.menu,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : null,
              actions: isMobile ? null : getNavButtons(false),
            ),
          ),

          // Help Button at Bottom Left
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSlide(
                  duration: const Duration(milliseconds: 400),
                  offset: showHelp ? Offset.zero : const Offset(-1.2, 0),
                  curve: Curves.easeInOut,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Need help navigating the site?\nClick a section above or reach out through Contact.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'help_btn',
                  backgroundColor: Colors.teal,
                  onPressed: () {
                    setState(() {
                      showHelp = !showHelp;
                    });
                  },
                  child: const Icon(Icons.help_outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> getNavButtons(bool isMobile) {
    return [
      _navButton('Home', () => scrollToSection(heroKey, isMobile), isMobile),
      _navButton(
          'Services', () => scrollToSection(featuresKey, isMobile), isMobile),
      _navButton(
          'Benefits', () => scrollToSection(benefitsKey, isMobile), isMobile),
      _navButton('About', () => scrollToSection(aboutKey, isMobile), isMobile),
      _navButton(
          'E-Album', () => scrollToSection(ealbumKey, isMobile), isMobile),

      _navButton('Contact', () => scrollToSection(ctaKey, isMobile), isMobile),
      const SizedBox(width: 20),
    ];
  }

  Widget _navButton(String text, VoidCallback onPressed, bool isMobile) {
    return isMobile
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              hoverColor: Colors.white24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: onPressed,
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(
                  Colors.blue.withOpacity(0.1),
                ),
                foregroundColor: MaterialStateProperty.all(
                  isScrolled ? Colors.black : Colors.white,
                ),
              ),
              child: Text(text),
            ),
          );
  }
}
