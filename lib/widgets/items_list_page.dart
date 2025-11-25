import 'package:flutter/material.dart';
import '../models/place_data.dart';

class ItemsListPage extends StatelessWidget {
  final List<PlaceData> items;

  const ItemsListPage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Places List')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final place = items[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                place.image,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            title: Text(place.name),
            subtitle: Text(
              place.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text('${place.rating}★'),
            onTap: () {
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}
