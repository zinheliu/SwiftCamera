//
//  ScaiAPIManager.swift
//  Scaivision
//
//  Created by Liu on 2021/12/17.
//

import Foundation


class ScaiAPIManager{
    var response = [String:Any]()
    func getInfo(withFilePath s3FilePath: String?) -> [String: Any]?{
        let semaphore = DispatchSemaphore (value: 0)
        let parameters = [
            [
                "key": "files",
                "value": s3FilePath ?? "",
                "type": "text"
            ],
            [
                "key": "request_type",
                "value": "https",
                "type": "text"
            ]] as [[String : Any]]
                
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = ""
                //        var _: Error? = nil
        for param in parameters {
            if param["disabled"] == nil {
                let paramName = param["key"]!
                body += "--\(boundary)\r\n"
                body += "Content-Disposition:form-data; name=\"\(paramName)\""
                if param["contentType"] != nil {
                    body += "\r\nContent-Type: \(param["contentType"] as! String)"
                }
                let paramType = param["type"] as! String
                if paramType == "text" {
                    let paramValue = param["value"] as! String
                    body += "\r\n\r\n\(paramValue)\r\n"
                } else {
                    let paramSrc = param["src"] as! String
                    do{
                        let fileData = try NSData(contentsOf: URL(string: paramSrc)!, options:[]) as Data
                        let fileContent = String(data: fileData, encoding: .utf8)
                        body += "; filename=\"\(paramSrc)\"\r\n"
                                + "Content-Type: \"content-type header\"\r\n\r\n\(String(describing: fileContent))\r\n"
                    }catch{
                        print(error)
                    }
                            
                }
            }
        }
        body += "--\(boundary)--\r\n";
        let postData = body.data(using: .utf8)
        var request = URLRequest(url: URL(string: "https://vision.scai.ai/ml")!,timeoutInterval: Double.infinity)
        request.addValue("70ec336a1bfa4d318707d4c169280efc", forHTTPHeaderField: "user")
        request.addValue("103a563bb18e53c464eec726ae697ea6b93040e93565c5b7f27be5af34b3fe6e", forHTTPHeaderField: "key")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = postData
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                semaphore.signal()
                return
            }
            let dicData = String(data: data, encoding: .utf8)!
            
            let dataResponse = self.convertToDictionary(text: dicData)!
            self.response = dataResponse
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        return self.response
    }
            
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try (JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]?)!
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
