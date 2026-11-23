import 'package:flutter/material.dart';
import 'package:waiting_room_app/models/client.dart';

class ClientCard extends StatelessWidget {
  const ClientCard({super.key, required this.client, this.onDelete});

  final Client client;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            client.hasLocation ? Icons.location_on : Icons.person,
            color: client.hasLocation ? Colors.green : null,
          ),
        ),
        title: Text(client.name),
        subtitle: Text(
          client.hasLocation
              ? '📍 ${client.locationText}'
              : '📍 Location not captured',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message:
                  client.isSynced ? 'Synchronisé' : 'En attente de synchro',
              child: Icon(
                client.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                color: client.isSynced ? Colors.green : Colors.orange,
                size: 20,
              ),
            ),
            IconButton(
              tooltip: 'Retirer ${client.name}',
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
