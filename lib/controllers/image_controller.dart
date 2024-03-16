import 'dart:io';

import 'package:autozoom_camera/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageController extends GetxController {
  final homeController = Get.put(HomeController());

  RxString imagePath = "".obs;

  @override
  void onInit() {
    super.onInit();
    imagePath.value = homeController.imagePath.value;
  }

  Future<void> saveImageToDevice(File imageFile) async {
    try {
      final Directory directory = Platform.isAndroid
          ? Directory('/storage/emulated/0/DCIM') 
          : await getApplicationDocumentsDirectory(); 

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'image_$timestamp.png';
      final String filePath = '${directory.path}/$fileName';

      await imageFile.copy(filePath);

      Get.showSnackbar(
        GetSnackBar(
          message: 'Image saved successfully to $filePath',
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error saving image: $e');
      Get.showSnackbar(
        const GetSnackBar(
          message: 'Error saving image',
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> saveImage() async {
    bool isPermissionGranted = await Permission.storage.request().isGranted;

    if (isPermissionGranted) {
      File imageFile = File(homeController.imagePath.value);
      await saveImageToDevice(imageFile);
    }
  }
}
