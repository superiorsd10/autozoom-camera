import 'package:autozoom_camera/controllers/home_controller.dart';
import 'package:autozoom_camera/ui/box_widget.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Autozoom Camera'),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              controller.cameraController.setZoomLevel(1.0);
              controller.isZoomed.value = false;
            },
            icon: const Icon(Icons.zoom_out),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Get.defaultDialog(
                  title: 'Instructions',
                  content: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Tap on multiple objects to zoom in on them.'),
                        Text(
                            '2. For a single object, automatic zoom is provided.'),
                        Text(
                            '3. Tap the reset zoom button to reset the zoom level.'),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.integration_instructions),
            ),
          ],
        ),
        body: GetBuilder<HomeController>(
          init: HomeController(),
          builder: (controller) {
            return controller.isCameraInitialized.value
                ? Stack(
                    children: [
                      GestureDetector(
                        onDoubleTap: () async {
                          controller.isZoomed.value = false;
                          await controller.cameraController.setZoomLevel(1.0);
                        },
                        child: CameraPreview(controller.cameraController),
                      ),
                      boundingBoxes(),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => controller.captureImage(),
          child: const Icon(Icons.camera),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget boundingBoxes() {
    if (controller.results == null || controller.isZoomed.value) {
      print('SIZEDBOX SHRINK');
      return const SizedBox.shrink();
    }
    return Stack(
      children: controller.results!
          .map(
            (box) => BoxWidget(
              result: box,
              onSingleTap: controller.onSingleTapped,
            ),
          )
          .toList(),
    );
  }
}
