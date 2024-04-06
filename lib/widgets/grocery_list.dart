import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'flutter-prep-769ed-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list.json');

    Response? result;
    result = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    ); // headers其實可省略

    if (result.statusCode >= 400) {
      throw Exception('Failed to fetch grocery items. Please try again later.');
    }

    if (result.body == 'null') {
      return [];
    }

    final Map<String, dynamic> listData = json.decode(result.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }

    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) return;

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    if (index < 0) return;

    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
        'flutter-prep-769ed-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list/${item.id}.json');

    final result = await http.delete(url);
    if (result.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: FutureBuilder(
        future: _loadedItems,
        builder: (ctx, snapshot) => snapshot.connectionState ==
                ConnectionState.waiting
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : snapshot.hasError
                ? Center(
                    child: Text(snapshot.error.toString()),
                  )
                : !snapshot.hasData
                    ? const Center(
                        child: Text('No items added yet.'),
                      )
                    : ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (ctx, index) => Dismissible(
                          key: ValueKey(snapshot.data![index].id),
                          onDismissed: (direction) {
                            _removeItem(snapshot.data![index]);
                          },
                          child: ListTile(
                            title: Text(snapshot.data![index].name),
                            leading: Container(
                                width: 24,
                                height: 24,
                                color: snapshot.data![index].category.color),
                            trailing:
                                Text(snapshot.data![index].quantity.toString()),
                          ),
                        ),
                      ),
      ),
    );
  }
}
