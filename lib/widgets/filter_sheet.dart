import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterSheet extends StatefulWidget {
  final List<String> selectedGenres;
  final String? selectedYear;
  final double minRating;
  final String? selectedLanguage;
  final Function(List<String>, String?, double, String?) onApply;

  const FilterSheet({
    super.key,
    required this.selectedGenres,
    this.selectedYear,
    required this.minRating,
    this.selectedLanguage,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late List<String> _selectedGenres;
  late String? _selectedYear;
  late double _minRating;
  String? _selectedLanguage;

  static const genres = [
    'Action',
    'Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Family',
    'Fantasy',
    'History',
    'Horror',
    'Music',
    'Mystery',
    'Romance',
    'Science Fiction',
    'Thriller',
    'War',
    'Western',
  ];

  late final List<String> _years;

  @override
  void initState() {
    super.initState();
    _selectedGenres = List.from(widget.selectedGenres);
    _selectedYear = widget.selectedYear;
    _minRating = widget.minRating;
    _selectedLanguage = widget.selectedLanguage;
    _years = List.generate(50, (i) => (DateTime.now().year - i).toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: Text(
                  'Reset',
                  style: GoogleFonts.inter(color: Colors.blueAccent),
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white10),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Genre selection
                _buildSectionTitle('Genres'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: genres.map((genre) {
                    final selected = _selectedGenres.contains(genre);
                    return FilterChip(
                      label: Text(
                        genre,
                        style: GoogleFonts.inter(
                          color: selected ? Colors.white : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      selected: selected,
                      selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
                      checkmarkColor: Colors.blueAccent,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      side: BorderSide(
                        color: selected
                            ? Colors.blueAccent.withValues(alpha: 0.5)
                            : Colors.white10,
                      ),
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selectedGenres.add(genre);
                          } else {
                            _selectedGenres.remove(genre);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Year selection
                _buildSectionTitle('Release Year'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedYear,
                    hint: Text(
                      'Select year',
                      style: GoogleFonts.inter(color: Colors.white38),
                    ),
                    dropdownColor: const Color(0xFF1A1A2E),
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white38,
                    ),
                    style: GoogleFonts.inter(color: Colors.white),
                    items: _years.map((year) {
                      return DropdownMenuItem(value: year, child: Text(year));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedYear = value),
                  ),
                ),

                const SizedBox(height: 24),

                // Rating slider
                _buildSectionTitle('Minimum Rating: ${_minRating.toInt()}+'),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.blueAccent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.blueAccent,
                    overlayColor: Colors.blueAccent.withValues(alpha: 0.2),
                    valueIndicatorColor: Colors.blueAccent,
                    valueIndicatorTextStyle: GoogleFonts.inter(
                      color: Colors.white,
                    ),
                  ),
                  child: Slider(
                    value: _minRating,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _minRating.toInt().toString(),
                    onChanged: (value) => setState(() => _minRating = value),
                  ),
                ),

                const SizedBox(height: 24),

                // Language
                _buildSectionTitle('Language'),
                Wrap(
                  spacing: 8,
                  children: ['Hindi', 'English', 'Dual Audio'].map((lang) {
                    return ChoiceChip(
                      label: Text(
                        lang,
                        style: GoogleFonts.inter(
                          color: _selectedLanguage == lang
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      selected: _selectedLanguage == lang,
                      selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      side: BorderSide(
                        color: _selectedLanguage == lang
                            ? Colors.blueAccent.withValues(alpha: 0.5)
                            : Colors.white10,
                      ),
                      onSelected: (selected) {
                        setState(
                          () => _selectedLanguage = selected ? lang : null,
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => widget.onApply(
                _selectedGenres,
                _selectedYear,
                _minRating,
                _selectedLanguage,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Apply Filters',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedGenres.clear();
      _selectedYear = null;
      _minRating = 0;
      _selectedLanguage = null;
    });
  }
}
