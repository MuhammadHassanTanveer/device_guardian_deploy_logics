import '../../util/styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../util/dimensions.dart';

class FilePickerDialogWidget extends StatelessWidget {
  final Function() onCamPress;
  final Function() onGalleryPress;
  final bool? isFile;
  final Function()? onFilePress;

  const FilePickerDialogWidget({
    super.key,
    required this.onCamPress,
    required this.onGalleryPress,
    this.isFile = false,
    this.onFilePress,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // backgroundColor: Theme.of(context).colorScheme.primary,
      child: Container(
        margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        width: 500,
        // height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Choose an action',
                style: robotoBold(context),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraOverLarge,),
              Wrap(

                // mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  InkWell(
                    onTap: onCamPress,
                    highlightColor: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.2),
                    child: SizedBox(
                      width: 100,
                      height: 120,
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.5),
                            ),
                            child: const Icon(CupertinoIcons.photo_camera_solid, size: 30,),
                          ),
                          const SizedBox(
                            height: Dimensions.paddingSizeExtraSmall,
                          ),
                          Text("Camera", style: robotoMedium(context)),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onGalleryPress,
                    highlightColor: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.2),
                    child: SizedBox(
                      width: 100,
                      height: 120,
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.5),
                            ),
                            child: const Icon(CupertinoIcons.photo_fill_on_rectangle_fill, size: 30,),
                          ),
                          const SizedBox(
                            height: Dimensions.paddingSizeExtraSmall,
                          ),
                          Text("Gallery", style: robotoMedium(context),),
                        ],
                      ),
                    ),
                  ),
                  if(isFile == true)
                  InkWell(
                    onTap: onFilePress,
                    highlightColor: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.2),
                    child: SizedBox(
                      width: 100,
                      height: 120,
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.5),
                            ),
                            child: const Icon(CupertinoIcons.arrow_up_doc_fill, size: 30,),
                          ),
                          const SizedBox(
                            height: Dimensions.paddingSizeExtraSmall,
                          ),
                          Text("File", style: robotoMedium(context),),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
