//
//  ViewController.swift
//  ScaiVision
//
//  Created by Liu on 2021/12/8.
//

import UIKit
import AVFoundation
import PhotosUI
import AWSCore
import AWSS3
import SVProgressHUD



class ViewController: UIViewController {
    
    let cameraController = CameraController()
    
    // Initialzie the UIButton and UIView from StoryBoard
    @IBOutlet fileprivate var capturePreview: UIView!
    
    @IBOutlet weak var captureView: UIView!
    @IBOutlet fileprivate var captureButton: UIButton!
    @IBOutlet fileprivate var photoModeButton: UIButton!
    @IBOutlet fileprivate var videoModeButton: UIButton!
    @IBOutlet fileprivate var toggleCameraButton: UIButton!
    @IBOutlet fileprivate var toggleFlashButton: UIButton!
    @IBOutlet fileprivate var pickImageButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var capturePreivewTrailing: NSLayoutConstraint!
    
    var photoButtonImage = UIImage()
    var videoButtonImage = UIImage()
    
    
    var isPhotoStatus: Bool = true
    var imagePicker = UIImagePickerController()
    var pickedImageView = UIImageView()
    var s3FilePath: String?
    
    var isRecording: Bool = false
    var timer: Timer = Timer()
    var recordedTime:Int = 0
    
    public var focusImage: String? = "focus"
   
}

extension ViewController{
    
