import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';
import 'package:url_launcher/url_launcher.dart';


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
    // 1. Access the list of users associated with this community
    final List mobileUsers = community['mobile_users'] ?? [];
    String status = 'none';

    

    if (mobileUsers.isNotEmpty) {
      // DYNAMIC FIX: Ask the provider for the true logged-in user ID
      final int? currentUserId = provider.currentMobileUserId;

      final myRecord = mobileUsers.firstWhere(
        (user) => user['mobile_user_id'] == currentUserId,
        orElse: () => null,
      );

      if (myRecord != null) {
        status = myRecord['pivot']?['status'] ?? 'none';
      }
      
  }
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(community['community_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(community['community_description'] ?? 'Stay updated with local alerts.'),
        trailing: _buildStatusButton(context, provider, community, status),
      ),
    );
  }

  Widget _buildStatusButton(BuildContext context, CommunityProvider provider, Map<String, dynamic> community, String status) {

    // Extract community data from JSON passed by Laravel
    final int id = community['community_id'];
    final String? telegramLink = community['telegram_link'];

    if (status == 'approved') {
      return ElevatedButton.icon(
        onPressed: () => _launchTelegram(telegramLink),
        icon: const Icon(Icons.telegram, color: Colors.white),
        label: const Text(
          'Join Channel',
           style: TextStyle(color: Colors.black)
          ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, 
        ),
      );
    } else if (status == 'pending') {
      return const Chip(
        label: Text('Pending'), 
        backgroundColor: Colors.amber,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(20)
          ),
          side: BorderSide.none,
        )
      );
    } else {
      return ElevatedButton(
        onPressed: () async {
          final result = await provider.requestToJoin(id);

          provider.loadCommunities();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        },
        child: const Text('Join'),
      );
    }
  }

    // Helper function to launch telegram
    Future<void> _launchTelegram(String? urlString) async {
      if (urlString == null || urlString.isEmpty) return;

      final Uri url = Uri.parse(urlString);

      // Uses url_launcher package to securely bounce execution to the native Telegram app
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Could not redirect path structure to: $urlString");
      }
  }
  
}