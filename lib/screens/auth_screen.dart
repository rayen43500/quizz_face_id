import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/face_auth_service.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isFrontCameraSelected = true;
  String _message = '';
  bool _isSuccess = false;
  bool _isCameraPermissionGranted = false;
  
  final FaceAuthService _faceAuthService = FaceAuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _checkAuthStatus();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize the camera
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuthenticated = prefs.getBool('is_authenticated') ?? false;
    
    if (isAuthenticated && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _cameraController!.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _isCameraInitialized = true;
        _isCameraPermissionGranted = true;
      });
    } catch (e) {
      setState(() {
        _isCameraPermissionGranted = false;
        _message = 'Camera error: $e';
      });
      print('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _faceAuthService.dispose();
    super.dispose();
  }

  Future<void> _processImage() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _message = 'Processing...';
      _isSuccess = false;
    });
    
    try {
      // Dans cette version simplifiée, nous n'avons pas besoin de capturer l'image
      // Nous simulons simplement le processus d'authentification
      
      bool result;
      if (_faceAuthService.isAuthSetup) {
        // Authenticate face
        result = await _faceAuthService.authenticateFace(null);
        
        setState(() {
          _isProcessing = false;
          if (result) {
            _message = 'Authentication successful!';
            _isSuccess = true;
            
            // Save authentication state
            _saveAuthState(true);
            
            // Navigate to home screen after successful authentication
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            });
          } else {
            _message = 'Authentication failed. Please try again.';
          }
        });
      } else {
        // Register face
        result = await _faceAuthService.registerFace(null);
        
        setState(() {
          _isProcessing = false;
          if (result) {
            _message = 'Face registered successfully! Now you can authenticate.';
            _isSuccess = true;
          } else {
            _message = 'Face registration failed. Please try again.';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _message = 'Error: $e';
      });
      print('Process image error: $e');
    }
  }

  Future<void> _clearFaceData() async {
    await _faceAuthService.clearFaceData();
    // Clear authentication state
    _saveAuthState(false);
    setState(() {
      _message = 'Face data cleared';
    });
  }
  
  Future<void> _saveAuthState(bool isAuthenticated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_authenticated', isAuthenticated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Authentication'),
        automaticallyImplyLeading: false,
      ),
      body: !_isCameraPermissionGranted
          ? _buildNoCameraAccessUI()
          : Column(
              children: [
                Expanded(
                  child: _isCameraInitialized
                      ? Stack(
                          children: [
                            CameraPreview(_cameraController!),
                            _buildFaceOverlay(),
                            if (_isProcessing)
                              Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Theme.of(context).cardColor,
                  child: Column(
                    children: [
                      if (_message.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: _isSuccess ? Colors.green.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isSuccess ? Colors.green : Colors.grey,
                            ),
                          ),
                          child: Text(
                            _message,
                            style: TextStyle(
                              color: _isSuccess ? Colors.green.shade800 : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(
                                _faceAuthService.isAuthSetup
                                    ? Icons.face
                                    : Icons.person_add,
                              ),
                              label: Text(
                                _faceAuthService.isAuthSetup
                                    ? 'Authenticate Face'
                                    : 'Register Face',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _isProcessing ? null : _processImage,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: _isProcessing ? null : _clearFaceData,
                            tooltip: 'Clear face data',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          _saveAuthState(true);
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        child: const Text('Skip Authentication (For Testing)'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNoCameraAccessUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_photography,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera Access Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'This app needs camera access for face authentication. Please grant camera permission in your device settings.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _initializeCamera();
              },
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                _saveAuthState(true);
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Skip Authentication (For Testing)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(125),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.face,
              size: 60,
              color: Colors.blue,
            ),
            SizedBox(height: 10),
            Text(
              'Position your face in the circle',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                backgroundColor: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 