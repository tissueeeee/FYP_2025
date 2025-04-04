import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:fyp_project/models/favorites.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class BrowsePage extends StatefulWidget {
  final latlng.LatLng? userLocation;

  const BrowsePage({Key? key, this.userLocation}) : super(key: key);

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSort = 'Relevance';
  final List<String> _sortOptions = [
    'Relevance',
    'Price',
    'Distance',
    'Rating'
  ];
  bool _isListView = true;
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _sortedItems = [];
  List<Map<String, dynamic>> _filteredItems = [];

  latlng.LatLng _currentLocation = latlng.LatLng(3.0798, 101.7331);

  @override
  void initState() {
    super.initState();
    if (widget.userLocation != null) {
      _currentLocation = widget.userLocation!;
    }
    _fetchNearbyItems();
    _searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNearbyItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String overpassQuery = '''
      [out:json];
      (
        node["shop"="bakery"](around:5000,${_currentLocation.latitude},${_currentLocation.longitude});
        node["shop"="supermarket"](around:5000,${_currentLocation.latitude},${_currentLocation.longitude});
        node["amenity"="restaurant"](around:5000,${_currentLocation.latitude},${_currentLocation.longitude});
      );
      out body;
      ''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: overpassQuery,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List<dynamic>;

        _items = elements.map((element) {
          final name = element['tags']['name'] ?? 'Unknown Store';
          final category =
              element['tags']['shop'] ?? element['tags']['amenity'] ?? 'Other';
          final lat = element['lat'] as double;
          final lon = element['lon'] as double;
          final location = latlng.LatLng(lat, lon);

          final distanceInMeters = Geolocator.distanceBetween(
            _currentLocation.latitude,
            _currentLocation.longitude,
            lat,
            lon,
          );

          final random = Random();
          final price = (random.nextDouble() * 10 + 2).toDouble();
          final discountRate = 50 + random.nextInt(31);
          final originalPrice = (price / (1 - discountRate / 100)).toDouble();
          final stock = random.nextInt(10) + 1;

          String storeImage;
          if (name.toLowerCase().contains('tf value-mart')) {
            storeImage = 'assets/images/browsestore1.png';
          } else if (name.toLowerCase().contains('aeon big')) {
            storeImage = 'assets/images/browsestore2.png';
          } else if (name.toLowerCase().contains('99 speedmart')) {
            storeImage = 'assets/images/browsestore3.png';
          } else if (name.toLowerCase().contains('ibrahim maju')) {
            storeImage = 'assets/images/browsestore4.png';
          } else if (name.toLowerCase().contains('kayu nasi kandar')) {
            storeImage = 'assets/images/browsestore5.png';
          } else if (name.toLowerCase().contains('hanizah nasi kandar')) {
            storeImage = 'assets/images/browsestore6.png';
          } else if (name.toLowerCase().contains('azzahra')) {
            storeImage = 'assets/images/browsestore7.png';
          } else if (name.toLowerCase().contains('the baker\'s place')) {
            storeImage = 'assets/images/browsestore8.png';
          } else if (name.toLowerCase().contains('deli2go')) {
            storeImage = 'assets/images/browsestore9.png';
          } else if (name
              .toLowerCase()
              .contains('putu piring bandar tun razak')) {
            storeImage = 'assets/images/browsestore10.png';
          } else if (name.toLowerCase().contains('baker\'s cottage')) {
            storeImage = 'assets/images/browsestore11.png';
          } else if (name.toLowerCase().contains('mon cherry')) {
            storeImage = 'assets/images/browsestore12.png';
          } else if (name.toLowerCase().contains('eco-bakery')) {
            storeImage = 'assets/images/browsestore13.png';
          } else if (name.toLowerCase().contains('happy bakery shop')) {
            storeImage = 'assets/images/browsestore14.png';
          } else if (name.toLowerCase().contains('star grocer')) {
            storeImage = 'assets/images/browsestore15.png';
          } else if (name
              .toLowerCase()
              .contains('morning market sri petaling')) {
            storeImage = 'assets/images/browsestore16.png';
          } else if (name.toLowerCase().contains('clan dimsum restaurant')) {
            storeImage = 'assets/images/browsestore17.png';
          } else if (name.toLowerCase().contains('kuali bonda')) {
            storeImage = 'assets/images/browsestore18.png';
          } else if (name.toLowerCase().contains('kyochon')) {
            storeImage = 'assets/images/browsestore19.png';
          } else if (name.toLowerCase().contains('hotel lsn')) {
            storeImage = 'assets/images/browsestore20.png';
          } else {
            storeImage = 'assets/images/bread.png';
          }

          return {
            'stock': stock,
            'storeName': name,
            'itemName': 'Surprise Bag',
            'pickupTime': _generateRandomPickupTime(),
            'rating': (random.nextDouble() * 2 + 3).toDouble(),
            'distance': (distanceInMeters).toInt(),
            'price': double.parse(price.toStringAsFixed(2)),
            'originalPrice': double.parse(originalPrice.toStringAsFixed(2)),
            'discountRate': discountRate,
            'image': storeImage,
            'isFavorite': false,
            'description': 'Surprise bag from $name',
            'category': category == 'bakery'
                ? 'Bakery'
                : category == 'supermarket'
                    ? 'Groceries'
                    : 'Meals',
            'isNew': random.nextBool(),
            'location': location,
          };
        }).toList();

        setState(() {
          _sortedItems = List.from(_items);
          _filteredItems = List.from(_sortedItems);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch nearby items: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching nearby items: $e';
        _isLoading = false;
      });
    }
  }

  String _generateRandomPickupTime() {
    final random = Random();
    final startHour = random.nextInt(20) + 1;
    final endHour = startHour + 1;
    return '${startHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00';
  }

  void _handleSearch() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterItems();
    });
  }

  void _filterItems() {
    if (_searchQuery.isEmpty) {
      _filteredItems = List.from(_sortedItems);
    } else {
      _filteredItems = _sortedItems.where((item) {
        bool matchesStore =
            item['storeName'].toLowerCase().contains(_searchQuery);
        bool matchesItem =
            item['itemName'].toLowerCase().contains(_searchQuery);
        bool matchesCategory =
            item['category'].toLowerCase().contains(_searchQuery);
        bool matchesDescription =
            item['description'].toLowerCase().contains(_searchQuery);
        return matchesStore ||
            matchesItem ||
            matchesCategory ||
            matchesDescription;
      }).toList();
    }
  }

  bool _showSoldOut = false;
  bool _pickUpToday = true;
  bool _pickUpTomorrow = false;
  RangeValues _pickupWindowRange = const RangeValues(0, 24);
  Map<String, bool> _bagTypes = {
    'Meals': false,
    'Bread & pastries': false,
    'Groceries': false,
    'Other': false,
    'Halal': false,
    'Non-Halal': false,
  };
  Map<String, bool> _dietPrefs = {
    'Vegetarian': false,
    'Vegan': false,
    'Gluten-Free': false,
    'Dairy-Free': false,
  };

  void _sortItems() {
    setState(() {
      switch (_selectedSort) {
        case 'Price':
          _sortedItems.sort((a, b) => a['price'].compareTo(b['price']));
          break;
        case 'Distance':
          _sortedItems.sort((a, b) => a['distance'].compareTo(b['distance']));
          break;
        case 'Rating':
          _sortedItems.sort((a, b) => b['rating'].compareTo(a['rating']));
          break;
        case 'Relevance':
        default:
          _sortedItems = List.from(_items);
          break;
      }
      _filterItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _buildTopBar(),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Container(
        color: const Color.fromARGB(255, 246, 246, 246),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.green))
            : Column(
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  _buildListMapToggle(),
                  _buildSortDropdown(),
                  _buildCategoryFilter(),
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? _buildNoResultsFound()
                        : _isListView
                            ? _buildListView()
                            : _buildMapView(),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/delivery');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/favorite');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Discover"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Browse"),
          BottomNavigationBarItem(
              icon: Icon(Icons.delivery_dining), label: "Delivery"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Favorite"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        selectedItemColor: const Color.fromARGB(255, 56, 142, 60),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No results found for "$_searchQuery"',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try different keywords or check your filters',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Clear Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Meals', 'Bakery', 'Groceries'];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(categories[index]),
              selectedColor: Colors.green[100],
              backgroundColor: Colors.grey[200],
              checkmarkColor: Colors.green,
              selected: false,
              onSelected: (selected) {
                setState(() {
                  if (categories[index] == 'All') {
                    _filteredItems = List.from(_sortedItems);
                  } else {
                    _filteredItems = _sortedItems
                        .where((item) => item['category'] == categories[index])
                        .toList();
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search for stores or items...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              fillColor: Colors.grey[200],
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.green),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _showFilterModal,
          icon: const Icon(Icons.filter_list, color: Colors.green),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            setState(() {
              _isListView = false;
            });
          },
          icon: const Icon(Icons.map, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildListMapToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _isListView = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isListView ? Colors.green : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    "List",
                    style: TextStyle(
                      color: _isListView ? Colors.white : Colors.grey,
                      fontWeight:
                          _isListView ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _isListView = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isListView ? Colors.green : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    "Map",
                    style: TextStyle(
                      color: !_isListView ? Colors.white : Colors.grey,
                      fontWeight:
                          !_isListView ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Text(
            "Sort by:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedSort,
            items: _sortOptions
                .map((sort) => DropdownMenuItem(
                      value: sort,
                      child: Text(sort),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedSort = value!;
                _sortItems();
              });
            },
            underline: Container(
              height: 2,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: _currentLocation,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.fyp_project',
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 80.0,
              height: 80.0,
              point: _currentLocation,
              child: const Icon(
                Icons.person_pin_circle,
                color: Colors.blue,
                size: 40.0,
              ),
            ),
            ..._filteredItems.map((item) {
              return Marker(
                width: 80.0,
                height: 80.0,
                point: item['location'],
                child: Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40.0,
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with stock badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        item['image'],
                        width: MediaQuery.of(context).size.width *
                            0.25, // Responsive width
                        height: MediaQuery.of(context).size.width * 0.25,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/bread.png',
                            width: MediaQuery.of(context).size.width * 0.25,
                            height: MediaQuery.of(context).size.width * 0.25,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          "${item['stock']} left",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Store Name and Favorite Icon on the same level
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              item['storeName'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              item['isFavorite']
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  item['isFavorite'] ? Colors.red : Colors.grey,
                              size: 30,
                            ),
                            onPressed: () {
                              setState(() {
                                item['isFavorite'] = !item['isFavorite'];
                                if (item['isFavorite']) {
                                  favoriteItems.add(FavoriteItem(
                                    productName: item['itemName'],
                                    imagePath: item['image'],
                                    price: item['price'].toString(),
                                    pickUpTime: item['pickupTime'],
                                    storeName: item['storeName'],
                                    rating: item['rating'],
                                    distance: item['distance'].toDouble(),
                                  ));
                                } else {
                                  favoriteItems.removeWhere((favItem) =>
                                      favItem.productName == item['itemName'] &&
                                      favItem.storeName == item['storeName']);
                                }
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      // Surprise Bag (grey color)
                      Text(
                        item['itemName'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          item['category'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                "Today ${item['pickupTime']}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                "${item['distance']} m",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(
              thickness: 1,
              height: 1,
              color: Colors.grey,
              indent: 0,
              endIndent: 0,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      item['rating'].toStringAsFixed(1),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "RM${item['price'].toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Color.fromARGB(255, 56, 142, 60),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "RM${item['originalPrice'].toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${item['discountRate']}%",
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Implementation for reserving the item
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text(
                        "Reserve",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              maxChildSize: 0.9,
              initialChildSize: 0.7,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Filters",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const Divider(thickness: 1),
                      SwitchListTile(
                        title: const Text("Show sold out",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle:
                            const Text("Include stores with no items left"),
                        value: _showSoldOut,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setModalState(() => _showSoldOut = val);
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text("Pick-up day",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text("Today"),
                            selected: _pickUpToday,
                            selectedColor: Colors.green[100],
                            labelStyle: TextStyle(
                              color: _pickUpToday
                                  ? Colors.green[800]
                                  : Colors.black,
                              fontWeight: _pickUpToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              setModalState(() {
                                _pickUpToday = true;
                                _pickUpTomorrow = false;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text("Tomorrow"),
                            selected: _pickUpTomorrow,
                            selectedColor: Colors.green[100],
                            labelStyle: TextStyle(
                              color: _pickUpTomorrow
                                  ? Colors.green[800]
                                  : Colors.black,
                              fontWeight: _pickUpTomorrow
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              setModalState(() {
                                _pickUpTomorrow = true;
                                _pickUpToday = false;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Pick-up window",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            _pickupWindowRange.start == 0 &&
                                    _pickupWindowRange.end == 24
                                ? "All day"
                                : "${_pickupWindowRange.start.toInt()}:00 - ${_pickupWindowRange.end.toInt()}:00",
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      RangeSlider(
                        values: _pickupWindowRange,
                        min: 0,
                        max: 24,
                        divisions: 24,
                        activeColor: Colors.green,
                        inactiveColor: Colors.green[100],
                        labels: RangeLabels(
                          "${_pickupWindowRange.start.toInt()}:00",
                          "${_pickupWindowRange.end.toInt()}:00",
                        ),
                        onChanged: (RangeValues values) {
                          setModalState(() {
                            _pickupWindowRange = values;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text("Surprise Bag types",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _bagTypes.keys.map((type) {
                          return FilterChip(
                            label: Text(type),
                            selected: _bagTypes[type]!,
                            selectedColor: Colors.green[100],
                            checkmarkColor: Colors.green,
                            onSelected: (val) {
                              setModalState(() {
                                _bagTypes[type] = val;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text("Dietary preferences",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _dietPrefs.keys.map((pref) {
                          return FilterChip(
                            label: Text(pref),
                            selected: _dietPrefs[pref]!,
                            selectedColor: Colors.green[100],
                            checkmarkColor: Colors.green,
                            onSelected: (val) {
                              setModalState(() {
                                _dietPrefs[pref] = val;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                _showSoldOut = false;
                                _pickUpToday = true;
                                _pickUpTomorrow = false;
                                _pickupWindowRange = const RangeValues(0, 24);
                                _bagTypes.updateAll((key, value) => false);
                                _dietPrefs.updateAll((key, value) => false);
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Clear all",
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Apply",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
