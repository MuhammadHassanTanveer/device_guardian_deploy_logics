import 'package:deviceguardianadmin/providers/profile_provider.dart';
import 'package:deviceguardianadmin/screens/edit_profile_screen.dart';
import 'package:deviceguardianadmin/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../util/dimensions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfileData();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading) {
            return _buildLoadingShimmer();
          }
          if (profileProvider.errorMessage != null) {
            return _buildErrorWidget(profileProvider);
          }
          return _buildProfileContent(profileProvider);
        },
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.tertiaryContainer,
          ],
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      ),
    );
  }

  Widget _buildErrorWidget(ProfileProvider profileProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.tertiaryContainer,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 64,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                Text(
                  'Oops! Something went wrong',
                  style: robotoBold(context).copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge(context),
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  profileProvider.errorMessage!,
                  style: robotoRegular(context).copyWith(
                    fontSize: Dimensions.fontSizeDefault(context),
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                ElevatedButton.icon(
                  onPressed: () => profileProvider.fetchProfileData(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(ProfileProvider profileProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Custom App Bar with Profile Header
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          stretch: true,
          backgroundColor: colorScheme.surface,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: colorScheme.primary, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit_rounded, color: colorScheme.primary, size: 20),
                ),
                onPressed: () => _navigateToEditProfile(profileProvider),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface,
                    colorScheme.tertiaryContainer,
                  ],
                ),
              ),
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Profile Avatar with border
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.primary, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                            child: Text(
                              _getInitials(profileProvider.name),
                              style: robotoBold(context).copyWith(
                                fontSize: 32,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Company Name
                        Text(
                          profileProvider.companyName,
                          style: robotoBold(context).copyWith(
                            fontSize: Dimensions.fontSizeOverLarge(context),
                            color: colorScheme.tertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Company Name Urdu
                        if (profileProvider.companyNameUrdu.isNotEmpty)
                          Text(
                            profileProvider.companyNameUrdu,
                            style: robotoMedium(context).copyWith(
                              fontSize: Dimensions.fontSizeLarge(context),
                              color: colorScheme.tertiary.withValues(alpha: 0.8),
                            ),
                          ),
                        const SizedBox(height: 8),
                        // User Name Badge
                        if (profileProvider.name.isNotEmpty && profileProvider.name != 'N/A')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_rounded, color: colorScheme.primary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  profileProvider.name,
                                  style: robotoRegular(context).copyWith(
                                    fontSize: Dimensions.fontSizeSmall(context),
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Profile Content
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Quick Stats Row
                      _buildQuickStatsRow(profileProvider),
                      const SizedBox(height: 24),

                      // Company Information
                      _buildModernInfoCard(
                        title: 'Company Information',
                        urduTitle: 'کمپنی کی معلومات',
                        icon: Icons.business_rounded,
                        iconColor: Colors.purple,
                        items: [
                          _InfoItem(Icons.store_rounded, 'Company Name', profileProvider.companyName, 'کمپنی کا نام'),
                          if (profileProvider.companyNameUrdu.isNotEmpty)
                            _InfoItem(Icons.translate_rounded, 'Company Name (Urdu)', profileProvider.companyNameUrdu, 'کمپنی کا نام اردو میں'),
                          if (profileProvider.gstNo.isNotEmpty)
                            _InfoItem(Icons.receipt_long_rounded, 'GST Number', profileProvider.gstNo, 'جی ایس ٹی نمبر'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Contact Information
                      _buildModernInfoCard(
                        title: 'Contact Information',
                        urduTitle: 'رابطے کی معلومات',
                        icon: Icons.contact_phone_rounded,
                        iconColor: Colors.blue,
                        items: [
                          _InfoItem(Icons.email_rounded, 'Email', profileProvider.email, 'ای میل'),
                          _InfoItem(Icons.phone_rounded, 'Phone', profileProvider.phone, 'فون'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Location Information
                      _buildModernInfoCard(
                        title: 'Location',
                        urduTitle: 'مقام',
                        icon: Icons.location_on_rounded,
                        iconColor: Colors.orange,
                        items: [
                          _InfoItem(Icons.home_rounded, 'Address', profileProvider.address, 'پتہ'),
                          _InfoItem(Icons.location_city_rounded, 'City', profileProvider.cityName, 'شہر'),
                          _InfoItem(Icons.map_rounded, 'State', profileProvider.stateName, 'صوبہ'),
                          _InfoItem(Icons.flag_rounded, 'Country', profileProvider.countryName, 'ملک'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Account Info
                      if (profileProvider.createdAt.isNotEmpty)
                        _buildModernInfoCard(
                          title: 'Account',
                          urduTitle: 'اکاؤنٹ',
                          icon: Icons.verified_user_rounded,
                          iconColor: Colors.green,
                          items: [
                            _InfoItem(
                              Icons.calendar_today_rounded,
                              'Member Since',
                              profileProvider.formatDate(profileProvider.createdAt),
                              'ممبر شپ',
                            ),
                          ],
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsRow(ProfileProvider profileProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.5),
            colorScheme.tertiaryContainer.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.location_city_rounded,
            label: 'City',
            value: profileProvider.cityName != 'N/A' ? profileProvider.cityName : '--',
            color: Colors.blue,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            icon: Icons.flag_rounded,
            label: 'Country',
            value: profileProvider.countryName != 'N/A' ? profileProvider.countryName : '--',
            color: Colors.orange,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            icon: Icons.verified_rounded,
            label: 'Status',
            value: 'Active',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: robotoBold(context).copyWith(
            fontSize: Dimensions.fontSizeDefault(context),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: robotoRegular(context).copyWith(
            fontSize: Dimensions.fontSizeSmall(context),
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 50,
      width: 1,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
    );
  }

  Widget _buildModernInfoCard({
    required String title,
    required String urduTitle,
    required IconData icon,
    required Color iconColor,
    required List<_InfoItem> items,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: robotoBold(context).copyWith(
                          fontSize: Dimensions.fontSizeLarge(context),
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        urduTitle,
                        style: robotoRegular(context).copyWith(
                          fontSize: Dimensions.fontSizeSmall(context),
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    _buildInfoRow(item),
                    if (index < items.length - 1)
                      Divider(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        height: 24,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item.icon,
            size: 18,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.label,
                    style: robotoRegular(context).copyWith(
                      fontSize: Dimensions.fontSizeSmall(context),
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${item.urduLabel})',
                    style: robotoRegular(context).copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall(context),
                      color: theme.hintColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: robotoMedium(context).copyWith(
                  fontSize: Dimensions.fontSizeDefault(context),
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToEditProfile(ProfileProvider profileProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    ).then((_) {
      // Refresh profile data when returning from edit screen
      profileProvider.fetchProfileData();
    });
  }

  String _getInitials(String name) {
    // Return first letter of company name
    if (name.isEmpty || name == 'N/A') return '?';
    return name.trim()[0].toUpperCase();
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final String urduLabel;

  _InfoItem(this.icon, this.label, this.value, this.urduLabel);
}