    override func viewWillAppear(_ animated: Bool) {
       
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.cameraController.previewLayer?.connection?.videoOrientation = .portrait
        
        timerLabel.text = "00:00:00"
        timerLabel.isHidden = true
        videoModeButton.setImage(UIImage(systemName: "video.fill"), for: .normal)
        
        func configureButtonStyle(){
            photoButtonImage = (UIImage(systemName: "camera.fill")?.withTintColor(.gray, renderingMode: .alwaysOriginal))!
            videoButtonImage = (UIImage(systemName: "video.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal))!
            let galleryButtonImage = UIImage(systemName: "photo.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
            
            photoModeButton.setImage(photoButtonImage, for: .normal)
            videoModeButton.setImage(videoButtonImage, for: .normal)
            pickImageButton.setImage(galleryButtonImage, for: .normal)
        }
        func configurePickImageView(){
            
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(pickedImageClick))
            pickedImageView.isUserInteractionEnabled = true
            pickedImageView.addGestureRecognizer(singleTap)
        }
        func configureCameraController(){
            cameraController.prepare{(error) in
                if let error = error{
                    print(error)
                }
                try? self.cameraController.displayPreview(on: self.capturePreview)
            }
        }
        func styleCaptureButton(){
            
            self.captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height)/2
            
            self.captureView.layer.borderColor = UIColor.white.cgColor
            self.captureView.layer.borderWidth = 5
            self.captureView.layer.cornerRadius = min(captureView.frame.width, captureView.frame.height)/2
        }
        
        configureButtonStyle()
        styleCaptureButton()
        configureCameraController()
        configurePickImageView()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.orientation.isLandscape{
            DispatchQueue.main.async {
                self.capturePreivewTrailing.constant = 50
                self.cameraController.previewLayer?.frame = CGRect(x:0, y: 0, width: self.capturePreview.bounds.width+50, height: self.capturePreview.bounds.height)
                self.cameraController.previewLayer?.connection?.videoOrientation = .landscapeRight
            }
        } else {
            DispatchQueue.main.async {
                self.cameraController.previewLayer?.frame = self.capturePreview.bounds
                self.cameraController.previewLayer?.connection?.videoOrientation = .portrait
                self.capturePreivewTrailing.constant = 0
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchPoint = touches.first!
        let screenSize = self.capturePreview.bounds.size
        let tapPoint = touchPoint.location(in: self.capturePreview)
        let x = tapPoint.y/screenSize.height
        let y = 1.0 - tapPoint.x / screenSize.width
        let focusPoint = CGPoint(x:x, y: y)
        let device = self.cameraController.currentCameraPosition == .front ? self.cameraController.frontCamera : self.cameraController.rearCamera
        
        do {
            try device!.lockForConfiguration()

            if device!.isFocusPointOfInterestSupported == true {
                device!.focusPointOfInterest = focusPoint
                device!.focusMode = .autoFocus
            }
            device!.exposurePointOfInterest = focusPoint
            device!.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            device!.unlockForConfiguration()
            //Call delegate function and pass in the location of the touch

            DispatchQueue.main.async {
//                self.delegate?.didFocusOnPoint(tapPoint)
                self.focusAnimationAt(tapPoint)
            }
        }
        catch {
            // just ignore
        }
        
        
                
                    
                
        
        
    }
}


extension ViewController:UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    @IBAction func toggleFlash(_ sender: UIButton) {
        if cameraController.flashMode == .on {
            cameraController.flashMode = .off
            toggleFlashButton.setImage(#imageLiteral(resourceName: "Flash Off Icon"), for: .normal)
        } else {
            cameraController.flashMode = .on
            toggleFlashButton.setImage(#imageLiteral(resourceName: "Flash On Icon"), for: .normal)
        }
    }
    @IBAction func switchCameras(_ sender: UIButton) {
        do {
            try cameraController.switchCameras()
        } catch {
            print(error)
        }
        
        switch cameraController.currentCameraPosition {
            case .some(.front):
                toggleCameraButton.setImage(#imageLiteral(resourceName: "Front Camera Icon"), for: .normal)
            case .some(.rear):
                toggleCameraButton.setImage(#imageLiteral(resourceName: "Rear Camera Icon"), for: .normal)
            case .none:
                return
        }
    }
    @IBAction func switchPhotoMode(_ sender: UIButton){
        self.isPhotoStatus = true
        photoButtonImage = (UIImage(systemName: "camera.fill")?.withTintColor(.gray, renderingMode: .alwaysOriginal))!
        videoButtonImage = (UIImage(systemName: "video.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal))!
        photoModeButton.setImage(photoButtonImage, for: .normal)
        videoModeButton.setImage(videoButtonImage, for: .normal)
        captureButton.backgroundColor = .white
        timerLabel.isHidden = true
    }
    @IBAction func switchVideoMode(_ sender: UIButton){
        self.isPhotoStatus = false
        photoButtonImage = (UIImage(systemName: "camera.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal))!
        videoButtonImage = (UIImage(systemName: "video.fill")?.withTintColor(.gray, renderingMode: .alwaysOriginal))!
        photoModeButton.setImage(photoButtonImage, for: .normal)
        videoModeButton.setImage(videoButtonImage, for: .normal)
        captureButton.backgroundColor = .red
        timerLabel.isHidden = false
    }
    @IBAction func capture(_ sender: UIButton) {
        if self.isPhotoStatus == true{
            cameraController.captureImage {(image, error) in
                guard let image = image else {
                    print(error ?? "Image capture error")
                    return
                }
                try? PHPhotoLibrary.shared().performChangesAndWait {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
                
                SVProgressHUD.show()
                AWSS3Manager.shared.uploadImage(image: image) {(uploadedFileUrl, error) in
                    if let finalPath = uploadedFileUrl as? String {
                        print("Uploaded File URL: \(finalPath)")
                        let s3Filepath = finalPath
                        
                        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let infoViewController = storyBoard.instantiateViewController(withIdentifier: "infoView") as! InfoViewController
                        SVProgressHUD.dismiss()
                        infoViewController.objImage = self.pickedImageView
                        infoViewController.modalPresentationStyle = .fullScreen
                        infoViewController.filePath = s3Filepath
                        self.present(infoViewController, animated: true, completion: nil)
                    } else {
                        print("\(String(describing: error?.localizedDescription))") // 4
                    }
                }
                self.pickedImageView.isHidden = false

                self.pickedImageView.image = image
                self.pickedImageView.contentMode = .scaleAspectFill
                self.pickedImageView.frame = self.view.bounds
                self.view.addSubview(self.pickedImageView)
                
            }
        } else {
//            self.captureView.bounds = self.captureView.frame.insetBy(dx:10.0, dy:10.0)
            
            if (!cameraController.isRecording){
                self.captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height)/2-20
                self.captureView.layer.borderWidth = 0
                
                
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timeCounting), userInfo: nil, repeats: true)
            } else {
                self.captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height)/2
                self.captureView.layer.borderWidth = 5
                timer.invalidate()
            }
            cameraController.captureVideo{(recordedVideo, error) in
                guard let recordedVideo = recordedVideo else {
                    print(error ?? "Video Capture Error")
                    return
                }
                try? PHPhotoLibrary.shared().performChangesAndWait {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: recordedVideo)
                }
                SVProgressHUD.show()
                AWSS3Manager.shared.uploadVideo(videoUrl: recordedVideo) {(uploadedFileUrl, error) in
                    if let finalPath = uploadedFileUrl as? String {
                        print("Uploaded File URL: \(finalPath)")
                        let s3Filepath = finalPath
                        
                        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let infoViewController = storyBoard.instantiateViewController(withIdentifier: "infoView") as! InfoViewController
                        SVProgressHUD.dismiss()
//                        infoViewController.objImage = self.pickedImageView
                        infoViewController.recordedVideoURL = finalPath
                        infoViewController.modalPresentationStyle = .fullScreen
                        infoViewController.filePath = s3Filepath
                        self.present(infoViewController, animated: true, completion: nil)
                    } else {
                        print("\(String(describing: error?.localizedDescription))") // 4
                    }
                }
            }
        }
    }
    @IBAction func pickImage(_ sender:UIButton){
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            DispatchQueue.main.async{
                self.imagePicker.allowsEditing = true
                self.imagePicker.sourceType = .photoLibrary
                self.imagePicker.delegate = self
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    @objc func timeCounting(){
        if (recordedTime < 5){
            recordedTime += 1
            timerLabel.text = "00:00:0\(recordedTime)"
        } else {
            timer.invalidate()
            cameraController.isRecording = false
            cameraController.movieOutput?.stopRecording()
        }
        
    }
    @objc func pickedImageClick(){
        let pickedImage = self.pickedImageView.image
        
        if pickedImage != nil
        {
            
            // Upload image to AWSS3
            SVProgressHUD.show()
            AWSS3Manager.shared.uploadImage(image: pickedImage!) {(uploadedFileUrl, error) in
                if let finalPath = uploadedFileUrl as? String {
                    print("Uploaded File URL: \(finalPath)")
                    let s3Filepath = finalPath
                    
                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let infoViewController = storyBoard.instantiateViewController(withIdentifier: "infoView") as! InfoViewController
                    SVProgressHUD.dismiss()
                    infoViewController.objImage = self.pickedImageView
                    infoViewController.modalPresentationStyle = .fullScreen
                    infoViewController.filePath = s3Filepath
                    self.present(infoViewController, animated: true, completion: nil)
                } else {
                    print("\(String(describing: error?.localizedDescription))") // 4
                }
            }
        }
    }
    func resizeImage(image: UIImage) -> UIImage {
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        let scale = self.view.frame.width/image.size.width
        
        let newHeight = scale * image.size.height

        UIGraphicsBeginImageContext(CGSize(width: screenWidth, height: screenHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: 500, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
          // let scaledImage = self.resizeImage(image: pickedImage)
            self.pickedImageView.image = pickedImage
            self.pickedImageView.contentMode = .scaleAspectFill
            self.pickedImageView.frame = self.view.bounds
            self.view.addSubview(self.pickedImageView)
        }
        dismiss(animated: true, completion: nil)
    }
}

extension ViewController {
    private func focusAnimationAt(_ point: CGPoint) {
//        guard let focusImage = self.focusImage else {
//            return
//        }
        let image = UIImage(systemName: "viewfinder")
        let focusView = UIImageView(image: image)
        focusView.center = point
        focusView.alpha = 0.0
        self.view.addSubview(focusView)
        //      self.previewView.addSubview(focusView)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }) { (success) in
                focusView.removeFromSuperview()
            }
        }
    }
    
}

extension Data{
    var format: String{
        let array = [UInt8](self)
        let ext: String
        switch (array[0]){
            case 0xFF:
                ext = "jpg"
            case 0x89:
                ext = "png"
            case 0x47:
                ext = "gif"
            case 0x49, 0x4D:
                ext = "tiff"
            default:
                ext="unknown"
        }
        return ext
    }
}



