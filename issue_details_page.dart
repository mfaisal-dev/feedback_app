import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'full_screen_image.dart';

class IssueDetailsPage extends StatefulWidget {
  final String issueId;

  const IssueDetailsPage({super.key, required this.issueId});

  @override
  _IssueDetailsPageState createState() => _IssueDetailsPageState();
}

class _IssueDetailsPageState extends State<IssueDetailsPage> {
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Issue Details", style: TextStyle( color: Colors.white ,fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2A2A72),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('issues').doc(widget.issueId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final issue = snapshot.data!;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF2A2A72)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIssueDetailsCard(issue),
                  const SizedBox(height: 16),
                  _buildCommentsSection(),
                  const SizedBox(height: 16),
                  _buildCommentInput(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Widget for displaying issue details inside a card
  Widget _buildIssueDetailsCard(DocumentSnapshot issue) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(issue['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(issue['description'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  "Status: ${issue['status']}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getStatusColor(issue['status'])),
                ),
              ],
            ),
            if (issue['imageUrl'] != null && issue['imageUrl'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => FullScreenImage(imageUrl: issue['imageUrl']),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      issue['imageUrl'],
                      height: 200,
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
              ),
          ],
        ),
      ),
    );
  }


  /// Widget for displaying comments section
  Widget _buildCommentsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issueId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data!.docs;
        if (comments.isEmpty) {
          return const Center(
            child: Text(
              'No comments yet.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(comment['comment']),
                subtitle: Text(
                  "By: ${comment['author']}",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Widget for adding comments
  Widget _buildCommentInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              labelText: 'Add a Comment',
              labelStyle: const TextStyle(color: Colors.white),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          backgroundColor: Colors.blueAccent,
          child: const Icon(Icons.send, color: Colors.white),
          onPressed: _addComment,
        ),
      ],
    );
  }

  /// Function to add a comment
  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch user role from Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String userRole = 'User'; // Default role
        if (userDoc.exists && userDoc.data() != null) {
          userRole = userDoc.data()!['role'] ?? 'User'; // Use 'role' from Firestore
        }
        // Add comment with role
        await FirebaseFirestore.instance
            .collection('issues')
            .doc(widget.issueId)
            .collection('comments')
            .add({
          'comment': comment,
          'author': userRole,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _commentController.clear(); // Clear input field after adding comment
      }}
  }


  /// Returns color based on issue status
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
