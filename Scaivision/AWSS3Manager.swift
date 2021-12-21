//
//  AWSS3Manager.swift
//  Scaivision
//
//  Created by Liu on 2021/12/16.
//

import Foundation
import UIKit
import AWSS3

typealias progressBlock = (_ progress: Double) -> Void
typealias completionBlock = (_ response: Any?, _ error: Error?) -> Void

class AWSS3Manager{
    static let shared = AWSS3Manager()
    
    private init(){
        
    }
    
    let bucketName = "scaivision-ios"
    
    func uploadImage(image: UIImage, progress: progressBlock?, completion: completionBlock?){
        
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            let error = NSError(domain:"", code: 402, userInfo: [NSLocalizedDescriptionKey:"invalid image"])
            completion?(nil, error)
            return
        }
                
        let tempPath = NSTemporaryDirectory() as String
        let fileName: String = ProcessInfo.processInfo.globallyUniqueString+(".jpg")
        
        let filePath = tempPath + "/" + fileName
        let fileUrl = URL(fileURLWithPath: filePath)
        do {
            try imageData.write(to: fileUrl)
            self.uploadFile(fileUrl: fileUrl, fileName: fileName, contenType: "image", progress: progress, completion: completion)
        } catch{
            let error = NSError(domain:"", code:402, userInfo:[NSLocalizedDescriptionKey: "invalid image"])
            completion?(nil, error)
        }
    }
    
    func uploadVideo(videoUrl: URL, progress: progressBlock?, completion: completionBlock?){
        let filename = self.getUniqueFileName(fileUrl: videoUrl)
        self.uploadFile(fileUrl: videoUrl, fileName: filename, contenType: "video", progress: progress, completion: completion)
    }
        
    func uploadFile(fileUrl: URL, fileName: String, contenType: String, progress: progressBlock?, completion: completionBlock?){
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task, awsProgress) in
            guard let uploadProgress = progress else { return }
            DispatchQueue.main.async {
                uploadProgress(awsProgress.fractionCompleted)
            }
        }
            
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if error == nil {
                    let url = AWSS3.default().configuration.endpoint.url
                    let publicURL = url?.appendingPathComponent(self.bucketName).appendingPathComponent(fileName)
                    
                    if let completionBlock = completion {
                        completionBlock(publicURL?.absoluteString, nil)
                    }
                } else {
                    if let completionBlock = completion {
                        completionBlock(nil, error)
                    }
                }
            })
        }
        let awsTransferUtility = AWSS3TransferUtility.default()
        awsTransferUtility.uploadFile(fileUrl, bucket: bucketName, key: fileName, contentType: contenType, expression: expression, completionHandler: completionHandler).continueWith { (task) -> Any? in
            if let error = task.error {
                print("error is: \(error.localizedDescription)")
            }
            if let _ = task.result {
                            // your uploadTask
            }
            return nil
        }
    }
        
    func getUniqueFileName(fileUrl: URL) -> String {
        let strExt: String = "." + (URL(fileURLWithPath: fileUrl.absoluteString).pathExtension)
        return (ProcessInfo.processInfo.globallyUniqueString + (strExt))
    }
}
