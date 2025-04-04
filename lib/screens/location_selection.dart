import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:flutter_map/flutter_map.dart'; // Add flutter_map package
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart'; // For popups on markers

class LocationSelectionPage extends StatefulWidget {
  const LocationSelectionPage({super.key});

  @override
  _LocationSelectionPageState createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  Position? _currentPosition;
  String _currentAddress = "";
  List<Map<String, dynamic>> _nearbyLocations = [];
  bool _isLoading = false;
  String? _errorMessage;
  latlng.LatLng? _selectedLocation; // Store the tapped location
  final MapController _mapController =
      MapController(); // Controller for the map

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              "Location services are disabled. Please enable them in your device settings.";
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = "Location permissions are denied.";
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              "Location permissions are permanently denied. Please enable them in the app settings.";
          _isLoading = false;
        });
        _showPermissionDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _selectedLocation =
            latlng.LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Move map to current location
      _mapController.move(
          latlng.LatLng(position.latitude, position.longitude), 15.0);

      await _fetchAddressFromCoordinates(position);
      await _fetchNearbyLocations(position);
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to get location: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAddressFromCoordinates(Position position) async {
    try {
      final response = await http.get(
        Uri.parse(
            "https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1"),
        headers: {
          'User-Agent':
              'fyp_project/1.0 (your_email@example.com)', // Replace with your app name and email
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _currentAddress = data['display_name'] ?? "Unknown Address";
        });
      } else {
        setState(() {
          _errorMessage = "Failed to fetch address: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to fetch address: $e";
      });
    }
  }

  Future<void> _fetchNearbyLocations(Position position) async {
    try {
      final String overpassQuery = '''
      [out:json];
      (
        node["shop"="bakery"](around:5000,${position.latitude},${position.longitude});
        node["shop"="supermarket"](around:5000,${position.latitude},${position.longitude});
        node["amenity"]="restaurant"](around:5000,${position.latitude},${position.longitude});
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

        setState(() {
          _nearbyLocations = elements.map((element) {
            final name = element['tags']['name'] ?? 'Unknown Location';
            final lat = element['lat'] as double;
            final lon = element['lon'] as double;
            final distance = Geolocator.distanceBetween(
                  position.latitude,
                  position.longitude,
                  lat,
                  lon,
                ) /
                1000; // Convert to kilometers

            return {
              'name': name,
              'distance': distance.toStringAsFixed(1),
              'location': latlng.LatLng(lat, lon),
            };
          }).toList();
        });
      } else {
        setState(() {
          _errorMessage =
              "Failed to fetch nearby locations: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to fetch nearby locations: $e";
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Permission Required"),
          content: const Text(
              "Location permissions are permanently denied. Please enable them in the app settings to continue."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }

  Future<String> _getAddressFromLatLng(latlng.LatLng point) async {
    try {
      final response = await http.get(
        Uri.parse(
            "https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1"),
        headers: {
          'User-Agent': 'fyp_project/1.0 (your_email@example.com)',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['display_name'] ?? "Unknown Address";
      } else {
        return "Failed to fetch address";
      }
    } catch (e) {
      return "Error fetching address: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Location"),
        backgroundColor: const Color.fromARGB(255, 56, 142, 60),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                // Map Section
                SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.4, // 40% of screen height
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition != null
                          ? latlng.LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            )
                          : const latlng.LatLng(
                              0, 0), // Default center if no position
                      initialZoom: 15.0,
                      onTap: (tapPosition, point) async {
                        setState(() {
                          _selectedLocation = point;
                        });
                        String address = await _getAddressFromLatLng(point);
                        setState(() {
                          _currentAddress = address;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          // Current location marker
                          if (_currentPosition != null)
                            Marker(
                              point: latlng.LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 80,
                              height: 80,
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 40,
                              ),
                            ),
                          // Selected location marker
                          if (_selectedLocation != null &&
                              (_selectedLocation!.latitude !=
                                      _currentPosition?.latitude ||
                                  _selectedLocation!.longitude !=
                                      _currentPosition?.longitude))
                            Marker(
                              point: _selectedLocation!,
                              width: 80,
                              height: 80,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          // Nearby locations markers
                          ..._nearbyLocations.map((location) {
                            return Marker(
                              point: location['location'],
                              width: 80,
                              height: 80,
                              child: const Icon(
                                Icons.store,
                                color: Colors.green,
                                size: 30,
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
                ),
                // Current Location Info
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Selected Location:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentAddress.isNotEmpty
                            ? _currentAddress
                            : "Tap the map to select a location",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _selectedLocation != null
                            ? () {
                                Navigator.pop(context, {
                                  'address': _currentAddress,
                                  'location': _selectedLocation,
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 56, 142, 60),
                        ),
                        child: const Text("Confirm Selected Location"),
                      ),
                    ],
                  ),
                ),
                // Nearby Locations List
                Expanded(
                  child: ListView.builder(
                    itemCount: _nearbyLocations.length,
                    itemBuilder: (context, index) {
                      final location = _nearbyLocations[index];
                      return ListTile(
                        title: Text(location['name']),
                        subtitle: Text("Distance: ${location['distance']} km"),
                        onTap: () {
                          setState(() {
                            _selectedLocation = location['location'];
                            _currentAddress = location['name'];
                            _mapController.move(_selectedLocation!, 15.0);
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
