import 'package:flutter/material.dart';

class InstructorInboxScreen extends StatefulWidget {
  const InstructorInboxScreen({super.key});

  @override
  State<InstructorInboxScreen> createState() => _InstructorInboxScreenState();
}

class _InstructorInboxScreenState extends State<InstructorInboxScreen> {
  bool isChatSelected = true; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC), // Match background color to theme
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        centerTitle: false,
        title: const Text("Inbox", style: TextStyle(color: Color(0xFF05398F), fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF05398F)), 
            onPressed: () {}
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          
          // 1. Custom Toggle Switch (Chat / Announce)
          _buildToggleSwitch(),
          
          const SizedBox(height: 20),

          // 2. Dynamic Content List
          Expanded(
            child: isChatSelected ? _buildChatList() : _buildAnnouncementsList(),
          ),
        ],
      ),
      // 3. Floating Action Button for New Message
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF09AEF5),
        elevation: 4,
        child: Icon(
          isChatSelected ? Icons.maps_ugc_rounded : Icons.campaign_rounded, 
          color: Colors.white, 
          size: 28
        ),
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isChatSelected = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isChatSelected ? Colors.white : Colors.transparent, 
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isChatSelected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))] : [],
                ),
                child: Center(
                  child: Text(
                    "Chats",
                    style: TextStyle(
                      color: isChatSelected ? const Color(0xFF05398F) : Colors.black54,
                      fontWeight: isChatSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isChatSelected = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: !isChatSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isChatSelected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))] : [],
                ),
                child: Center(
                  child: Text(
                    "Announcements",
                    style: TextStyle(
                      color: !isChatSelected ? const Color(0xFF05398F) : Colors.black54,
                      fontWeight: !isChatSelected ? FontWeight.bold : FontWeight.w600,
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

  Widget _buildChatTile(String name, String message, String count, String time, Color avatarColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: avatarColor.withOpacity(0.15),
                  child: Text(name[0], style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                          Text(time, style: TextStyle(color: count.isNotEmpty ? const Color(0xFF09AEF5) : Colors.black38, fontSize: 12, fontWeight: count.isNotEmpty ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              message, 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: count.isNotEmpty ? Colors.black87 : Colors.black54, fontWeight: count.isNotEmpty ? FontWeight.w600 : FontWeight.normal),
                            ),
                          ),
                          if (count.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Color(0xFF09AEF5), shape: BoxShape.circle),
                              child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildChatList() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildChatTile("Natasha", "Hi, Good Evening Prof!", "3", "14:59", Colors.purple),
        _buildChatTile("Alex", "I Just Finished It..!", "2", "06:35", Colors.orange),
        _buildChatTile("John", "How are you?", "", "08:10", Colors.blue),
        _buildChatTile("Mia", "Could we get an extension?", "5", "Yesterday", Colors.green),
        _buildChatTile("Maria", "Understood, thank you.", "", "Yesterday", Colors.red),
        _buildChatTile("Tiya", "When is the next lecture?", "1", "Mon", Colors.teal),
        _buildChatTile("Manisha", "I've uploaded my assignment.", "", "Mon", Colors.indigo),
      ],
    );
  }

  Widget _buildAnnouncementsList() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildAnnouncementTile(
          "Final Exam Schedule", 
          "The final exam for ITCS 414 will be held on Dec 15th at 9:00 AM.", 
          "2 hrs ago", 
          Icons.event_note_rounded,
          Colors.orange
        ),
        _buildAnnouncementTile(
          "Assignment 3 Grades Posted", 
          "Grades for Assignment 3 have been published to the portal. Please review the feedback.", 
          "Yesterday", 
          Icons.grade_rounded,
          Colors.green
        ),
        _buildAnnouncementTile(
          "Guest Speaker Tomorrow", 
          "We will have a guest speaker from Google joining our class tomorrow. Attendance is mandatory.", 
          "Oct 24", 
          Icons.campaign_rounded,
          Colors.blue
        ),
        _buildAnnouncementTile(
          "Syllabus Update", 
          "Please check the updated syllabus for changes regarding the final project requirements.", 
          "Oct 15", 
          Icons.info_outline_rounded,
          const Color(0xFF09AEF5)
        ),
      ],
    );
  }

  Widget _buildAnnouncementTile(String title, String description, String time, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      )
                    ),
                    Text(time, style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description, 
                  style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}