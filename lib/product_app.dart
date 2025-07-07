import 'package:flutter/material.dart';
import 'login_page.dart';
import 'cart_page.dart';
import 'favorites_page.dart';
import 'shared_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final String thumbnail;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.thumbnail,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      thumbnail: json['thumbnail'],
    );
  }
}

class ProductApp extends StatefulWidget {
  @override
  State<ProductApp> createState() => _ProductAppState();
}

class _ProductAppState extends State<ProductApp> {
  List<Product> _products = [];
  List<Product> _cartItems = [];
  List<Product> _favoriteItems = [];

  List<String> _apiCategories = ['All'];
  String _selectedApiCategory = 'All';

  final Map<String, List<String>> customFilters = {
    'All': [],
    'Food & Groceries': ['groceries'],
    'Cosmetics & Skincare': ['skincare', 'fragrances'],
    'Electronics': ['smartphones', 'laptops'],
    'Fashion (Men)': ['mens-shirts', 'mens-shoes', 'mens-watches'],
    'Fashion (Women)': ['womens-dresses', 'womens-shoes', 'womens-watches'],
    'Home & Lifestyle': ['home-decoration', 'furniture', 'lighting'],
    'Accessories': ['sunglasses', 'womens-bags', 'womens-jewellery'],
    'Automotive': ['automotive'],
    'Toys & Hobbies': ['tops'],
  };

  String _selectedCustomFilter = 'All';

  bool _isLoading = false;
  bool _hasMore = true;
  int _skip = 0;
  int _limit = 20;
  bool _isGridView = false;
  String _searchQuery = "";

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchApiCategories().then((_) => _fetchProducts());
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading &&
          _hasMore) {
        _fetchProducts();
      }
    });
  }

  Future<void> _fetchApiCategories() async {
    final res = await http.get(
      Uri.parse('https://dummyjson.com/products/categories'),
    );
    if (res.statusCode == 200) {
      List<dynamic> list = jsonDecode(res.body);
      setState(() {
        _apiCategories = ['All'];
        _apiCategories.addAll(list.map((e) => e.toString()).toList());
      });
    }
  }

  Future<void> _fetchProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _skip = 0;
        _products.clear();
        _hasMore = true;
      });
    }

    setState(() => _isLoading = true);

    List<String> categoriesToFetch;

    if (_selectedCustomFilter == 'All') {
      if (_selectedApiCategory == 'All') {
        categoriesToFetch = [];
      } else {
        categoriesToFetch = [_selectedApiCategory];
      }
    } else {
      categoriesToFetch = customFilters[_selectedCustomFilter] ?? [];
    }

    List<Product> newProducts = [];

    if (categoriesToFetch.isEmpty) {
      String url = 'https://dummyjson.com/products?limit=$_limit&skip=$_skip';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final List items = jsonDecode(res.body)['products'];
        newProducts = items.map((e) => Product.fromJson(e)).toList();
      }
    } else {
      for (String cat in categoriesToFetch) {
        String url =
            'https://dummyjson.com/products/category/${Uri.encodeComponent(cat)}?limit=$_limit&skip=$_skip';
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          final List items = jsonDecode(res.body)['products'];
          newProducts.addAll(items.map((e) => Product.fromJson(e)).toList());
        }
      }
    }

    setState(() {
      _products.addAll(newProducts);
      _skip += _limit;
      _hasMore = newProducts.isNotEmpty;
      _isLoading = false;
    });
  }

  void _toggleFavorite(Product p) {
    setState(() {
      _favoriteItems.contains(p)
          ? _favoriteItems.remove(p)
          : _favoriteItems.add(p);
    });
  }

  void _addToCart(Product p) {
    if (!_cartItems.contains(p)) {
      setState(() => _cartItems.add(p));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${p.title} added to cart")));
    }
  }

  List<Product> get _filtered => _searchQuery.isEmpty
      ? _products
      : _products
            .where(
              (p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

  void _logout() async {
    await SharedService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  void _openMenu(String value) {
    if (value == 'cart') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CartPage(cartItems: _cartItems)),
      );
    } else if (value == 'favorites') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FavoritesPage(favoriteItems: _favoriteItems),
        ),
      );
    } else if (value == 'logout') {
      _logout();
    }
  }

  void _showProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(product.thumbnail, height: 150),
            SizedBox(height: 10),
            Text(
              "₹${product.price}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(product.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addToCart(product);
              Navigator.pop(context);
            },
            child: Text("Add to Cart"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(Product product) {
    return Card(
      child: ListTile(
        onTap: () => _showProductDialog(product),
        leading: Image.network(
          product.thumbnail,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
        title: Text(product.title),
        subtitle: Text("₹${product.price}"),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: Icon(
                _favoriteItems.contains(product)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: Colors.pink,
              ),
              onPressed: () => _toggleFavorite(product),
            ),
            IconButton(
              icon: Icon(Icons.add_shopping_cart, color: Colors.green),
              onPressed: () => _addToCart(product),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(Product product) {
    return GestureDetector(
      onTap: () => _showProductDialog(product),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(product.thumbnail, fit: BoxFit.cover),
            ),
            Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(
                    _favoriteItems.contains(product)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.pink,
                  ),
                  onPressed: () => _toggleFavorite(product),
                ),
                IconButton(
                  icon: Icon(Icons.add_shopping_cart, color: Colors.green),
                  onPressed: () => _addToCart(product),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: Text("Products"),
        backgroundColor: Colors.deepPurple.shade100,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.share('Check out this amazing product app!');
            },
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          PopupMenuButton<String>(
            onSelected: _openMenu,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'cart', child: Text('Cart')),
              PopupMenuItem(value: 'favorites', child: Text('Favorites')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "Search...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                DropdownButton<String>(
                  value: _selectedCustomFilter,
                  isExpanded: true,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCustomFilter = val;
                        _products.clear();
                        _skip = 0;
                        _hasMore = true;
                      });
                      _fetchProducts(reset: true);
                    }
                  },
                  items: customFilters.keys.map((key) {
                    return DropdownMenuItem(value: key, child: Text(key));
                  }).toList(),
                ),
                SizedBox(height: 10),
                DropdownButton<String>(
                  value: _selectedApiCategory,
                  isExpanded: true,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedApiCategory = val;
                        _products.clear();
                        _skip = 0;
                        _hasMore = true;
                      });
                      _fetchProducts(reset: true);
                    }
                  },
                  items: _apiCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(
                        cat == 'All'
                            ? 'All Categories'
                            : cat.replaceAll('-', ' ').toUpperCase(),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isGridView
                ? GridView.builder(
                    padding: EdgeInsets.all(12),
                    controller: _scrollController,
                    itemCount: display.length + (_hasMore ? 1 : 0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (_, i) {
                      if (i < display.length) return _buildGrid(display[i]);
                      return Center(child: CircularProgressIndicator());
                    },
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: display.length + (_hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i < display.length) return _buildTile(display[i]);
                      return Center(child: CircularProgressIndicator());
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
