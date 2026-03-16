import 'package:flutter/material.dart';

class StudentDownloadsScreen extends StatefulWidget {
  const StudentDownloadsScreen({super.key});

  @override
  State<StudentDownloadsScreen> createState() => _StudentDownloadsScreenState();
}

class _StudentDownloadsScreenState extends State<StudentDownloadsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Documents', 'Videos', 'Images'];
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Start scrolled down exactly enough to hide the 190px of expanded flexible space
    _scrollController = ScrollController(initialScrollOffset: 190.0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const _LessStretchyScrollPhysics(parent: AlwaysScrollableScrollPhysics()), 
        slivers: [
          // The SliverAppBar that contains the Storage widget and expands when dragged down
          SliverAppBar(
            backgroundColor: const Color(0xFFF4F7FC),
            elevation: 0,
            pinned: true,
            floating: false,
            stretch: false, 
            expandedHeight: 250.0,
            collapsedHeight: 60.0,
            title: const Text(
              "Downloads",
              style: TextStyle(color: Color(0xFF05398F), fontSize: 24, fontWeight: FontWeight.bold)
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Color(0xFF05398F)),
                onPressed: () {},
              ),
            ],
            // Regular flexible space for storage widget, appears on scroll to top
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildStorageStatus(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
          
          // Sticky Filter Chips Below App Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeaderDelegate(
              child: Container(
                color: const Color(0xFFF4F7FC),
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: _filters.map((filter) {
                      bool isSelected = _selectedFilter == filter;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF09AEF5) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black54,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // Search Results / Download List grouped by Date
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                 _buildDateSection("December 21 2025"),
                 _buildDownloadFileTile("Compiler Design Lecture Note - 2", "8.14 MB", "Miraf M.", Icons.insert_drive_file_rounded, Colors.blue),
                 _buildDownloadFileTile("Research Methods in Computer Scie...", "5.9 MB", "Muluken B.", Icons.insert_drive_file_rounded, Colors.blue),
                 
                 const SizedBox(height: 15),
                 
                 _buildDateSection("January 23 2026"),
                 _buildDownloadFileTile("Complexity Classes Part 2 | NPC (N...", "38.3 MB", "Dr. Debas", Icons.play_circle_fill_rounded, Colors.purple),
                 _buildDownloadFileTile("Image 02", "122 KB", "Abebe M.", Icons.image_rounded, Colors.green),
                 _buildDownloadFileTile("Complexity Theory", "4.4 MB", "Dr. Debas", Icons.insert_drive_file_rounded, Colors.blue),
                 
                 const SizedBox(height: 80), // Padding at bottom for navigation bar
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF09AEF5), Color(0xFF05398F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF05398F).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
               Text("Local Storage Used", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
               Icon(Icons.sd_storage_rounded, color: Colors.white70, size: 20)
            ],
          ),
          const SizedBox(height: 5),
          const Text("182 MB", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: 0.25, 
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            borderRadius: BorderRadius.circular(5),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          const Text("Saved for Offline Viewing", style: TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDateSection(String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 10.0),
      child: Text(
        date, 
        style: const TextStyle(
          fontSize: 15, 
          fontWeight: FontWeight.bold, 
          color: Colors.black87
        )
      ),
    );
  }

  Widget _buildDownloadFileTile(String name, String size, String author, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(size, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Text("•", style: TextStyle(color: Colors.black38, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(author, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black38),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        ],
      ),
    );
  }
}

// Simple Delegate to keep the Filter Header pinned to the top below the AppBar
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FilterHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 60.0;

  @override
  double get minExtent => 60.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

// Custom ScrollPhysics to reduce the overscroll stretch dramatically
class _LessStretchyScrollPhysics extends BouncingScrollPhysics {
  const _LessStretchyScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  _LessStretchyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _LessStretchyScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Add significant drag resistance when revealing the 190.0 top storage region
    // so it requires a purposeful downward drag and doesn't reveal easily on normal scroll.
    final bool isOverscrollingTop = position.pixels <= 190.0 && offset > 0.0;
    if (isOverscrollingTop) {
      return super.applyPhysicsToUserOffset(position, offset) * 0.20;
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }
}

