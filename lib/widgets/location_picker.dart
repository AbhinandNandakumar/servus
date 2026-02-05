// lib/widgets/location_picker.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/location_service.dart';

class LocationPicker extends StatefulWidget {
  final Function(String address, double lat, double lng) onLocationSelected;
  final String? initialAddress;

  const LocationPicker({
    Key? key,
    required this.onLocationSelected,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  Timer? _debounce;

  String? _selectedAddress;
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    _initializeLocationService();

    if (widget.initialAddress != null) {
      _searchController.text = widget.initialAddress!;
      _selectedAddress = widget.initialAddress;
    }

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  Future<void> _initializeLocationService() async {
    await _locationService.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
        return;
      }

      setState(() => _isLoading = true);
      final results = await _locationService.searchPlaces(query);
      setState(() {
        _suggestions = results;
        _showSuggestions = results.isNotEmpty;
        _isLoading = false;
      });
    });
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    setState(() => _isLoading = true);

    final details = await _locationService.getPlaceDetails(place['place_id']);

    if (details != null) {
      setState(() {
        _selectedAddress = details['address'];
        _selectedLat = details['lat'];
        _selectedLng = details['lng'];
        _searchController.text = details['address'];
        _showSuggestions = false;
        _isLoading = false;
      });

      widget.onLocationSelected(
        details['address'],
        details['lat'],
        details['lng'],
      );
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);

    final position = await _locationService.getCurrentPosition();

    if (position != null) {
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedAddress = address ?? 'Current Location';
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
        _searchController.text = _selectedAddress!;
        _showSuggestions = false;
        _isLoading = false;
      });

      widget.onLocationSelected(
        _selectedAddress!,
        position.latitude,
        position.longitude,
      );
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get current location. Please enable location services or search for your address.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Location',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(height: 8),

        // Search field
        TextFormField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search for your location...',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F).withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1E3A5F),
                      ),
                    )
                  : const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF1E3A5F),
                      size: 20,
                    ),
            ),
            suffixIcon: IconButton(
              onPressed: _useCurrentLocation,
              icon: const Icon(Icons.my_location, color: Color(0xFF1E3A5F)),
              tooltip: 'Use current location',
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please select your location';
            }
            return null;
          },
        ),

        // Suggestions dropdown
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final place = _suggestions[index];
                return ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: Color(0xFF1E3A5F),
                    size: 20,
                  ),
                  title: Text(
                    place['description'],
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectPlace(place),
                );
              },
            ),
          ),

        // Selected location indicator
        if (_selectedLat != null && _selectedLng != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location set: ${_selectedLat!.toStringAsFixed(4)}, ${_selectedLng!.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
