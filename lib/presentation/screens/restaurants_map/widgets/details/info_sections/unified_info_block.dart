import 'package:flutter/material.dart';
import 'opening_hours_section.dart';
import 'address_section.dart';
import 'website_section.dart';
import 'price_section.dart';
import 'cuisine_section.dart';

/// Unified info block combining all restaurant information
class UnifiedInfoBlock extends StatelessWidget {
  final dynamic openingHours;
  final String? address;
  final String? website;
  final String? price;
  final String? cuisine;
  final double lat;
  final double lng;

  const UnifiedInfoBlock({
    super.key,
    required this.openingHours,
    this.address,
    this.website,
    this.price,
    this.cuisine,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    final hasAddress = address != null && address!.isNotEmpty;
    final hasWebsite = website != null && website!.isNotEmpty;
    final hasPrice = price != null && price!.isNotEmpty;
    final hasCuisine = cuisine != null && cuisine!.isNotEmpty;

    final List<Widget> sections = [];

    // Opening Hours (always shown)
    sections.add(OpeningHoursSection(openingHours: openingHours));

    // Price
    if (hasPrice) {
      sections.add(Container(
        height: 5,
        color: const Color(0xFF1C1C1E),
      ));
      sections.add(PriceSection(price: price!));
    }

    // Cuisine
    if (hasCuisine) {
      sections.add(Container(
        height: 5,
        color: const Color(0xFF1C1C1E),
      ));
      sections.add(CuisineSection(cuisine: cuisine!));
    }

    // Address
    if (hasAddress) {
      sections.add(Container(
        height: 5,
        color: const Color(0xFF1C1C1E),
      ));
      sections.add(AddressSection(
        address: address!,
        lat: lat,
        lng: lng,
      ));
    }

    // Website
    if (hasWebsite) {
      sections.add(Container(
        height: 5,
        color: const Color(0xFF1C1C1E),
      ));
      sections.add(WebsiteSection(website: website!));
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: sections),
    );
  }
}
