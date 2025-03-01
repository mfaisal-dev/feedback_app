import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'full_screen_image.dart';
import 'issue_details_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('issues').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.blue));
            }

            final issues = snapshot.data!.docs;
            return
              ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: issues.length,
              itemBuilder: (context, index) {
                final issue = issues[index];
                final imageUrl = issue['imageUrl'] as String?;

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  shadowColor: Colors.grey.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                issue['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            _getStatusBadge(issue['status']),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => FullScreenImage(imageUrl: imageUrl),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              ),
                            ),
                          ),


                        const SizedBox(height: 10),
                        Text(
                          'Status: ${issue['status']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => IssueDetailsPage(issueId: issue.id),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.info_outline, color: Colors.blue),
                              label: const Text("View Details"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                _showStatusUpdateDialog(context, issue.id, issue['status']);
                              },
                              icon: const Icon(Icons.update, color: Colors.white),
                              label: const Text("Update Status", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );

              },
            );
          },
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, String issueId, String currentStatus) {
    final statusController = TextEditingController(text: currentStatus);
    showDialog(
      context: context,
      builder: (context) {
        return
          AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Update Issue Status', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: statusController,
            decoration: InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String newStatus = statusController.text.trim();
                if (newStatus.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('issues').doc(issueId).update({'status': newStatus});
                }
                Navigator.pop(context);
              },
              child: const Text('Update', style: TextStyle(color: Colors.blue)),),
          ],
          );
      },
    );
  }
}

Widget _getStatusBadge(String status) {
  Color color;
  switch (status.toLowerCase()) {
    case "pending":
      color = Colors.orange;
      break;
    case "resolved":
      color = Colors.green;
      break;
    case "in progress":
      color = Colors.blue;
      break;
    default:
      color = Colors.grey;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      status.toUpperCase(),
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
