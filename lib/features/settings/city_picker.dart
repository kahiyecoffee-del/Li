import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../domain/models/user_profile.dart';

/// Bottom sheet to search a city (Open-Meteo geocoding). Returns the place.
Future<Place?> pickCity(BuildContext context) =>
    showModalBottomSheet<Place>(context: context, isScrollControlled: true, builder: (_) => const _CitySheet());

class _CitySheet extends ConsumerStatefulWidget {
  const _CitySheet();

  @override
  ConsumerState<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends ConsumerState<_CitySheet> {
  Timer? _debounce;
  List<Place> _results = const [];
  bool _loading = false;
  bool _failed = false;

  void _search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _loading = true);
      try {
        final r = await ref.read(servicesProvider).weather.search(q, Localizations.localeOf(context).languageCode);
        if (mounted) {
          setState(() {
            _results = r;
            _failed = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _failed = true);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(hintText: l.onbPickCity, prefixIcon: const Icon(Icons.search)),
                onChanged: _search,
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_failed) Padding(padding: const EdgeInsets.all(Space.lg), child: Text(l.errorNetwork)),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.location_city_outlined),
                  title: Text(_results[i].name),
                  onTap: () => Navigator.pop(context, _results[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
