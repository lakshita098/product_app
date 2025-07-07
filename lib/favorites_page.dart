import 'package:flutter/material.dart';
import 'product_app.dart';

class FavoritesPage extends StatelessWidget {
  final List<Product> favoriteItems;

  const FavoritesPage({super.key, required this.favoriteItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Favorites")),
      body: favoriteItems.isEmpty
          ? Center(child: Text("No favorites added"))
          : ListView.builder(
              itemCount: favoriteItems.length,
              itemBuilder: (context, index) {
                final product = favoriteItems[index];
                return ListTile(
                  leading: Image.network(
                    product.thumbnail,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(product.title),
                  subtitle: Text("\$${product.price}"),
                );
              },
            ),
    );
  }
}
