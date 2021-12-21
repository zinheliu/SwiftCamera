//
//  ContentView.swift
//  Scaivision
//
//  Created by Liu on 2021/12/15.
//

import SwiftUI
import AVFoundation



struct CameraView: View {
    
    var body: some View {
        
            CameraPageView()
        
        
    }
}
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}

struct CameraPageView: View{
    @StateObject var cameraController = CameraController()
    @State private var showingPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var recodedVideoURL: URL?
    @State private var selectedImageView: Image?
    @State private var isShowingPickedImage = false
    @State private var timeRemaining = 5
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        NavigationView{
            ZStack {
                if !isShowingPickedImage {
                    CameraPreview(cameraController: cameraController).ignoresSafeArea(.all, edges: .all)
                } else {
                    VStack{
                        selectedImageView?
                            .resizable()
                            .scaledToFit()
                    }
                    .background(Color.black)
                }
                VStack{
                    HStack{
                        if cameraController.isPhotoTaken{
                            Spacer()
                            Button(action:retakePhoto, label:{
                                Image(systemName: "arrow.triangle.2.circlepath.camera").frame(width: 8, height: 8).foregroundColor(.black).padding(10).background(Color.white).clipShape(Circle()).shadow(radius:10).overlay(Circle().stroke(.white, lineWidth: 2))
                            }).padding(.trailing, 15)
                        } else {
                            Button(action: {}, label: {
                                Image(systemName: "bolt.fill").frame(width: 10, height: 10).foregroundColor(.white).padding(10).background(Color.black).clipShape(Circle()).shadow(radius:10).overlay(Circle().stroke(.white, lineWidth: 2))
                            }).padding(.leading, 15)
                            Spacer()
                            if !cameraController.isPhotoMode{
                                Text("00:00:0\(5-timeRemaining)").font(Font.headline).foregroundColor(.red).onReceive(timer) { _ in
                                    if (cameraController.isRecording){
                                        if timeRemaining > 0{
                                            timeRemaining -= 1
                                            
                                        } else {
                                            stopRecord()
                                        }
                                    }
                                    
                                }
                                Spacer()
                            }
                            Button(action:{}, label:{
                                Image(systemName: "repeat").frame(width: 8, height: 8).foregroundColor(.white).padding(10).background(Color.black).clipShape(Circle()).shadow(radius:10).overlay(Circle().stroke(.white, lineWidth: 2))
                            }).padding(.trailing, 15)
                        }
                    }.padding(.top, 10).padding(.bottom, 20).background(.black)
                    Spacer()
                    HStack{
                        
                        if cameraController.isPhotoTaken{
                            ZStack{
                                HStack{
                                    Button(action:{if !cameraController.isPhotoSaved {
                                        cameraController.savePhoto()
                                    }}, label: {
                                        Text(cameraController.isPhotoSaved ? "Saved" : "Save").foregroundColor(.black).fontWeight(.semibold).padding(.vertical, 10).padding(.horizontal, 20).background(.white).clipShape(Capsule())
                                    }).padding(.leading)
                                    Spacer()
                                }
                                HStack{
                                    Spacer()
//                                    Button(action: moveToViewPage, label: {
//
//                                    })
                                    NavigationLink(destination: InfoView(takenPhoto: self.$selectedImage, recordedVideo: self.$recodedVideoURL)) {
                                        Image(systemName: "icloud.and.arrow.up").padding().frame(width: 75, height: 75).foregroundColor(.black).background(.white).clipShape(Circle())
                                    }.onAppear(perform: {
                                        self.selectedImage = cameraController.takenPhoto
                                    })
//                                    NavigationLink(destination: InfoView()) {
//                                        Image(systemName: "icloud.and.arrow.up").padding().frame(width: 75, height: 75).foregroundColor(.black).background(.white).clipShape(Circle())
//                                    }
                                    Spacer()
                                }
                            }
                        } else {
                            HStack{
                                // Gallery Button
                                Button(action: openGallery, label:{
                                    Image(systemName: "photo.fill").frame(width: 30, height: 30).foregroundColor(.white).padding(15).background(Color.black).shadow(radius:10)
                                }).padding(.leading, 15)
                                Spacer()
                                // Shutter Button
                                if cameraController.isPhotoMode{
                                    Button(action: takePhoto, label:{
                                        ZStack{
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 65, height: 65)
                                            Circle().stroke(Color.white, lineWidth: 2).frame(width: 75, height: 75)
                                        }
                                    })
                                } else {
                                    if !cameraController.isRecording{
                                        Button(action: takeRecord, label:{
                                            ZStack{
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 65, height: 65)
                                                Circle().stroke(Color.white, lineWidth: 2).frame(width: 75, height: 75)
                                            }
                                        })
                                    } else {
                                        Button(action: stopRecord, label:{
                                            ZStack{
                                                Rectangle()
                                                    .fill(Color.red)
                                                    .frame(width: 40, height: 40)
                                                Circle().stroke(Color.white, lineWidth: 2).frame(width: 75, height: 75)
                                            }
                                        })
                                    }
                                }
                                Spacer()
                                // Switch Button
                                if cameraController.isPhotoMode{
                                    Button(action:cameraController.switchMode, label:{
                                        Image(systemName: "video.fill").frame(width: 30, height: 30).foregroundColor(.white).padding(15).background(Color.black).clipShape(Circle()).shadow(radius:10)
                                    }).padding(.trailing, 15)
                                } else {
                                    Button(action:cameraController.switchMode, label:{
                                        Image(systemName: "camera.fill").frame(width: 30, height: 30).foregroundColor(.white).padding(15).background(Color.black).clipShape(Circle()).shadow(radius:10)
                                    }).padding(.trailing, 15)
                                }
                                
                            }
                            
                        }
        
                    }.padding(.top, 25).background(.black)
                }
                .onChange(of: selectedImage) {_ in loadImage()}
                .sheet(isPresented: $showingPhotoPicker){
                    ImagePicker(image: $selectedImage)
                }
            }.navigationTitle("").navigationBarHidden(true)
        }.onAppear(perform: {
            cameraController.checkPermission()
        })
    }
    
    func takePhoto(){
        cameraController.takePhoto()
        self.selectedImage = cameraController.takenPhoto
        
    }
    
    func retakePhoto(){
        cameraController.retakePhoto()
        showingPhotoPicker = false
        isShowingPickedImage = false
    }
    
    func openGallery(){
        showingPhotoPicker = true
        cameraController.isPhotoTaken = true
        isShowingPickedImage = true
    }
    
    func loadImage(){
        guard let pickedImage = selectedImage else {
            return
        }
        print("Picked Image11: \(String(describing: selectedImage))")
        self.selectedImage = pickedImage
        selectedImageView = Image(uiImage: selectedImage!)
    }
    
//    func uploadFileToS3(){
//        if cameraController.isPhotoTaken{
//            self.selectedImage = cameraController.takenPhoto
//        }
//        showingPhotoPicker = false
//        isShowingPickedImage = false
//        print("Picked Image: \(String(describing: self.selectedImage))")
//        AWSS3Manager.shared.uploadImage(image: self.selectedImage!, progress: {( uploadProgress) in
//        }) {(uploadedFileUrl, error) in
//            if let finalPath = uploadedFileUrl as? String {
//                print("Uploaded File Path: \(finalPath)")
//            }
//        }
//    }
    func takeRecord(){
        cameraController.takeRecord()
    }
    
    func stopRecord(){
        cameraController.finishRecord()
        self.recodedVideoURL = cameraController.recordedVideo
    }
}



struct CameraPreview: UIViewRepresentable{
    @ObservedObject var cameraController: CameraController
    
    func makeUIView(context: Context) -> UIView { 
        let view = UIView(frame: UIScreen.main.bounds)
        cameraController.previewLayer = AVCaptureVideoPreviewLayer(session: cameraController.captureSession)
        cameraController.previewLayer!.frame = view.frame
        
        cameraController.previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(cameraController.previewLayer!)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
