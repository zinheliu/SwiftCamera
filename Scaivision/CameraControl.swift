//
//  CameraControl.swift
//  ScaiVision
//
//  Created by Liu on 2021/12/10.
//

import Foundation
import AVFoundation
import UIKit
import Photos

class CameraController : NSObject{
    // Capture Session
    var captureSession: AVCaptureSession?
    
    // Camera Devices
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    var microphone: AVCaptureDevice?
    
    // Camera Device Inputs
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    var microphoneInput: AVCaptureDeviceInput?
    
    // Camera Options
    var currentCameraPosition: CameraPosition?
    var currentMode: CameraMode?
    
    // Camera Device Ouputs
    var photoOutput: AVCapturePhotoOutput?
    var movieOutput: AVCaptureMovieFileOutput?
    
    // Camera Flash Mode
    var flashMode = AVCaptureDevice.FlashMode.off
    
    // Update the PhotoCapture Completion
    var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    
    
    // Update the Moviefile Completion
    var videoCaptureCompletionBlock: ((URL?, Error?) -> Void)?
    
    // PreviewLayer
    var previewLayer: AVCaptureVideoPreviewLayer?

    // Output URL of Video or Photo
    var outputURL: URL?
    
    var isRecording: Bool = false

    
    // Initializer
    func prepare(completionHandler: @escaping(Error?) -> Void){
        
        // Initialize Capture Session
        func createCaptureSession(){
            self.captureSession = AVCaptureSession()
        }
        
        // Initialize Capture Devices
        func configureCaptureDevices() throws {
            
            let cameras = AVCaptureDevice.DiscoverySession(deviceTypes:[.builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices.compactMap{$0}
                
            if cameras.isEmpty {
                self.currentCameraPosition = .noCamera
            }
            else {
                for camera in cameras{
                    if camera.position == .front{
                        self.frontCamera = camera
                        self.currentCameraPosition = .front
                    } else if camera.position == .back{
                        self.rearCamera = camera
                        try camera.lockForConfiguration()
                        camera.focusMode = .autoFocus
                        camera.unlockForConfiguration()
                        self.currentCameraPosition = .rear
                    }
                }
            }
            
            let microphone = AVCaptureDevice.default(for: .audio)
            self.microphone = microphone
            
        }
        
        // Initialize CaptureDeviceInputs
        func configureDeviceInputs() throws {
            guard let captureSession = self.captureSession else {throw CameraControllerError.captureSessionIsMissing}
            // Camera Device Input Configuration
            if let rearCamera = self.rearCamera {
                self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
                if captureSession.canAddInput(self.rearCameraInput!){
                    captureSession.addInput(self.rearCameraInput!)
                }
                self.currentCameraPosition = .rear
            } else if let frontCamera = self.frontCamera{
                self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                if captureSession.canAddInput(self.frontCameraInput!){
                    captureSession.addInput(self.frontCameraInput!)
                }
                self.currentCameraPosition = .front
            } else {
                throw CameraControllerError.noCamerasAvailable
                self.currentCameraPosition = .noCamera
            }
            
            // MicroPhone Input Configuration
            if let microphone = self.microphone{
                self.microphoneInput = try AVCaptureDeviceInput(device: microphone)
                if captureSession.canAddInput(self.microphoneInput!){
                    captureSession.addInput(self.microphoneInput!)
                }
            } else {
                throw CameraControllerError.noMicrophoneAvailable
            }
            
        }
        
        
        
        // Initialize CaptureDevicePhotoOutput or CaptureDeviceMovieOutput
        func configureOutput() throws {
            guard let captureSession = self.captureSession else {throw CameraControllerError.captureSessionIsMissing}
            
            self.photoOutput = AVCapturePhotoOutput()
            self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
            
            if captureSession.canAddOutput(self.photoOutput!) {
                captureSession.addOutput(self.photoOutput!)
            }
            
            self.movieOutput = AVCaptureMovieFileOutput()
            
            if captureSession.canAddOutput(self.movieOutput!){
                captureSession.addOutput(self.movieOutput!)
            }
            
            captureSession.startRunning()
            
        }
        
        
        
        
        // Call the initalizers
        DispatchQueue(label: "prepare").async{
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configureOutput()
                
            }
            catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
        
        
    }
    
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession else {throw CameraControllerError.captureSessionIsMissing}
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        view.layer.insertSublayer(self.previewLayer!, at: 0)
//        view.layer.addSublayer(self.previewLayer!)
        self.previewLayer?.frame = view.bounds
    }
    
    func switchPhotoMode() throws{
        currentMode = .photo
    }
    
    func switchVideoMode() throws{
        currentMode = .video
    }
    
    // Initalize Camera Switch
    func switchCameras() throws {
        guard let currentCameraPosition = currentCameraPosition, let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
        captureSession.beginConfiguration()
        
        func switchToFrontCamera() throws {
            
            guard let rearCameraInput = self.rearCameraInput, captureSession.inputs.contains(rearCameraInput),
                let frontCamera = self.frontCamera else { throw CameraControllerError.invalidOperation }
            
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            
            captureSession.removeInput(rearCameraInput)
            
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
                
                self.currentCameraPosition = .front
            }
                
            else {
                throw CameraControllerError.invalidOperation
            }
        }
        
        func switchToRearCamera() throws {
            
            guard let frontCameraInput = self.frontCameraInput, captureSession.inputs.contains(frontCameraInput),
                let rearCamera = self.rearCamera else { throw CameraControllerError.invalidOperation }
            
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            
            captureSession.removeInput(frontCameraInput)
            
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
                
                self.currentCameraPosition = .rear
            }
                
            else { throw CameraControllerError.invalidOperation }
        }
        
        switch currentCameraPosition {
            case .front:
                try switchToRearCamera()
                
            case .rear:
                try switchToFrontCamera()
            case .noCamera:
                return
        }
        
        captureSession.commitConfiguration()
    }
    
    func setPathURL() -> URL?{
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != ""{
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    func captureImage(completion: @escaping (UIImage?, Error?) -> Void) {
        guard let captureSession = captureSession, captureSession.isRunning else { completion(nil, CameraControllerError.captureSessionIsMissing); return }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode
        
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
        self.photoCaptureCompletionBlock = completion
    }
    
    func captureVideo(completion: @escaping (URL?, Error?) -> Void){
        
        if(self.isRecording == false){
            guard let captureSession = captureSession, captureSession.isRunning else { completion(nil, CameraControllerError.captureSessionIsMissing); return }
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = self.flashMode
            
            self.outputURL = setPathURL()
            
            self.movieOutput?.startRecording(to: self.outputURL!, recordingDelegate: self)
            
            self.videoCaptureCompletionBlock = completion
            
            self.isRecording = true
        } else {
            self.isRecording = false
            self.movieOutput?.stopRecording()
            
        }
     
    }
    
    
}

extension CameraController: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            return
        }
        let image = UIImage(data: data)
            
        captureSession?.stopRunning()
        self.photoCaptureCompletionBlock?(image, nil)
    }
    
    
}


extension CameraController:AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            let recordedVideo = outputFileURL as URL
            self.videoCaptureCompletionBlock?(recordedVideo, nil)
        }
    }
}


extension CameraController {
    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case noMicrophoneAvailable
        case unknown
    }
    
    public enum CameraPosition {
        case front
        case rear
        case noCamera
    }
    
    public enum CameraMode{
        case video
        case photo
    }
}

