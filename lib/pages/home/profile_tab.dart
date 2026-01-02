import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../backend/providers/auth_provider.dart';
import '../../const/app_colors.dart';
import '../navigation/splash_screen.dart';
import '../components/language_selection_widget.dart';
import 'package:yatra_suraksha_app/l10n/app_localizations.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          l10n?.profile ?? 'Profile',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<CustomAuthProvider>(
        builder: (context, authProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // User Profile Card
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Profile Avatar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.7)
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: authProvider.user?.photoURL != null
                            ? NetworkImage(authProvider.user!.photoURL!)
                            : null,
                        child: authProvider.user?.photoURL == null
                            ? Icon(Icons.person,
                                size: 50, color: AppColors.primary)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User Name
                    Text(
                      authProvider.user?.displayName ?? 'User Name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // User Email
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        authProvider.user?.email ?? 'user@example.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tourist Profile Information
              if (authProvider.userProfile != null) ...[
                _buildSectionHeader(l10n?.touristProfile ?? 'Tourist Profile'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildModernInfoTile(
                        l10n?.touristId ?? 'Tourist ID',
                        authProvider.touristId ??
                            (l10n?.notAvailable ?? 'Not Available'),
                        Icons.badge_outlined,
                        isFirst: true,
                      ),
                      _buildDivider(),
                      _buildModernInfoTile(
                        l10n?.digitalId ?? 'Digital ID',
                        authProvider.digitalId ??
                            (l10n?.notAvailable ?? 'Not Available'),
                        Icons.credit_card_outlined,
                      ),
                      _buildDivider(),
                      _buildModernInfoTile(
                        l10n?.status ?? 'Status',
                        authProvider.touristStatus ??
                            (l10n?.unknown ?? 'Unknown'),
                        Icons.info_outline,
                      ),
                      _buildDivider(),
                      _buildModernInfoTile(
                        l10n?.kycStatus ?? 'KYC Status',
                        authProvider.kycStatus ?? (l10n?.unknown ?? 'Unknown'),
                        Icons.verified_user_outlined,
                      ),
                      _buildDivider(),
                      _buildModernInfoTile(
                        l10n?.safetyScore ?? 'Safety Score',
                        authProvider.safetyScore?.toString() ??
                            (l10n?.notAvailable ?? 'Not Available'),
                        Icons.security_outlined,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Settings Section
              _buildSectionHeader(l10n?.settings ?? 'Settings'),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildModernActionTile(
                      l10n?.language ?? 'Language',
                      l10n?.selectLanguage ?? 'Change app language',
                      Icons.language_outlined,
                      AppColors.primary,
                      () {
                        LanguageBottomSheet.show(context);
                      },
                      isFirst: true,
                    ),
                    _buildDivider(),
                    _buildModernActionTile(
                      l10n?.refreshProfile ?? 'Refresh Profile',
                      l10n?.updateProfileInfo ??
                          'Update your profile information',
                      Icons.refresh_outlined,
                      AppColors.primary,
                      () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n?.refreshingProfile ??
                                'Refreshing profile...'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        await authProvider.refreshUserProfile();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n?.profileRefreshed ??
                                  'Profile refreshed!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildModernActionTile(
                      l10n?.logout ?? 'Logout',
                      l10n?.signOutAccount ?? 'Sign out of your account',
                      Icons.logout_outlined,
                      Colors.red,
                      () => _showLogoutDialog(context, authProvider),
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // App Information
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.appName ?? 'Yatra Suraksha',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.appTagline ?? 'Safe Travel, Secure Journey',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n?.version ?? 'Version'} 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildModernInfoTile(String title, String value, IconData icon,
      {bool isFirst = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionTile(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap,
      {bool isFirst = false, bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
      indent: 16,
      endIndent: 16,
    );
  }

  void _showLogoutDialog(
      BuildContext context, CustomAuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Dialog(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 20),
                            Text("Signing out..."),
                          ],
                        ),
                      ),
                    );
                  },
                );

                // Perform logout
                authProvider.signout();

                // Wait a moment for the logout to process
                await Future.delayed(const Duration(milliseconds: 30));

                // Navigate to splash screen and clear navigation stack
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close loading dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const SplashScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
