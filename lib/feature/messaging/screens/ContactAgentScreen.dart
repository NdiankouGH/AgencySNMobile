import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';



class ContactAgentScreen extends StatefulWidget {
  final String? documentId;
  final String? agentId;

  const ContactAgentScreen({Key? key, this.documentId, this.agentId}) : super(key: key);

  @override
  _ContactAgentScreenState createState() => _ContactAgentScreenState();
}

class _ContactAgentScreenState extends State<ContactAgentScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _sendMessage() async {
    final user = _auth.currentUser;

    if (_messageController.text.isEmpty) return;

    if(user == null){
      // L'utilisateur doit être connecté pour envoyer un message
      throw Exception("Vous devez être connecté pour contacter l'agent.");
    }
    final messageData = {
      'senderId': user?.uid,
      'receiverId': widget.agentId,
      'documentId': widget.documentId,
      'message': _messageController.text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('messages').add(messageData);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacter l\'agent'),
        backgroundColor: Colors.blue[400],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('documentId', isEqualTo: widget.documentId)
                  .where('receiverId', isEqualTo: widget.agentId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSender = message['senderId'] == _auth.currentUser?.uid;

                    return ListTile(
                      title: Align(
                        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: isSender ? Colors.blueAccent : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            message['message'],
                            style: TextStyle(
                              color: isSender ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      subtitle: Text("Envoyé le ${message['timestamp']}"),

                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Écrire un message...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }


}
