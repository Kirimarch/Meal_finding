import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/search_filter_provider.dart';
import '../thai_districts.dart';

// Province autocomplete needs local TextEditingController state to drive the
// Autocomplete fieldViewBuilder, so it lives in its own ConsumerStatefulWidget.
class _LocationSelector extends ConsumerStatefulWidget {
  const _LocationSelector();

  @override
  ConsumerState<_LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends ConsumerState<_LocationSelector> {
  final List<String> _thaiProvinces =
      List<String>.from(thaiAddressTree.keys)..sort();

  // Tracks the text shown in the province field so we can sync it when the
  // provider resets (e.g. when useCustomLocation is toggled off then on).
  String _lastSyncedProvince = '';

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(searchFilterProvider);
    final notifier = ref.read(searchFilterProvider.notifier);

    final prov = filter.province;
    final dist = filter.district;

    final hasProv = thaiAddressTree.containsKey(prov);
    final districts =
        hasProv ? (List<String>.from(thaiAddressTree[prov]!.keys)..sort()) : <String>[];

    final hasDist =
        hasProv && thaiAddressTree[prov]!.containsKey(dist) && dist.isNotEmpty;
    final subDistricts = hasDist
        ? (List<String>.from(thaiAddressTree[prov]![dist]!)..sort())
        : <String>[];

    // Validate stored district/subDistrict against current lists.
    final validDist =
        districts.contains(filter.district) ? filter.district : '';
    final validSub =
        subDistricts.contains(filter.subDistrict) ? filter.subDistrict : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // Province autocomplete
        LayoutBuilder(
          builder: (context, constraints) => Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return _thaiProvinces
                  .where((p) => p.contains(textEditingValue.text));
            },
            onSelected: (String selection) {
              notifier.setProvince(selection);
              _lastSyncedProvince = selection;
            },
            fieldViewBuilder:
                (context, fieldController, focusNode, onEditingComplete) {
              // Sync the field controller when the provider resets the province.
              if (filter.province != _lastSyncedProvince) {
                _lastSyncedProvince = filter.province;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) fieldController.text = filter.province;
                });
              }
              return TextField(
                controller: fieldController,
                focusNode: focusNode,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'ค้นหาจังหวัด...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.map_outlined,
                      color: Colors.white38, size: 20),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) {
                  // Typing manually: update province and reset children.
                  notifier.setProvince(val);
                  _lastSyncedProvince = val;
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: const Color(0xFF1E1E1E),
                  elevation: 8.0,
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth, maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final String option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            child: Text(option,
                                style:
                                    GoogleFonts.outfit(color: Colors.white70)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // District + SubDistrict row
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    isDense: true,
                    hint: Text('อำเภอ/เขต',
                        style:
                            GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                    value: validDist.isEmpty ? null : validDist,
                    items: [
                      if (hasProv)
                        const DropdownMenuItem<String>(
                            value: '', child: Text('ทุกอำเภอ')),
                      ...districts
                          .map((d) => DropdownMenuItem(value: d, child: Text(d))),
                    ],
                    onChanged: hasProv
                        ? (val) => notifier.setDistrict(val ?? '')
                        : null,
                    disabledHint: Text('เลือกจังหวัด',
                        style:
                            GoogleFonts.outfit(color: Colors.white24, fontSize: 12)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    isDense: true,
                    hint: Text('ตำบล/แขวง',
                        style:
                            GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                    value: validSub.isEmpty ? null : validSub,
                    items: [
                      if (hasDist)
                        const DropdownMenuItem<String>(
                            value: '', child: Text('ทุกตำบล')),
                      ...subDistricts
                          .map((s) => DropdownMenuItem(value: s, child: Text(s))),
                    ],
                    onChanged: hasDist
                        ? (val) => notifier.setSubDistrict(val ?? '')
                        : null,
                    disabledHint: Text('เลือกอำเภอ',
                        style:
                            GoogleFonts.outfit(color: Colors.white24, fontSize: 12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FilterPanel extends ConsumerWidget {
  const FilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(filterExpandedProvider);
    final filter = ref.watch(searchFilterProvider);
    final notifier = ref.read(searchFilterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header toggle
            InkWell(
              onTap: () => ref
                  .read(filterExpandedProvider.notifier)
                  .state = !isExpanded,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded,
                          color: Colors.white70, size: 20),
                      const SizedBox(width: 10),
                      Text('ตั้งค่าฟิลเตอร์ & สถานที่',
                          style:
                              GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),

            if (isExpanded) ...[
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),

              // Custom location toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('ตั้งค่าสถานที่เอง (จังหวัด/อำเภอ/ตำบล)',
                        style: GoogleFonts.outfit(color: Colors.white70)),
                  ),
                  Switch(
                    value: filter.useCustomLocation,
                    activeColor: const Color(0xFFEB1555),
                    onChanged: notifier.setUseCustomLocation,
                  ),
                ],
              ),

              if (!filter.useCustomLocation) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ระยะค้นหา',
                        style: GoogleFonts.outfit(color: Colors.white38)),
                    Text(
                      '${(filter.radius / 1000).toStringAsFixed(1)} กม.',
                      style: GoogleFonts.outfit(
                          color: const Color(0xFFEB1555),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFEB1555),
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.white,
                    overlayColor: const Color(0xFFEB1555).withOpacity(0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: filter.radius,
                    min: 500,
                    max: 5000,
                    divisions: 9,
                    onChanged: notifier.setRadius,
                  ),
                ),
              ] else ...[
                const _LocationSelector(),
              ],

              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // Rating dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ระดับความอร่อย',
                      style: GoogleFonts.outfit(color: Colors.white38)),
                  DropdownButton<double>(
                    value: filter.minRating,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.w500),
                    underline: const SizedBox(),
                    icon:
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                    items: const [
                      DropdownMenuItem(
                          value: 0.0, child: Text(' ไม่จำกัดดาว ')),
                      DropdownMenuItem(
                          value: 3.5, child: Text(' 3.5 ดาวขึ้นไป ')),
                      DropdownMenuItem(
                          value: 4.0, child: Text(' 4.0 ดาวขึ้นไป ')),
                      DropdownMenuItem(
                          value: 4.5, child: Text(' 4.5 ดาวขึ้นไป ')),
                    ],
                    onChanged: (val) {
                      if (val != null) notifier.setMinRating(val);
                    },
                  ),
                ],
              ),

              // Open now switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('สถานะร้าน',
                      style: GoogleFonts.outfit(color: Colors.white38)),
                  Row(
                    children: [
                      Text(
                        filter.openNow ? 'เปิดอยู่เท่านั้น' : 'เปิด/ปิด ก็ได้',
                        style: GoogleFonts.outfit(
                            color: filter.openNow
                                ? Colors.greenAccent
                                : Colors.white60),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: filter.openNow,
                        activeColor: Colors.greenAccent,
                        onChanged: notifier.setOpenNow,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
