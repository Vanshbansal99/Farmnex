import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../products/product_search_delegate.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cart/cart_provider.dart';
import '../auth/auth_provider.dart';
import '../admin/product_admin_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset('assets/videos/tractor-video.mp4');
    
    _controller.addListener(() {
      if (_controller.value.isInitialized && !stateIsSet) {
        setState(() {});
        stateIsSet = true;
      }
    });

    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      _controller.play();
    } catch (e) {
      debugPrint('Video error: $e');
    }
  }

  bool stateIsSet = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/catalogue'),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.manage_search_rounded),
        label: Text('Select From Catalogue', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Container(
              child: Column(
                children: [
                  _buildCategories(),
                  _buildFeaturedProducts(ref),
                  _buildTrendingSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    // Dynamic height: 70% of screen on mobile, 600px on large screens to avoid overflow
    final heroHeight = isLargeScreen ? 650.0 : screenHeight * 0.7;

    return SliverAppBar(
      floating: false,
      pinned: false,
      expandedHeight: heroHeight,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroSection(),
      ),
      title: Text(
        'FARMNEX',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: AppColors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            final products = ref.read(adminProductProvider);
            showSearch(
              context: context,
              delegate: ProductSearchDelegate(products),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => context.push('/cart'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.person_outline),
          onSelected: (value) {
            final auth = ref.read(authProvider.notifier);
            final user = ref.read(authProvider).user;
            
            switch (value) {
              case 'login':
                context.push('/login');
                break;
              case 'signup':
                context.push('/signup');
                break;
              case 'profile':
                context.push('/profile');
                break;
              case 'admin':
                context.push('/admin');
                break;
              case 'logout':
                auth.logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
                break;
            }
          },
          itemBuilder: (context) {
            final isLoggedIn = ref.read(authProvider).token != null;
            final isAdmin = ref.read(authProvider).user?['role'] == 'admin';
            
            if (!isLoggedIn) {
              return [
                const PopupMenuItem(value: 'login', child: Text('Login')),
                const PopupMenuItem(value: 'signup', child: Text('Sign Up')),
              ];
            }
            
            return [
              const PopupMenuItem(value: 'profile', child: Text('My Profile')),
              if (isAdmin)
                const PopupMenuItem(value: 'admin', child: Text('Admin Portal')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ];
          },
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final heroHeight = isLargeScreen ? 650.0 : screenHeight * 0.7;

    return ClipRect(
      child: SizedBox(
        height: heroHeight,
        width: double.infinity,
        child: Stack(
          children: [
            // Background Video or Fallback Image
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _controller.value.isInitialized
                  ? SizedBox.expand(
                      key: const ValueKey('video'),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    )
                  : SizedBox.expand(
                      key: const ValueKey('image'),
                      child: Image.network(
                        'https://images.pexels.com/photos/2933243/pexels-photo-2933243.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),

            // Content
            Positioned.fill(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: isLargeScreen ? 80 : 60),
                      // Premium Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentYellow,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentYellow.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Text(
                          'PREMIUM QUALITY',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Main Title with shadow for readability
                      Text(
                        'Precision Engineering\nfor the Modern Farm',
                        style: GoogleFonts.outfit(
                          fontSize: MediaQuery.of(context).size.width > 900 ? 64 : 42,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          height: 1.1,
                          shadows: [
                            Shadow(
                              blurRadius: 20,
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Discover the most durable and high-precision spare parts\nfor your tractors and agricultural machinery.',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          color: AppColors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Actions
                      Wrap(
                        spacing: 20,
                        runSpacing: 16,
                        children: [
                          ElevatedButton(
                            onPressed: () => context.push('/catalogue'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentYellow,
                              foregroundColor: AppColors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                              elevation: 10,
                              shadowColor: AppColors.accentYellow.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'EXPLORE CATALOGUE',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.white,
                              side: const BorderSide(color: AppColors.white, width: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'WATCH DEMO',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                    ],
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

  Widget _buildCategories() {
    final categories = [
      {'name': 'Engine', 'icon': Icons.settings},
      {'name': 'Hydraulic', 'icon': Icons.water_drop},
      {'name': 'Transmission', 'icon': Icons.alt_route},
      {'name': 'Electrical', 'icon': Icons.flash_on},
      {'name': 'Tyres & Wheels', 'icon': Icons.adjust},
      {'name': 'Body & Chassis', 'icon': Icons.agriculture},
      {'name': 'Maintenance', 'icon': Icons.build},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Categories',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => context.push('/category/${categories[index]['name']}'),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          categories[index]['icon'] as IconData,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        categories[index]['name'] as String,
                        style: GoogleFonts.outfit(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedProducts(WidgetRef ref) {
    final allProducts = ref.watch(adminProductProvider);
    
    // Phase 1 Logic: Show exactly 4 parts from key categories
    final List<AdminProduct> phase1Products = [];
    
    // 1. One from Tyre category
    final tyre = allProducts.firstWhere(
      (p) => p.category.toLowerCase().contains('tyre'),
      orElse: () => allProducts.isNotEmpty ? allProducts.first : AdminProduct(id: '0', name: 'Premium Tyre', category: 'Tyres', price: 12000, stock: 10, description: ''),
    );
    phase1Products.add(tyre);

    // 2. One from Maintenance
    final maintenance = allProducts.firstWhere(
      (p) => p.category.toLowerCase().contains('maintenance') && !phase1Products.contains(p),
      orElse: () => allProducts.length > 1 ? allProducts[1] : AdminProduct(id: '1', name: 'Service Kit', category: 'Maintenance', price: 4500, stock: 15, description: ''),
    );
    phase1Products.add(maintenance);

    // 3. One from Published Catalogue (looking for 'Part #' or specific keyword)
    final cataloguePart = allProducts.firstWhere(
      (p) => p.description.toLowerCase().contains('part #') && !phase1Products.contains(p),
      orElse: () => allProducts.length > 2 ? allProducts[2] : AdminProduct(id: '2', name: 'Catalogue Part', category: 'Engine', price: 8500, stock: 5, description: ''),
    );
    phase1Products.add(cataloguePart);

    // 4. One high-impact Engine/Hydraulic part
    final enginePart = allProducts.firstWhere(
      (p) => p.category.toLowerCase().contains('engine') && !phase1Products.contains(p),
      orElse: () => allProducts.length > 3 ? allProducts[3] : AdminProduct(id: '3', name: 'Precision Engine Part', category: 'Engine', price: 25000, stock: 8, description: ''),
    );
    phase1Products.add(enginePart);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Products',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'See All',
                    style: GoogleFonts.outfit(color: AppColors.darkGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : MediaQuery.of(context).size.width > 800 ? 3 : 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: phase1Products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(phase1Products[index], ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(AdminProduct product, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: product.image.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image_outlined, color: AppColors.metallicGray, size: 40),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image, color: AppColors.metallicGray, size: 40),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.metallicGray),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final user = ref.read(authProvider).user;
                          if (user == null) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Login Required'),
                                content: const Text('Please login or create an account to start adding items to your cart.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Later'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.push('/login');
                                    },
                                    child: const Text('Login Now'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                          
                          ref.read(cartProvider.notifier).addItem(
                                CartItem(
                                  id: product.id,
                                  name: product.name,
                                  price: product.price,
                                  image: product.image,
                                ),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item added to cart'),
                              duration: Duration(seconds: 1),
                              backgroundColor: AppColors.darkGreen,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.darkGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: AppColors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Heavy Duty Sale!',
                  style: GoogleFonts.outfit(
                    color: AppColors.accentYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get up to 40% off on all hydraulic parts.',
                  style: GoogleFonts.outfit(color: AppColors.white),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.darkGreen,
                    minimumSize: const Size(120, 35),
                  ),
                  child: const Text('Explore'),
                ),
              ],
            ),
          ),
          const Icon(Icons.agriculture, color: AppColors.white, size: 80),
        ],
      ),
    );
  }
}
