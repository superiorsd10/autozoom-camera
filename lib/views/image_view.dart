import 'dart:io';

import 'package:autozoom_camera/controllers/image_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImageView extends GetView<ImageController> {
  const ImageView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Autozoom Camera'),
          centerTitle: true,
        ),
        body: Image.file(
          File(controller.imagePath.value),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => controller.saveImage(),
          child: const Icon(Icons.save),
        ),
      ),
    );
  }
}
