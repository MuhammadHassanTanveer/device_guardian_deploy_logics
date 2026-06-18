
import 'dart:io';

import 'package:deviceguardianadmin/providers/customer_provider.dart';
import 'package:deviceguardianadmin/providers/home_provider.dart';
import 'package:deviceguardianadmin/providers/login_provider.dart';
import 'package:deviceguardianadmin/providers/profile_provider.dart';
import 'package:deviceguardianadmin/util/app_constants.dart';
import 'package:deviceguardianadmin/util/styles.dart';
import 'package:deviceguardianadmin/widgets/app_update_dialog.dart';
import 'package:deviceguardianadmin/widgets/shuffling_counter.dart';
import 'package:deviceguardianadmin/models/key_rate_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/snack_bar_widget.dart';
import '../util/dimensions.dart';
import 'add_customer_screen.dart';
import 'customer_list.dart';
import 'help_support_screen.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'link_devices_screen.dart';
import 'profile_screen.dart';
import 'purchase_history_screen.dart';
import 'update_pin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _versionDialogShown = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPinAndInit();
    });
  }

  Future<void> _checkPinAndInit() async {
    final loginProvider = context.read<LoginProvider>();
    if (!await loginProvider.hasPinConfigured()) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const UpdatePinScreen(isFirstTime: true)),
        (route) => false,
      );
      return;
    }
    await _initHomeData();
  }

  Future<void> _refreshHomeData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    final homeProvider = context.read<HomeProvider>();
    await homeProvider.refreshHomeData();

    if (mounted) {
      _precacheQrImages(homeProvider);
      _checkAndShowUpdateDialog();
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _initHomeData() async {
    await _refreshHomeData();
  }

  void _checkAndShowUpdateDialog() {
    if (!mounted || _versionDialogShown) return;

    final homeProvider = context.read<HomeProvider>();
    if (homeProvider.isVersionOutdated) {
      _versionDialogShown = true;
      _showUpdateDialogIfNeeded();
    }
  }

  void _precacheQrImages(HomeProvider homeProvider) {
    final appVersionData = homeProvider.appVersionData;
    if (appVersionData != null) {
      final firstQrCodePath = appVersionData.firstQrCode;
      final secondQrCodePath = appVersionData.secondQrCode;
      
      if (firstQrCodePath.isNotEmpty) {
        precacheImage(
          NetworkImage('${AppConstants.imageUrl}$firstQrCodePath'),
          context,
        );
      }
      if (secondQrCodePath.isNotEmpty) {
        precacheImage(
          NetworkImage('${AppConstants.imageUrl}$secondQrCodePath'),
          context,
        );
      }
    }
  }

  void _showUpdateDialogIfNeeded() {
    final homeProvider = context.read<HomeProvider>();
    if (homeProvider.isVersionOutdated) {
      showAppUpdateDialog(
        context,
        downloadUrl: homeProvider.downloadUrl,
        currentVersion: homeProvider.installedAppVersion,
        newVersion: homeProvider.latestServerVersion,
      );
    }
  }

  void _showComingSoonDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.campaign, size: 48, color: colorScheme.primary),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text(
                'Coming Soon',
                style: robotoBold(context).copyWith(
                  fontSize: Dimensions.fontSizeExtraLarge(context),
                  color: colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'My Advertisements will be available soon.',
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeDefault(context),
                  color: colorScheme.tertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'جلد دستیاب ہوگا',
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeSmall(context),
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: robotoBold(context).copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: _isRefreshing ? null : _refreshHomeData,
          tooltip: 'Refresh',
          icon: _isRefreshing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.tertiary,
                  ),
                )
              : Icon(Icons.refresh, color: colorScheme.tertiary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.tertiary),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Call logout API and clear data
                final success = await context.read<LoginProvider>().logout();
                
                // Clear other providers' data
                if (context.mounted) {
                  context.read<ProfileProvider>().clearProfileData();
                  context.read<HomeProvider>().clearData();
                  context.read<CustomerProvider>().clearAllData();
                }

                // Close loading indicator
                if (context.mounted) {
                  Navigator.pop(context);
                }

                // Navigate to login screen
                if (context.mounted) {
                  if (success) {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    // Show warning (still logged out locally even if API failed)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out locally (network error)'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(seconds: 1),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface, // Alice blue background (F0F8FF)
              colorScheme.tertiaryContainer, // Lighter sky blue (A8C6FF)
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Container(
                  width: MediaQuery.sizeOf(context).width,
                  padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          "assets/images/logo.png",
                          width: MediaQuery.sizeOf(context).width * 0.6, // Deep blue (102F9C)
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.only(right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall),
                          child: Text(
                            '''قسطوں پر فروخت ہونے والے موبائلز کی مکمل حفاظت''',
                            style: robotoRegular(context).copyWith(
                              fontSize: Dimensions.fontSizeSmall(context),
                              color: colorScheme.tertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Card(
                    elevation: 4,
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    child: Consumer<HomeProvider>(
                      builder: (context, homeProvider, child) {
                        return Column(
                          children: <Widget>[
                            // Header with name and balance
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(Dimensions.radiusDefault),
                                  topRight: Radius.circular(Dimensions.radiusDefault),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    homeProvider.userName,
                                    style: GoogleFonts.acme(
                                      fontSize: Dimensions.fontSizeOverLarge(context),
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.tertiary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: Dimensions.paddingSizeSmall),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeLarge,
                                      vertical: Dimensions.paddingSizeSmall,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Android: ",
                                          style: robotoRegular(context).copyWith(
                                            color: Colors.white,
                                            fontSize: Dimensions.fontSizeDefault(context),
                                          ),
                                        ),
                                        ShufflingText(
                                          targetValue: homeProvider.crediteAndroid,
                                          isLoading: homeProvider.isLoading,
                                          textStyle: robotoBold(context).copyWith(
                                            color: Colors.white,
                                            fontSize: Dimensions.fontSizeSmall(context),
                                          ),
                                        ),
                                        const SizedBox(width: Dimensions.paddingSizeLarge),
                                        Text(
                                          "iPhone: ",
                                          style: robotoRegular(context).copyWith(
                                            color: Colors.white,
                                            fontSize: Dimensions.fontSizeDefault(context),
                                          ),
                                        ),
                                        ShufflingText(
                                          targetValue: homeProvider.crediteiPhone,
                                          isLoading: homeProvider.isLoading,
                                          textStyle: robotoBold(context).copyWith(
                                            color: Colors.white,
                                            fontSize: Dimensions.fontSizeSmall(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Stats row
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeExtraSmall,
                                vertical: Dimensions.paddingSizeDefault,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  _buildStatCardWithShuffle(context, homeProvider.locked.toString(), "Locked", Icons.lock, Colors.red, homeProvider.isLoading),
                                  _buildStatCardWithShuffle(context, homeProvider.total.toString(), "Total", Icons.devices, colorScheme.primary, homeProvider.isLoading),
                                  _buildStatCardWithShuffle(context, homeProvider.unlocked.toString(), "Unlocked", Icons.lock_open, Colors.green, homeProvider.isLoading),
                                  _buildStatCardWithShuffle(context, homeProvider.inactive.toString(), "Inactive", Icons.power_off, Colors.orange, homeProvider.isLoading),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                // New Application & Old Application Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  child: Card(
                    elevation: 2,
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: Dimensions.paddingSizeDefault),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: InkWell(
                              onTap: () => _showGetApplicationDialog(context, isNew: true),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Flexible(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "New Device Scan",
                                          style: robotoBold(context).copyWith(
                                            fontSize: Dimensions.fontSizeDefault(context),
                                            color: colorScheme.tertiary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "نئی ڈیوائس اسکین",
                                          style: robotoRegular(context).copyWith(
                                            fontSize: Dimensions.fontSizeSmall(context),
                                            color: colorScheme.tertiary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeSmall),
                                  Icon(Icons.qr_code, size: 36, color: colorScheme.primary),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 50,
                            width: 1,
                            color: theme.dividerColor,
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => _showGetApplicationDialog(context, isNew: false),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Flexible(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Old Device Scan",
                                          style: robotoBold(context).copyWith(
                                            fontSize: Dimensions.fontSizeDefault(context),
                                            color: colorScheme.tertiary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "پرانی ڈیوائس اسکین",
                                          style: robotoRegular(context).copyWith(
                                            fontSize: Dimensions.fontSizeSmall(context),
                                            color: colorScheme.tertiary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeSmall),
                                  Icon(Icons.qr_code, size: 36, color: colorScheme.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Padding(
                  padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: GridView.custom(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: Dimensions.paddingSizeExtraSmall,
                      mainAxisSpacing: Dimensions.paddingSizeExtraSmall,
                      childAspectRatio: 1.8,
                    ),
                    childrenDelegate: SliverChildListDelegate([
                      _buildGridCard(context, Icons.person_add_alt, "Add Customer", "کسٹمر شامل کریں", ()=> Navigator.of(context).push(MaterialPageRoute(builder: (context)=> AddCustomerScreen(),),),),
                      _buildGridCard(context, Icons.list_alt_outlined, "Customer List", "کسٹمر لسٹ", ()=> Navigator.of(context).push(MaterialPageRoute(builder: (context)=> CustomersListScreen(),),),),
                      _buildGridCard(context, Icons.shopping_cart, "Purchase Request", "خریداری کی درخواست", () {
                        _showPurchaseRequestDialog(context);
                      }),
                      _buildGridCard(context, Icons.history, "Purchase History", "خریداری کی ہسٹری", () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const PurchaseHistoryScreen()),
                        );
                      }),
                      _buildGridCard(context, Icons.video_library, "Installation Videos", "انسٹالیشن ویڈیوز", () {
                        _showInstallationVideosDialog(context);
                      }),
                      _buildGridCard(context, Icons.person, "My Profile", "میری پروفائل", () {
                        _showProfileDialog(context);
                      }),
                      _buildGridCard(context, Icons.support_agent, "Support", "سپورٹ", () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                        );
                      }),
                    ]),
                  ),
                ),
                // My Advertisements Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  child: InkWell(
                    onTap: () => _showComingSoonDialog(context),
                    child: Card(
                      elevation: 2,
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.campaign, size: 25, color: colorScheme.primary),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "My Advertisements",
                                  style: robotoBold(context).copyWith(
                                    fontSize: Dimensions.fontSizeLarge(context),
                                    color: colorScheme.tertiary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "میرے اشتہارات",
                                  style: robotoRegular(context).copyWith(
                                    fontSize: Dimensions.fontSizeSmall(context),
                                    color: colorScheme.tertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Divider(
                    color: theme.primaryColor,
                    thickness: 3,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Text("Version: ${AppConstants.appVersion}", style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor), ),
                const SizedBox(height: 5),
                Text("Powered by Deploy Logics", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, fontStyle: FontStyle.italic), ),
                Text("deploylogics.com", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, fontStyle: FontStyle.italic), ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                // ElevatedButton(onPressed: ()async {
                //   try {
                //     final keyService = GetServerKey(); // create instance
                //     String token = await keyService.serverToken(); // call method
                //     log("Server key: $token");
                //   } catch (e, st) {
                //     log("Error generating server key: $e");
                //     log(st.toString());
                //   }
                // }, child: Text("Generate server key"))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String title, IconData icon, Color iconColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: 75,
      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            value,
            style: robotoBold(context).copyWith(
              fontSize: Dimensions.fontSizeExtraLarge(context),
              color: colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: robotoRegular(context).copyWith(
              fontSize: Dimensions.fontSizeExtraSmall(context),
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardWithShuffle(BuildContext context, String value, String title, IconData icon, Color iconColor, bool isLoading) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: 75,
      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          ShufflingCounter(
            targetValue: value,
            isLoading: isLoading,
            textStyle: robotoBold(context).copyWith(
              fontSize: Dimensions.fontSizeDefault(context),
              color: colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: robotoRegular(context).copyWith(
              fontSize: Dimensions.fontSizeExtraSmall(context),
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, IconData icon, String title, String urduTitle, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 25, color: theme.colorScheme.primary),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: robotoBold(context).copyWith(
                        fontSize: Dimensions.fontSizeDefault(context),
                        color: theme.colorScheme.tertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      urduTitle,
                      style: robotoRegular(context).copyWith(
                        fontSize: Dimensions.fontSizeSmall(context),
                        color: theme.colorScheme.tertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGetApplicationDialog(BuildContext context, {required bool isNew}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final homeProvider = context.read<HomeProvider>();
    final appVersionData = homeProvider.appVersionData;
    final title = isNew ? "New Device Scan" : "Running Device Scan";
    
    // Get image URLs from API and prepend base URL
    final firstQrCodePath = appVersionData?.firstQrCode ?? '';
    final secondQrCodePath = appVersionData?.secondQrCode ?? '';
    final firstQrCodeUrl = firstQrCodePath.isNotEmpty ? '${AppConstants.imageUrl}$firstQrCodePath' : '';
    final secondQrCodeUrl = secondQrCodePath.isNotEmpty ? '${AppConstants.imageUrl}$secondQrCodePath' : '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      title,
                      style: robotoBold(context).copyWith(
                        fontSize: Dimensions.fontSizeExtraLarge(context),
                        color: colorScheme.tertiary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.hintColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                if (isNew) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Step 1",
                        style: robotoBold(context).copyWith(
                          fontSize: Dimensions.fontSizeLarge(context),
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        "پہلا کیو آر کوڈ",
                        style: robotoRegular(context).copyWith(
                          fontSize: Dimensions.fontSizeDefault(context),
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: firstQrCodeUrl.isNotEmpty
                        ? Image.network(
                            firstQrCodeUrl,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 48, color: theme.hintColor),
                                    const SizedBox(height: 8),
                                    Text("Failed to load image", style: TextStyle(color: theme.hintColor)),
                                  ],
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 200,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 48, color: theme.hintColor),
                                const SizedBox(height: 8),
                                Text("No image available", style: TextStyle(color: theme.hintColor)),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Step 2",
                        style: robotoBold(context).copyWith(
                          fontSize: Dimensions.fontSizeLarge(context),
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        "دوسرا کیو آر کوڈ",
                        style: robotoRegular(context).copyWith(
                          fontSize: Dimensions.fontSizeDefault(context),
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: secondQrCodeUrl.isNotEmpty
                        ? Image.network(
                            secondQrCodeUrl,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 48, color: theme.hintColor),
                                    const SizedBox(height: 8),
                                    Text("Failed to load image", style: TextStyle(color: theme.hintColor)),
                                  ],
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 200,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 48, color: theme.hintColor),
                                const SizedBox(height: 8),
                                Text("No image available", style: TextStyle(color: theme.hintColor)),
                              ],
                            ),
                          ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Scan QR Code",
                        style: robotoBold(context).copyWith(
                          fontSize: Dimensions.fontSizeLarge(context),
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        "اسکین کیو آر کوڈ",
                        style: robotoRegular(context).copyWith(
                          fontSize: Dimensions.fontSizeDefault(context),
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: secondQrCodeUrl.isNotEmpty
                        ? Image.network(
                            secondQrCodeUrl,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 48, color: theme.hintColor),
                                    const SizedBox(height: 8),
                                    Text("Failed to load image", style: TextStyle(color: theme.hintColor)),
                                  ],
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 200,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 48, color: theme.hintColor),
                                const SizedBox(height: 8),
                                Text("No image available", style: TextStyle(color: theme.hintColor)),
                              ],
                            ),
                          ),
                  ),
                ],
                const SizedBox(height: Dimensions.paddingSizeDefault),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInstallationVideosDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final homeProvider = context.read<HomeProvider>();
    final appVersionData = homeProvider.appVersionData;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Training Videos",
                    style: robotoBold(context).copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge(context),
                      color: colorScheme.tertiary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.hintColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              // Android Installation Video
              _buildVideoTile(
                context,
                icon: Icons.android,
                iconColor: Colors.green,
                title: "Android Installation",
                urduTitle: "اینڈرائیڈ انسٹالیشن",
                onTap: () => _openVideoUrl(appVersionData?.videoUrl ?? ''),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              // User Running Android Phone Installation Video
              _buildVideoTile(
                context,
                icon: Icons.phone_android,
                iconColor: colorScheme.primary,
                title: "Running Phone Installation",
                urduTitle: "چلتے فون میں انسٹالیشن",
                onTap: () => _openVideoUrl(appVersionData?.userRunningPhoneInstallationVideoUrl ?? ''),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              // Retailer App Installation Video
              _buildVideoTile(
                context,
                icon: Icons.store,
                iconColor: Colors.orange,
                title: "Retailer App Tutorial",
                urduTitle: "ریٹیلر ایپ ٹیوٹوریل",
                onTap: () => _openVideoUrl(appVersionData?.retailerVideoUrl ?? ''),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              // iPhone Installation Video
              _buildVideoTile(
                context,
                icon: Icons.phone_iphone,
                iconColor: Colors.grey.shade700,
                title: "iPhone Installation",
                urduTitle: "آئی فون انسٹالیشن",
                onTap: () => _openVideoUrl(appVersionData?.iphoneVideoUrl ?? ''),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String urduTitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: robotoBold(context).copyWith(
                      fontSize: Dimensions.fontSizeDefault(context),
                      color: colorScheme.tertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    urduTitle,
                    style: robotoRegular(context).copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall(context),
                      color: theme.hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_outline, size: 24, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _openVideoUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showProfileDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "My Profile",
                    style: robotoBold(context).copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge(context),
                      color: colorScheme.tertiary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.hintColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              // Profile Tile
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 28, color: colorScheme.primary),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Profile",
                              style: robotoBold(context).copyWith(
                                fontSize: Dimensions.fontSizeLarge(context),
                                color: colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "پروفائل",
                              style: robotoRegular(context).copyWith(
                                fontSize: Dimensions.fontSizeSmall(context),
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 18, color: theme.hintColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              // Change Password Tile
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.password_rounded, size: 28, color: colorScheme.primary),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Change Password",
                              style: robotoBold(context).copyWith(
                                fontSize: Dimensions.fontSizeLarge(context),
                                color: colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "پاس ورڈ تبدیل کریں",
                              style: robotoRegular(context).copyWith(
                                fontSize: Dimensions.fontSizeSmall(context),
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 18, color: theme.hintColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              // Link Devices Tile
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LinkDevicesScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.devices, size: 28, color: colorScheme.primary),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Link Devices",
                              style: robotoBold(context).copyWith(
                                fontSize: Dimensions.fontSizeLarge(context),
                                color: colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "آلات منسلک کریں",
                              style: robotoRegular(context).copyWith(
                                fontSize: Dimensions.fontSizeSmall(context),
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 18, color: theme.hintColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              // Update Pin Tile
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const UpdatePinScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, size: 28, color: colorScheme.primary),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Update Pin",
                              style: robotoBold(context).copyWith(
                                fontSize: Dimensions.fontSizeLarge(context),
                                color: colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "پن اپڈیٹ کریں",
                              style: robotoRegular(context).copyWith(
                                fontSize: Dimensions.fontSizeSmall(context),
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 18, color: theme.hintColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ],
          ),
        ),
      ),
    );
  }

  static const List<String> _creditKeyTypeOptions = ['Android', 'iOS'];

  void _showPurchaseRequestDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final quantityController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedKeyType = _creditKeyTypeOptions.first;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Padding(
              padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "Purchase Request",
                          style: robotoBold(context).copyWith(
                            fontSize: Dimensions.fontSizeExtraLarge(context),
                            color: colorScheme.tertiary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: theme.hintColor),
                          onPressed: isLoading ? null : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text(
                      "خریداری کی درخواست",
                      style: robotoRegular(context).copyWith(
                        fontSize: Dimensions.fontSizeDefault(context),
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    Text(
                      "Credit Key Type",
                      style: robotoRegular(context).copyWith(
                        fontSize: Dimensions.fontSizeDefault(context),
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    DropdownButtonFormField<String>(
                      value: selectedKeyType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        prefixIcon: Icon(Icons.vpn_key, color: colorScheme.primary),
                      ),
                      items: _creditKeyTypeOptions.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  selectedKeyType = value;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    TextFormField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: "Quantity",
                        hintText: "Enter quantity",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        prefixIcon: Icon(Icons.numbers, color: colorScheme.primary),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter quantity';
                        }
                        final qty = int.tryParse(value);
                        if (qty == null || qty <= 0) {
                          return 'Please enter a valid quantity';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  final quantity = int.parse(quantityController.text);
                                  final homeProvider = context.read<HomeProvider>();
                                  final keyRateModel = await homeProvider.getKeyRate(
                                    quantity,
                                    keyType: selectedKeyType,
                                  );

                                  setState(() {
                                    isLoading = false;
                                  });

                                  if (keyRateModel != null) {
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      _showPurchaseConfirmationDialog(context, keyRateModel);
                                    }
                                  } else {
                                    if (context.mounted) {
                                      showCustomSnackBar(context, 'Failed to get key rate. Please try again.', isError: true);
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                "Submit",
                                style: robotoBold(context).copyWith(
                                  fontSize: Dimensions.fontSizeLarge(context),
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPurchaseConfirmationDialog(BuildContext context, KeyRateModel keyRateModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final homeProvider = context.read<HomeProvider>();
    final appVersionData = homeProvider.appVersionData;
    final transactionIdController = TextEditingController();
    File? selectedImage;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            "Purchase Summary",
                            style: robotoBold(context).copyWith(
                              fontSize: Dimensions.fontSizeExtraLarge(context),
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: theme.hintColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text(
                      "خریداری کا خلاصہ",
                      style: robotoRegular(context).copyWith(
                        fontSize: Dimensions.fontSizeDefault(context),
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    // Purchase Details Container
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shopping_cart, size: 18, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                "Purchase Details",
                                style: robotoBold(context).copyWith(
                                  fontSize: Dimensions.fontSizeDefault(context),
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          _buildCompactSummaryRow(context, "Credit Key Type", keyRateModel.keyType),
                          _buildCompactSummaryRow(context, "Quantity", keyRateModel.quantity.toString()),
                          _buildCompactSummaryRow(context, "Price Per Key", "Rs. ${keyRateModel.pricePerKey.toStringAsFixed(0)}"),
                          _buildCompactSummaryRow(context, "Total Amount", "Rs. ${keyRateModel.totalAmount.toStringAsFixed(0)}", isHighlighted: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    // Bank Account Details
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance, size: 18, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                "Bank Account Details",
                                style: robotoBold(context).copyWith(
                                  fontSize: Dimensions.fontSizeDefault(context),
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          _buildCompactBankRow(context, "Bank", appVersionData?.bankName ?? 'N/A'),
                          _buildCompactBankRow(context, "Account Title", appVersionData?.accountTitle ?? 'N/A'),
                          _buildCompactBankRow(context, "Account No", appVersionData?.accountNo ?? 'N/A'),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    // Instruction Text
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Please transfer the amount to the above bank account. After payment, upload the screenshot and enter transaction ID to proceed.",
                                  style: robotoRegular(context).copyWith(
                                    fontSize: Dimensions.fontSizeSmall(context),
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: EdgeInsets.only(left: 26),
                            child: Text(
                              "براہ کرم رقم اوپر دیے گئے بینک اکاؤنٹ میں منتقل کریں۔ ادائیگی کے بعد، اسکرین شاٹ اپ لوڈ کریں اور آگے بڑھنے کے لیے ٹرانزیکشن آئی ڈی درج کریں۔",
                              style: robotoRegular(context).copyWith(
                                fontSize: Dimensions.fontSizeSmall(context),
                                color: Colors.orange.shade700,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    // Transaction ID Input
                    TextFormField(
                      controller: transactionIdController,
                      decoration: InputDecoration(
                        labelText: "Transaction ID",
                        hintText: "Enter transaction ID",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        prefixIcon: Icon(Icons.receipt_long, color: colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    // Upload Receipt Image
                    Text(
                      "Upload Receipt",
                      style: robotoRegular(context).copyWith(
                        fontSize: Dimensions.fontSizeDefault(context),
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "رسید اپ لوڈ کریں",
                      style: robotoRegular(context).copyWith(
                        fontSize: Dimensions.fontSizeSmall(context),
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    InkWell(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (image != null) {
                          setState(() {
                            selectedImage = File(image.path);
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: selectedImage != null ? 200 : 100,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: selectedImage != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                    child: Image.file(
                                      selectedImage!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedImage = null;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 40,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Tap to upload receipt image",
                                    style: robotoRegular(context).copyWith(
                                      fontSize: Dimensions.fontSizeSmall(context),
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                // Validate transaction ID
                                if (transactionIdController.text.trim().isEmpty) {
                                  showCustomSnackBar(context, 'Please enter transaction ID', isError: true);
                                  return;
                                }

                                setState(() {
                                  isSubmitting = true;
                                });

                                final homeProvider = context.read<HomeProvider>();
                                final result = await homeProvider.submitPurchaseRequest(
                                  qty: keyRateModel.quantity,
                                  keyType: keyRateModel.keyType,
                                  transactionId: transactionIdController.text.trim(),
                                  paymentProof: selectedImage,
                                );

                                setState(() {
                                  isSubmitting = false;
                                });

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  showCustomSnackBar(context, result['message'], isError: !result['success']);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          ),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                "Confirm",
                                style: robotoBold(context).copyWith(
                                  fontSize: Dimensions.fontSizeLarge(context),
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactBankRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: robotoRegular(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: theme.hintColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: robotoBold(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: colorScheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryRow(BuildContext context, String label, String value, {bool isHighlighted = false}) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: robotoRegular(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: theme.hintColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: robotoBold(context).copyWith(
                fontSize: Dimensions.fontSizeSmall(context),
                color: isHighlighted ? Colors.blue.shade700 : theme.colorScheme.tertiary,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String urduLabel,
    String value, {
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeDefault(context),
                  color: colorScheme.tertiary,
                ),
              ),
              Text(
                urduLabel,
                style: robotoRegular(context).copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall(context),
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: isHighlighted
                ? robotoBold(context).copyWith(
                    fontSize: Dimensions.fontSizeLarge(context),
                    color: colorScheme.primary,
                  )
                : robotoBold(context).copyWith(
                    fontSize: Dimensions.fontSizeDefault(context),
                    color: colorScheme.tertiary,
                  ),
          ),
        ],
      ),
    );
  }
}