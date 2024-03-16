import 'dart:async';

import 'package:autozoom_camera/controllers/image_controller.dart';
import 'package:autozoom_camera/models/recognition.dart';
import 'package:autozoom_camera/models/screen_params.dart';
import 'package:autozoom_camera/service/detector_service.dart';
import 'package:autozoom_camera/views/image_view.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  late List<CameraDescription> cameras;

  late CameraController cameraController;
  late CameraImage cameraImage;

  Detector? _detector;
  StreamSubscription? _subscription;

  List<Recognition>? results;
  Recognition? singleTappedObject;

  var isZoomed = false.obs;
  var imagePath = "".obs;
  var isCameraInitialized = false.obs;
  var frameCount = 0.obs;

  @override
  void onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    await _initStateAsync();
    await initCamera();
  }

  Future<void> initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
      );

      await cameraController.initialize().then((value) async {
        await cameraController
            .startImageStream((image) => onLatestImageAvailable(image));
        ScreenParams.previewSize = cameraController.value.previewSize!;
        update();
      });
      isCameraInitialized.value = true;
      update();
    } else {
      print('Permission denied');
    }
  }

  Future<void> _initStateAsync() async {
    Detector.start().then((instance) {
      _detector = instance;
      _subscription = instance.resultsStream.stream.listen((values) {
        results = values['recognitions'];
        update();
      });
    });
  }

  Future<void> onSingleTapped(Recognition result) async {
    // Calculate the zoom level based on the size of the selected object
    double objectWidth = result.location.width;
    double objectHeight = result.location.height;
    double maxObjectSize = 240.0; // Maximum size of the object to zoom in
    double zoomLevel =
        1.0 + ((objectWidth + objectHeight) / (2 * maxObjectSize));

    // Set the zoom level and update the state
    isZoomed.value = true;
    await cameraController.setZoomLevel(zoomLevel);
    singleTappedObject = result;
    update();
  }

  Future<void> resetZoom() async {
    isZoomed.value = false;
    await cameraController.setZoomLevel(1.0);
  }

  Future<void> onLatestImageAvailable(CameraImage cameraImage) async {
    frameCount.value++;

    if (frameCount.value % 10 == 0) {
      frameCount.value = 0;

      // Process the frame to detect objects
      _detector!.processFrame(cameraImage);

      // If there are detected objects and the camera is not already zoomed in
      if (results != null && results!.isNotEmpty && !isZoomed.value) {
        // Calculate the center coordinates and size of the first detected object
        Recognition? firstObject;
        if (results!.length > 1) {
          firstObject = singleTappedObject;
        } else {
          firstObject = results!.first;
        }
        double objectWidth = firstObject!.location.width;
        double objectHeight = firstObject.location.height;

        // Calculate the zoom level based on the size of the detected object
        double maxObjectSize = 240.0; // Maximum size of the object to zoom in
        double zoomLevel =
            1.0 + ((objectWidth + objectHeight) / (2 * maxObjectSize));

        // Set the zoom level and update the state
        isZoomed.value = true;
        await cameraController.setZoomLevel(zoomLevel);
        singleTappedObject = firstObject;
        update();
      }
    }
  }

  Future<void> captureImage() async {
    try {
      final image = await cameraController.takePicture();
      await cameraController.setZoomLevel(1.0);
      isZoomed.value = false;
      imagePath.value = image.path;
      Get.put<ImageController>(ImageController());
      Get.to(const ImageView());
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        cameraController.stopImageStream();
        _detector?.stop();
        _subscription?.cancel();
        break;
      case AppLifecycleState.resumed:
        _initStateAsync();
        break;
      default:
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    _detector?.stop();
    _subscription?.cancel();
    super.onClose();
  }
}
