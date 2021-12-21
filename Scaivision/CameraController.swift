//
//  CameraController.swift
//  Scaivision
//
//  Created by Liu on 2021/12/15.
//

import Foundation
import AVFoundation
import SwiftUI


class CameraController : NSObject, AVCapturePhotoCaptureDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, AVCaptureFileOutputRecordingDelegate, ObservableObject{
    // Capture Session
    @Published var captureSession = AVCaptureSession()
    
    @Published var isPhotoTaken = false
    @Published var isRecording = false
    @Published var isPhotoSaved = false
    @Published var isPhotoMode = true
    @Published var photoPicker = UIImagePickerController()
    @Published var takenPhoto = UIImage()
    @Published var recordedVideo : URL?
    @Published var outputURL: URL?
    
    
    // Camera Devices
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    
    // Capture Device Inputs
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    
    // Capture Device Outputs
    var photoOutput = AVCapturePhotoOutput()
    var movieOutput = AVCaptureMovieFileOutput()
    
    // Capture Flash Mode
    var flashMode = AVCaptureDevice.FlashMode.off
    
    // Capture Preview Layer
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Camera Options
    var currentCameraPosition: CameraPosition?
    var currenCameratMode: CameraMode = CameraMode.photo
    
    func checkPermission(){
        switch AVCaptureDevice.authorizationStatus(for: .video){
            case .authorized:
                self.setupCamera()
                return
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video){ (status) in
                    if status{
                        self.setupCamera()
                    }
                }
            case .denied:
                print("check issue")
                return
            default:
                    break
        }
    }
    
    func setupCamera(){
        func configureCaptureDevices() throws {
        let cameras = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualWideCamera], mediaType: .video, position: .unspecified).devices.compactMap{$0}
        if cameras.isEmpty { throw CameraControllerError.captureSessionIsMissing} else {
            for camera in cameras{
                if camera.position == .front{
                    self.frontCamera = camera
                } else if camera.position == .back{
                    self.rearCamera = camera
                }
            }
        }
        
    }
        
        func configureCaptureDeviceInputs() throws {
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
            }
        }
        
        func configureCaptureOutputs() throws {
            self.photoOutput = AVCapturePhotoOutput()
            self.photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
                        
            if captureSession.canAddOutput(self.photoOutput) {
                captureSession.addOutput(self.photoOutput)
            }
                        
            self.movieOutput = AVCaptureMovieFileOutput()
                        
            if captureSession.canAddOutput(self.movieOutput){
                captureSession.addOutput(self.movieOutput)
            }
            
            self.captureSession.startRunning()
        }
        
        DispatchQueue(label: "prepare").async{
            do {
                try configureCaptureDevices()
                try configureCaptureDeviceInputs()
                try configureCaptureOutputs()
                
            }
            catch {
                DispatchQueue.main.async {
                    print(error)
                }
                return
            }
                  
            DispatchQueue.main.async {
                return
            }
        }
    }
    
    func retakePhoto(){
        DispatchQueue.global(qos: .background).async{
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                withAnimation{self.isPhotoTaken.toggle()}
                self.isPhotoSaved = false
            }
        }
    }
    
    func takePhoto(){
        DispatchQueue.global(qos: .background).async{
            self.photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            self.captureSession.stopRunning()
            DispatchQueue.main.async{
                withAnimation{self.isPhotoTaken.toggle()}
            }
        }
    }
    
    func savePhoto(){
        UIImageWriteToSavedPhotosAlbum(self.takenPhoto, nil, nil, nil)
        self.isPhotoSaved = true
        print("Saved Photo")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            return
        }
        self.takenPhoto = UIImage(data: data)!
        
        print("Taken Photo:\(self.takenPhoto)")
        print("Photo is taken")
        
    }
    
    func switchMode(){
        DispatchQueue.global(qos: .background).async{
            DispatchQueue.main.async{
                withAnimation{self.isPhotoMode.toggle()}
            }
        }
    }
    
    func setPathURL() -> URL?{
        let directory = NSTemporaryDirectory() as NSString
        if directory != ""{
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
                
        return nil
    }
    
    func takeRecord(){
        DispatchQueue.global(qos: .background).async{ [self] in
            self.outputURL = setPathURL()
            movieOutput.startRecording(to: self.outputURL!, recordingDelegate: self)
            DispatchQueue.main.async{
                withAnimation{self.isRecording.toggle()}
            }
        }
    }
    
    func finishRecord(){
        DispatchQueue.global(qos: .background).async{ [self] in
            movieOutput.stopRecording()
            captureSession.stopRunning()
            DispatchQueue.main.async{
                withAnimation{
                    self.isRecording.toggle();
                    self.isPhotoTaken.toggle()
                }
            }
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if(error != nil){
            print("Camera Recording is not okay")
        } else {
            self.recordedVideo = outputFileURL
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
    }
    
    public enum CameraMode{
        case video
        case photo
    }
}

