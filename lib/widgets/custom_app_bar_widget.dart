import 'package:flutter/material.dart';
import '../util/dimensions.dart';
import '../util/styles.dart';

class CustomAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isBackButtonExist;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const CustomAppBarWidget({
    super.key,
    required this.title,
    this.isBackButtonExist = true,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: robotoBold(context).copyWith(
          fontSize: Dimensions.fontSizeLarge(context),
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      centerTitle: true,
      leading: isBackButtonExist
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : const SizedBox(),
      backgroundColor: Theme.of(context).cardColor,
      elevation: 2,
      shadowColor: Colors.grey.withValues(alpha: 0.3),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

