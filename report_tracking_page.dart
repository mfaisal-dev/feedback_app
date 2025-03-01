import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'issue_details_page.dart';

class ReportTrackingPage extends StatelessWidget {
  final String studentId;

  ReportTrackingPage({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports', style: TextStyle(
          fontWeight: FontWeight.bold, color: Colors.white )),
        centerTitle: true,
        backgroundColor: const Color(0xFF2A2A72),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF2A2A72)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
        StreamBuilder(

          stream: FirebaseFirestore.instance
              .collection('issues')
              .where('studentId', isEqualTo: studentId)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            final issues = snapshot.data!.docs;
            if (issues.isEmpty) {
              return const Center(
                child: Text(
                  'No reports found!',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: issues.length,
              itemBuilder: (context, index) {
                final issue = issues[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      issue['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.circle, color: _getStatusColor(issue['status']), size: 14),
                            const SizedBox(width: 5),
                            Text(
                              'Status: ${issue['status']}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(issue['status']),
                              ),
                            ),
                          ],
                        ),
                        if (issue['imageUrl'] != null && issue['imageUrl'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(issue['imageUrl'], height: 120, fit: BoxFit.cover),
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IssueDetailsPage(issueId: issue.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
