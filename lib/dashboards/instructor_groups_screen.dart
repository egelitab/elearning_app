import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InstructorGroupsScreen extends StatefulWidget {
  const InstructorGroupsScreen({super.key});

  @override
  State<InstructorGroupsScreen> createState() => _InstructorGroupsScreenState();
}

class _InstructorGroupsScreenState extends State<InstructorGroupsScreen> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _courses = [];
  List<dynamic> _groups = [];
  List<dynamic> _targets = [];
  bool _isLoading = true;
  String? _error;

  // Search state
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> get _filteredGroups {
    if (_searchQuery.isEmpty) return _groups;
    return _groups.where((g) {
      final String batchName = (g["batch_name"] ?? "").toString().toLowerCase();
      final String courseTitle = (g["course_title"] ?? "").toString().toLowerCase();
      final String query = _searchQuery.toLowerCase();
      return batchName.contains(query) || courseTitle.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch courses and targets in parallel
      final results = await Future.wait([
        _apiService.getInstructorCourses().timeout(const Duration(seconds: 10)),
        _apiService.getInstructorTargets().timeout(const Duration(seconds: 10)),
      ]);

      final courses = results[0] as List<dynamic>;
      final targets = results[1] as List<dynamic>;
      
      // Fetch groups for all courses in parallel with individual timeouts
      final groupFutures = courses.map((course) => 
        _apiService.getGroups(course['id'].toString())
          .timeout(const Duration(seconds: 7))
          .catchError((e) => []) // If one course fails, just return empty list for it
      );
      
      final groupResults = await Future.wait(groupFutures);
      
      List<dynamic> allBatches = [];
      for (int i = 0; i < courses.length; i++) {
        final courseGroups = groupResults[i];
        if (courseGroups is List && courseGroups.isNotEmpty) {
          // Group these specific groups by batch_name
          final Map<String, List<dynamic>> batchesMap = {};
          for (var g in courseGroups) {
            final String bName = g['batch_name'] ?? 'General Groups';
            if (!batchesMap.containsKey(bName)) batchesMap[bName] = [];
            batchesMap[bName]!.add(g);
          }
          
          batchesMap.forEach((name, groups) {
            allBatches.add({
              "batch_name": name,
              "course_id": courses[i]['id'],
              "course_title": courses[i]['title'] ?? courses[i]['course_code'] ?? "Course",
              "groups": groups,
            });
          });
        }
      }

      if (mounted) {
        setState(() {
          _courses = courses;
          _targets = targets;
          _groups = allBatches;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().contains('TimeoutException') 
              ? "Request timed out. Please check your connection."
              : e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCreateGroupBottomSheet() {
    String? selectedCourseId;
    String? selectedDepartmentId;
    String? selectedSection;
    String? groupName;
    int groupSize = 5;
    String groupingMethod = 'Random';
    List<dynamic> currentCourseStats = [];
    bool isFetchingStats = false;
    
    final List<String> methods = ['Random', 'Alphabetic', 'GPA Top Distributed'];
    final TextEditingController nameController = TextEditingController();
    final TextEditingController sizeController = TextEditingController(text: '5');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // 1. Filter unique departments from the course stats
            final Set<String> uniqueDeptIds = currentCourseStats.map((s) => s["department_id"].toString()).toSet();
            final List<dynamic> availableDepts = [];
            for (var deptId in uniqueDeptIds) {
              final stat = currentCourseStats.firstWhere((s) => s["department_id"].toString() == deptId);
              availableDepts.add({
                "id": stat["department_id"],
                "name": stat["department_name"],
              });
            }

            // Auto-select department if only one is available
            if (availableDepts.length == 1 && selectedDepartmentId == null && !isFetchingStats) {
              Future.delayed(Duration.zero, () {
                setSheetState(() {
                  selectedDepartmentId = availableDepts[0]["id"].toString();
                });
              });
            }

            // 2. Filter sections from stats based on selected department
            final List<String> availableSections = selectedDepartmentId != null
              ? currentCourseStats
                  .where((s) => s["department_id"].toString() == selectedDepartmentId)
                  .map((s) => s["section"].toString())
                  .toSet()
                  .toList()
              : [];
            
            // Auto-select section if only one is available
            if (availableSections.length == 1 && selectedSection == null && selectedDepartmentId != null) {
              Future.delayed(Duration.zero, () {
                setSheetState(() {
                  selectedSection = availableSections[0];
                });
              });
            }

            // Calculate the exact count for selected dept and section
            int currentSegmentCount = 0;
            if (selectedDepartmentId != null && selectedSection != null) {
              final stat = currentCourseStats.firstWhere(
                (s) => s["department_id"].toString() == selectedDepartmentId && s["section"].toString() == selectedSection,
                orElse: () => null
              );
              if (stat != null) {
                currentSegmentCount = stat["student_count"] ?? 0;
              }
            }

            return Container(
              padding: EdgeInsets.only(
                top: 20, 
                left: 20, 
                right: 20, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 30
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Form New Groups",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F)),
                    ),
                    const SizedBox(height: 20),
                    
                    const Text("Group Title", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "e.g., Final Project Teams",
                        filled: true,
                        fillColor: const Color(0xFFF4F7FC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) {
                        setSheetState(() {
                          groupName = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text("Select Course", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text("Choose Course"),
                          value: selectedCourseId,
                          items: _courses.map((course) {
                            return DropdownMenuItem<String>(
                              value: course["id"],
                              child: Text("${course['title']}"),
                            );
                          }).toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              setSheetState(() {
                                isFetchingStats = true;
                                selectedCourseId = val;
                                selectedDepartmentId = null;
                                selectedSection = null;
                                currentCourseStats = [];
                              });
                              
                              try {
                                final stats = await _apiService.getCourseEnrollmentStats(val);
                                setSheetState(() {
                                  currentCourseStats = stats;
                                  isFetchingStats = false;
                                });
                              } catch (e) {
                                setSheetState(() => isFetchingStats = false);
                              }
                            }
                          },
                        ),
                      ),
                    ),

                    if (isFetchingStats) ...[
                      const SizedBox(height: 10),
                      const Center(child: LinearProgressIndicator(minHeight: 2)),
                    ],

                    if (selectedCourseId != null) ...[
                      const SizedBox(height: 20),
                      const Text("Select Department", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7FC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text("Choose Department"),
                            value: selectedDepartmentId,
                            items: availableDepts.map((dept) {
                              return DropdownMenuItem<String>(
                                value: dept["id"].toString(),
                                child: Text("${dept['name']}"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setSheetState(() {
                                selectedDepartmentId = val;
                                selectedSection = null; // Reset section
                              });
                            },
                          ),
                        ),
                      ),
                    ],

                    if (selectedDepartmentId != null) ...[
                      const SizedBox(height: 20),
                      const Text("Select Section", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7FC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text("Choose Section"),
                            value: selectedSection,
                            items: availableSections.map((sec) {
                              return DropdownMenuItem<String>(
                                value: sec,
                                child: Text(sec),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setSheetState(() {
                                selectedSection = val;
                              });
                            },
                          ),
                        ),
                      ),
                      
                      if (selectedSection != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people_alt_rounded, color: Color(0xFF09AEF5), size: 20),
                              const SizedBox(width: 10),
                              const Text(
                                "Students in Section:", 
                                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)
                              ),
                              const Spacer(),
                              Text(
                                "$currentSegmentCount",
                                style: const TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Students Per Group", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: sizeController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF4F7FC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: EdgeInsets.zero,
                                  prefixIcon: IconButton(
                                    icon: const Icon(Icons.remove_rounded, color: Color(0xFF05398F), size: 20),
                                    onPressed: () {
                                      if (groupSize > 1) {
                                        setSheetState(() {
                                          groupSize--;
                                          sizeController.text = groupSize.toString();
                                        });
                                      }
                                    },
                                    splashRadius: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.add_rounded, color: Color(0xFF05398F), size: 20),
                                    onPressed: () {
                                      setSheetState(() {
                                        groupSize++;
                                        sizeController.text = groupSize.toString();
                                      });
                                    },
                                    splashRadius: 20,
                                  ),
                                ),
                                onChanged: (val) {
                                  if (int.tryParse(val) != null) {
                                    setSheetState(() {
                                      groupSize = int.parse(val);
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Grouping Method", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F7FC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: groupingMethod,
                                    items: methods.map((m) {
                                      return DropdownMenuItem<String>(value: m, child: Text(m, style: const TextStyle(fontSize: 14)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setSheetState(() => groupingMethod = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 35),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (selectedCourseId != null && selectedDepartmentId != null && selectedSection != null && groupName != null && groupName!.isNotEmpty && groupSize > 0) 
                          ? () {
                              if (groupingMethod == 'GPA Top Distributed') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("GPA Top Distributed feature is not available yet"),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.orange,
                                  )
                                );
                                return;
                              }

                              int totalStudents = currentSegmentCount;
                              int remainder = totalStudents % groupSize;

                              if (remainder != 0) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                  title: const Text("Uneven Distribution"),
                                  content: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Colors.black87, fontSize: 15, fontFamily: 'Inter'),
                                      children: [
                                        const TextSpan(text: "The group size does not evenly divide "),
                                        TextSpan(text: "$totalStudents", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                                        const TextSpan(text: " students. One group will have "),
                                        TextSpan(text: "$remainder", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                        const TextSpan(text: " students. Proceed?"),
                                      ],
                                    ),
                                  ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          Navigator.pop(context);
                                          _finalizeGroupCreation(groupName!, selectedCourseId!, groupSize, groupingMethod, departmentId: selectedDepartmentId, section: selectedSection);
                                        },
                                        child: const Text("Continue"),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                Navigator.pop(context); // Close sheet
                                _finalizeGroupCreation(groupName!, selectedCourseId!, groupSize, groupingMethod, departmentId: selectedDepartmentId, section: selectedSection);
                              }
                          } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF09AEF5),
                          disabledBackgroundColor: Colors.black12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: (selectedCourseId != null && selectedDepartmentId != null && selectedSection != null && groupName != null && groupName!.isNotEmpty && groupSize > 0) ? 4 : 0,
                        ),
                        child: const Text("Generate Groups", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _finalizeGroupCreation(String title, String courseId, int size, String method, {String? departmentId, String? section}) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating groups..."), behavior: SnackBarBehavior.floating));
      
      await _apiService.generateGroups(courseId, size, departmentId: departmentId, section: section, method: method, title: title);
      
      _fetchData(); // Reload everything
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Successfully formed groups!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  void _confirmDeleteBatch(Map<String, dynamic> batch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Groups?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text("Are you sure you want to delete all groups in '${batch['batch_name']}'? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteBatch(batch);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  void _deleteBatch(Map<String, dynamic> batch) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removing groups..."), behavior: SnackBarBehavior.floating));
      await _apiService.deleteGroupBatch(batch['course_id'].toString(), batch['batch_name']);
      _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Groups removed successfully"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF05398F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Search group sets...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.black38),
              ),
              style: const TextStyle(color: Color(0xFF05398F), fontSize: 18),
              onChanged: (val) => setState(() => _searchQuery = val),
            )
          : const Text(
              "Manage Groups", 
              style: TextStyle(color: Color(0xFF05398F), fontSize: 22, fontWeight: FontWeight.bold)
            ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: const Color(0xFF05398F)), 
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = "";
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSearching ? "Search Results" : "Active Course Groups",
                    style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),

                  ..._filteredGroups.map((groupSet) => _buildGroupSetTile(groupSet)).toList(),
                  
                  if (_filteredGroups.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40.0),
                        child: Text("No groups found.", style: TextStyle(color: Colors.black38)),
                      )
                    ),

                  const SizedBox(height: 100), // padding for FAB
                ],
              ),
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "form_groups_btn",
            onPressed: _showCreateGroupBottomSheet,
            backgroundColor: const Color(0xFF09AEF5),
            elevation: 4,
            icon: const Icon(Icons.groups_rounded, color: Colors.white),
            label: const Text("Form New Groups", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSetTile(Map<String, dynamic> batch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF09AEF5).withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.auto_awesome_motion_rounded, color: Color(0xFF09AEF5)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(batch["batch_name"] ?? "General Groups", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                    const SizedBox(height: 4),
                    Text(batch["course_title"] ?? "Course", style: const TextStyle(fontSize: 13, color: Colors.black45)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.black38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                onSelected: (value) {
                  if (value == 'delete') _confirmDeleteBatch(batch);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        SizedBox(width: 10),
                        Text("Remove", style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text("${(batch["groups"] as List).length} Groups formed", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => GroupDetailScreen(batch: batch)));
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("More Detail", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF09AEF5), padding: const EdgeInsets.symmetric(horizontal: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class GroupDetailScreen extends StatelessWidget {
  final Map<String, dynamic> batch;

  const GroupDetailScreen({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> groups = batch["groups"] ?? [];
    
    // Extract unique depts and sections from the groups in this batch
    final depts = groups.map((g) => g["department_name"]).where((d) => d != null).toSet().join(", ");
    final sections = groups.map((g) => g["section"]).where((s) => s != null).toSet().join(", ");
    final method = (groups.isNotEmpty && groups[0]["method"] != null) ? groups[0]["method"] : "N/A";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF05398F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          batch["batch_name"] ?? "Group Details",
          style: const TextStyle(color: Color(0xFF05398F), fontSize: 20, fontWeight: FontWeight.bold)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.school_rounded, "Course", batch["course_title"] ?? "N/A"),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.business_rounded, "Department/s", depts.isEmpty ? "All" : depts),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.class_rounded, "Section/s", sections.isEmpty ? "All" : sections),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.settings_suggest_rounded, "Method", method),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Row(
              children: [
                const Text("Formed Groups", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                const Spacer(),
                Text("${groups.length} Groups", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 15),

            ...groups.map((group) => _buildGroupCard(group)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF09AEF5), size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Color(0xFF05398F), fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final members = group["members"] as List<dynamic>? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF09AEF5).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.group_work_rounded, color: Color(0xFF09AEF5), size: 20),
          ),
          title: Text(group["name"] ?? "Group", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
          subtitle: Text("${members.length} members", style: const TextStyle(fontSize: 12, color: Colors.black45)),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
          children: members.map((m) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: Colors.black38),
                const SizedBox(width: 10),
                Text(m["full_name"] ?? "Unnamed", style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}
