import SwiftUI
import AVFoundation

class CameraViewModel: NSObject, ObservableObject {
    
    enum Status {
        case unconfigured
        case configured
        case unauthorized
        case faild
    }
    
    var preview: AVCaptureVideoPreviewLayer!
    
    @Published var isReady = false
    @Published var session = AVCaptureSession()
    @Published var isFinished: Bool = false
    @Published var isVideo: Bool = false
    @Published var position: AVCaptureDevice.Position = .front
    @Published var orientation: AVCaptureVideoOrientation = .portrait {
        willSet { rotate(newValue) }
    }
    @Published var previewURL: URL?
    @Published var mediaData = Data(count: 0)
    @Published var recordedDuration: Double = 0
    @Published var isRecording = false
    
    @Published var selectedAsset: AVAsset?
    @Published var selectedImage: UIImage?
    
    @Published var showAlert = false
    @Published var alertIncludeSettings = false
    @Published var alertText = ""
    
    private var status: Status = .unconfigured
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureMovieFileOutput()
    
    private let discoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera],
        mediaType: .video,
        position: .unspecified
    )
    
    private let sessionQueue = DispatchQueue(label: "cameraSessionQueue")
    
    override init() {
        super.init()
        
        configure()
    }
    
    public func controllSession(start: Bool) {
        guard status == .configured else {
            self.configure()
            
            sessionQueue.async {
                self.session.startRunning()
            }
            
            return
        }
        
        sessionQueue.async {
            if start {
                if !self.session.isRunning {
                    self.session.startRunning()
                }
            } else {
                self.session.stopRunning()
            }
        }
    }
    
    private func configure() {
        checkPermissions()
        sessionQueue.async {
            self.configCaptureSession()
        }
    }
    
    public func configCaptureSession(restoreSession: Bool = false) {
        guard status == .unconfigured else { return }
        
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        
        // If session need to be restored
        if restoreSession {
            for input in session.inputs { session.removeInput(input) }
            for output in session.outputs { session.removeOutput(output) }
        }
        
        // Set session preset
        session.sessionPreset = .hd1280x720 // .hd1920x1080
        
        // Prepare devices
        guard
            let cameraDevice = discoverySession.devices.first(where: { device in device.position == position }),
            let audioDevice = AVCaptureDevice.default(for: .audio)
        else {
            handleError(.cameraUnavailable)
            status = .faild
            return
        }
        
        // Add input to session
        do {
            let cameraInput = try AVCaptureDeviceInput(device: cameraDevice)
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if session.canAddInput(cameraInput) && session.canAddInput(audioInput) {
                session.addInput(cameraInput)
                session.addInput(audioInput)
            } else {
                handleError(.videoInputError)
                status = .faild
                return
            }
        } catch {
            handleError(.imageInputError)
            status = .faild
            return
        }
        
        // Add output to session
        if session.canAddOutput(videoOutput) && session.canAddOutput(photoOutput) {
            session.addOutput(videoOutput)
            session.addOutput(photoOutput)
            
            // Setup video connection
            if let videoConnection = videoOutput.connection(with: .video) {
                // Force video orientation
                videoConnection.videoOrientation = orientation
                
                // Fixing mirroring issue
                if videoConnection.isVideoMirroringSupported {
                    videoConnection.isVideoMirrored = (position == .front)
                }
            }
            
            // Setup photo connection
            if let photoConnection = photoOutput.connection(with: .video) {
                // Force video orientation
                photoConnection.videoOrientation = orientation
                
                // Fixing mirroring issue
                if photoConnection.isVideoMirroringSupported {
                    photoConnection.isVideoMirrored = (position == .front)
                }
            }
        } else {
            handleError(.videoOutputError)
            status = .faild
            return
        }
        
        status = .configured
    }
    
    public func reconfigure() {
        status = .unconfigured
        sessionQueue.async {
            self.configCaptureSession(restoreSession: true)
        }
    }
    
    public func takeShoot() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            DispatchQueue.main.async {
                withAnimation {
                    self.isFinished = true
                }
            }
        }
    }
    
    public func retakeShoot() {
        withAnimation {
            isVideo = false
            recordedDuration = 0
            mediaData = Data(count: 0)
            previewURL = nil
            isFinished = false
        }
    }
    
    public func startRecordinng() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("video.mov")
        try? FileManager.default.removeItem(at: fileUrl)
        videoOutput.startRecording(to: fileUrl, recordingDelegate: self)
        isRecording = true
    }
    
    public func stopRecording() {
        videoOutput.stopRecording()
        isRecording = false
        isFinished = true
    }
    
    public func manuallySetPreview(_ previewURL: URL?) {
        self.previewURL = previewURL
        isFinished = true
    }
    
    public func reset() {
        isReady = false
        isFinished = false
        isVideo = false
        position = .front
        previewURL = nil
        mediaData = Data(count: 0)
        recordedDuration = 0
        isRecording = false
        selectedAsset = nil
        selectedImage = nil
    }
    
    public func rotate(_ orientation: AVCaptureVideoOrientation) {
        guard let videoConnection = preview.connection else {
            return
        }
        
        switch orientation {
        case .landscapeLeft:
            videoConnection.videoOrientation = .landscapeLeft
        case .landscapeRight:
            videoConnection.videoOrientation = .landscapeRight
        case .portrait:
            videoConnection.videoOrientation = .portrait
        case .portraitUpsideDown:
            videoConnection.videoOrientation = .portraitUpsideDown
        default:
            videoConnection.videoOrientation = .portrait
        }
        
        reconfigure()
    }
}

// MARK: - Helpers

extension CameraViewModel {
    private func checkPermissions() {
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            sessionQueue.suspend()
            
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                if !authorized {
                    self.status = .unauthorized
                    self.handleError(.deniedCameraAccess)
                    return
                }
                
                if AVAudioSession.sharedInstance().recordPermission != .granted {
                    AVAudioSession.sharedInstance().requestRecordPermission { status in
                        if !status {
                            self.status = .unauthorized
                            self.handleError(.deniedMicrophoneAccess)
                        }
                        
                        self.sessionQueue.resume()
                    }
                }
            }
        }
    }
    
    private func savePhoto() {
        if
            let uiImage = UIImage(data: mediaData),
            let data = uiImage.jpegData(compressionQuality: 0.8)
        {
            let tempFile = NSTemporaryDirectory() + "\(UUID().uuidString).jpg"
            try? data.write(to: URL(fileURLWithPath: tempFile))
            self.previewURL = URL(fileURLWithPath: tempFile)
        }
    }
    
    private func handleError(_ localizedError: CameraLocalizedError) {
        alertIncludeSettings = localizedError == .deniedCameraAccess || localizedError == .deniedMicrophoneAccess
        alertText = localizedError.rawValue
        showAlert.toggle()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        self.mediaData = imageData
        DispatchQueue.main.async {
            self.isFinished = true
        }
        savePhoto()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error {
            print(error.localizedDescription)
            return
        }
        
        previewURL = outputFileURL
        DispatchQueue.main.async {
            self.isFinished = true
        }
        
        do {
            try self.mediaData = Data(contentsOf: outputFileURL)
        } catch {
            print("Error occurred")
        }
    }
}

// MARK: - Errors

extension CameraViewModel {
    enum CameraLocalizedError: String {
        case cameraUnavailable = "Camera or Microphone is Unavailable"
        case videoInputError = "Video Input Error"
        case imageInputError = "Image Input Error"
        case videoOutputError = "Output Video Error"
        case deniedCameraAccess = "Camera Access Denied"
        case deniedMicrophoneAccess = "Microphone Access Denied"
    }
}
