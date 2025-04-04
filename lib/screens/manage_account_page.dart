import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_project/business/screens/business_sign_up_page.dart';
import 'package:fyp_project/screens/account_details_page.dart';
import 'package:fyp_project/screens/loyalty_page.dart';
import 'package:fyp_project/screens/sign_in_page.dart';

class ManageAccountPage extends StatelessWidget {
  const ManageAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Manage account"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),

          // SETTINGS SECTION
          _buildSectionHeader("SETTINGS"),
          _buildListTile(
            context,
            icon: Icons.person,
            title: "Account details",
            subtitle: "Change your account information",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountDetailPage()),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.credit_card,
            title: "Payment",
            subtitle: "Manage payment methods",
            onTap: () {
              // Payment methods
            },
          ),
          _buildListTile(
            context,
            icon: Icons.card_giftcard,
            title: "Vouchers",
            subtitle: "Check available vouchers",
            onTap: () {
              // Vouchers page
            },
          ),
          _buildListTile(
            context,
            icon: Icons.star,
            title: "Special Rewards",
            subtitle: "Your loyalty perks",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoyaltyPage()),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.notifications,
            title: "Notifications",
            subtitle: "Manage notification settings",
            onTap: () {
              // Notifications page
            },
          ),

          const SizedBox(height: 16),

          // COMMUNITY SECTION
          _buildSectionHeader("COMMUNITY"),
          _buildListTile(
            context,
            icon: Icons.group_add,
            title: "Invite your friends",
            subtitle: "Share the app with friends",
            onTap: () {
              // Invite friends
            },
          ),
          _buildListTile(
            context,
            icon: Icons.store,
            title: "Recommend a store",
            subtitle: "Help us find new partners",
            onTap: () {
              // Recommend store
            },
          ),
          _buildListTile(
            context,
            icon: Icons.add_business,
            title: "Sign up your store",
            subtitle: "Join as a partner",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BusinessSignUpPage()),
              );
            },
          ),
          // Sign up store

          const SizedBox(height: 16),

          // SUPPORT SECTION
          _buildSectionHeader("SUPPORT"),
          _buildListTile(
            context,
            icon: Icons.help,
            title: "Help with an order",
            subtitle: "Get support for your orders",
            onTap: () {
              // Help
            },
          ),
          _buildListTile(
            context,
            icon: Icons.info,
            title: "How Grab and Go works",
            subtitle: "Learn about our mission",
            onTap: () {
              // Info about TGTG
            },
          ),

          const SizedBox(height: 16),

          // OTHER SECTION
          _buildSectionHeader("OTHER"),
          _buildListTile(
            context,
            icon: Icons.hide_image,
            title: "Hidden stores",
            subtitle: "Stores you've hidden",
            onTap: () {
              // Hidden stores
            },
          ),
          _buildListTile(
            context,
            icon: Icons.book,
            title: "Terms & Conditions",
            subtitle: "",
            onTap: () {
              // Terms & Conditions
            },
          ),
          _buildListTile(
            context,
            icon: Icons.lock,
            title: "Privacy Policy",
            subtitle: "",
            onTap: () {
              // Privacy Policy
            },
          ),
          _buildListTile(
            context,
            icon: Icons.cookie,
            title: "Cookies & Data",
            subtitle: "",
            onTap: () {
              // Cookies & Data
            },
          ),
          _buildListTile(
            context,
            icon: Icons.receipt_long,
            title: "Licenses",
            subtitle: "",
            onTap: () {
              // Licenses
            },
          ),

          const SizedBox(height: 20),

          // SIGN OUT BUTTON
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              try {
                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();

                // Navigate to login page and remove all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => SignInPage()),
                    (Route<dynamic> route) => false);
              } catch (e) {
                // Optional: Show error if sign out fails
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to sign out: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Sign Out"),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  // Reusable ListTile
  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      subtitle: subtitle != null && subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
