import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';

class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch communities immediately when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CommunityProvider>(context, listen: false).loadCommunities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Communities')),
      body: Consumer<CommunityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.communities.isEmpty) {
            return const Center(child: Text('No communities found nearby.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.communities.length,
            itemBuilder: (context, index) {
              final community = provider.communities[index];
              return _buildCommunityCard(context, provider, community);
            },
          );
        },
      ),
    );
  }

  Widget _buildCommunityCard(BuildContext context, CommunityProvider provider, dynamic community) {
    // Note: 'pivot' contains the 'status' from your Laravel backend
    String status = community['pivot']?['status'] ?? 'none';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(community['community_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(community['description'] ?? 'Stay updated with local alerts.'),
        trailing: _buildStatusButton(context, provider, community['id'], status),
      ),
    );
  }

  Widget _buildStatusButton(BuildContext context, CommunityProvider provider, int id, String status) {
    if (status == 'approved') {
      return const Chip(label: Text('Member'), backgroundColor: Colors.greenAccent);
    } else if (status == 'pending') {
      return const OutlinedButton(onPressed: null, child: Text('Pending'));
    } else {
      return ElevatedButton(
        onPressed: () async {
          final result = await provider.requestToJoin(id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        },
        child: const Text('Join'),
      );
    }
  }
}