import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waiting_room_app/queue_provider.dart';
import 'package:waiting_room_app/widgets/client_card.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addClient() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    _controller.clear();
    await context.read<QueueProvider>().addClient(name);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QueueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Waiting Room'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (provider.isDemo)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.all(10),
              child: const Text(
                'Mode démo : les clients sont stockés localement, sans Supabase.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          if (provider.error != null)
            MaterialBanner(
              content: Text(provider.error!),
              actions: [
                TextButton(
                  onPressed: provider.clearError,
                  child: const Text('Fermer'),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Client name',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addClient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  key: const Key('add-client-button'),
                  onPressed: _addClient,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Text(
            'Clients in Queue: ${provider.clients.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildQueue(context, provider)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.clients.isEmpty
                    ? null
                    : () => context.read<QueueProvider>().nextClient(),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next Client'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueue(BuildContext context, QueueProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.clients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No one in queue yet...'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.clients.length,
      itemBuilder: (context, index) {
        final client = provider.clients[index];
        return ClientCard(
          client: client,
          onDelete: () => context.read<QueueProvider>().removeClient(client.id),
        );
      },
    );
  }
}
