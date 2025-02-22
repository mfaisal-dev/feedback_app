import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationPickerPage extends StatefulWidget {
  @override
  _LocationPickerPageState createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  LatLng? _pickedLocation; // Store the picked location
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  bool _isLoading = false; // For loading state during GPS or search
  String? _locationName; // Store the name of the location

  // Function to search for a location using OpenStreetMap's Nominatim API
  Future<void> _searchLocation(String query) async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=$query',);
    final response = await http.get(url);
    final data = json.decode(response.body);
    if (data.isNotEmpty) {
      setState(() {
        _pickedLocation = LatLng(
          double.parse(data[0]['lat']),
          double.parse(data[0]['lon']),
        );
        _mapController.move(_pickedLocation!, 15.0); // Move map to the searched location
        _isLoading = false;
        _fetchLocationName(_pickedLocation!); // Fetch location name
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not found')),
      );
    }
  }

  // Function to get the user's current location using GPS
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them.'),
          ),
        );
        return;
      }

      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are required to use this feature.'),
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied. Enable them in settings.'),
          ),
        );
        return;
      }

      // Fetch the current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _pickedLocation = newLocation;
        _isLoading = false;
      });

      _mapController.move(newLocation, 15.0); // Move map to new location
      _fetchLocationName(newLocation); // Fetch location name

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch location: $e')),
      );
    }
  }

  // Function to fetch the location name (address) using reverse geocoding
  Future<void> _fetchLocationName(LatLng location) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['display_name'] != null) {
      setState(() {
        _locationName = data['display_name'];
      });
    } else {
      setState(() {
        _locationName = 'Unknown Location';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick a Location"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Get Current Location',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a location...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _searchLocation(_searchController.text),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Display Location Name
          if (_locationName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _locationName!,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(0, 0), // Default center
                    initialZoom: 2.0, // Default zoom
                    onTap: (tapPosition, latLng) {
                      setState(() {
                        _pickedLocation = latLng; // Update picked location on tap
                        _fetchLocationName(latLng); // Fetch location name
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    if (_pickedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pickedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _pickedLocation != null
          ? FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, {
            'latitude': _pickedLocation!.latitude,
            'longitude': _pickedLocation!.longitude,
            'name': _locationName,
          }); // Return location data
        },
        child: const Icon(Icons.check),
      )
          : null,
    );
  }
}
