//
//  InfoView.swift
//  Scaivision
//
//  Created by Liu on 2021/12/16.
//

import SwiftUI

struct InfoView: View {
    
    
    @Binding var takenPhoto: UIImage?
    @Binding var recordedVideo: URL?
    
    @State private var progress: Double = 0
    private let total: Double = 1
    
    @State private var dataTask: URLSessionDataTask?
    @State private var observation: NSKeyValueObservation?
    @State private var image: UIImage?
    
    @State private var s3FilePath: String?
    
    @State private var scaiImage: String?
    @State private var guidelines = NSDictionary()
    @State private var concerns = NSDictionary()
    @State private var response = [String:Any]()
    @State private var dicDataRespo = NSDictionary()
    @State private var tags = NSArray()
    @State private var tagString: [String] = []
    @State private var strGuidelineDetails:[String] = []
    @State private var strConcerns: [String] = []
    var body: some View {
        VStack{
            ZStack{
                if self.scaiImage == nil{
                    ProgressView("Loading...", value: progress, total: total)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding()
                } else {
                    ScrollView{
                        VStack(spacing: 20){
                            Image(uiImage: self.takenPhoto!).resizable().frame(width: UIScreen.main.bounds.width, height: 500, alignment: .center)
                            VStack{
                                ForEach(tagString, id: \.self){ tag in
                                    Text("\(tag)").background(Color.black).foregroundColor(Color.white).padding(4).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 4)).multilineTextAlignment(TextAlignment.leading)
                                }
                            }
                            VStack{
                                Text("Guidelines").background(Color.black).foregroundColor(Color.white).font(Font.title)
                                ForEach(strGuidelineDetails, id: \.self){ strGuidelineDetail in
//                                    Text("\(strGuidelineDetail)").background(Color.black).foregroundColor(Color.white)
                                    if strGuidelineDetail.prefix(1) == "＜" && strGuidelineDetail.suffix(1) == "＞"{
                                        Text("\(strGuidelineDetail)").frame(width: UIScreen.main.bounds.width, height:25, alignment: .leading).background(Color.black).foregroundColor(Color.white).font(Font.title).multilineTextAlignment(TextAlignment.leading)
                                    } else {
                                        Text("\(strGuidelineDetail)").frame(width: UIScreen.main.bounds.width, height:25,alignment: .leading).background(Color.black).foregroundColor(Color.white).font(Font.body).multilineTextAlignment(TextAlignment.leading)
                                    }
                                }
                            }
                            VStack{
                                Text("Security Concerns").background(Color.black).foregroundColor(Color.white).font(Font.title)
                                ForEach(strConcerns, id: \.self){ strConcern in
                                    Text("\(strConcern)").frame(width: UIScreen.main.bounds.width, height: 25, alignment: .leading).background(Color.black).foregroundColor(Color.white).multilineTextAlignment(TextAlignment.leading)
                                }
                            }
                            
                            
                        }
                    }
                }
            }
        }.onAppear(perform: {
            doTask()
        })
    }
    
    func doTask(){
        AWSS3Manager.shared.uploadImage(image: self.takenPhoto!, progress: {( uploadProgress) in
            self.progress = uploadProgress
                }) {(uploadedFileUrl, error) in
                    if let finalPath = uploadedFileUrl as? String {
                        self.response = ScaiAPIManager().getInfo(withFilePath: finalPath)!
                        let data = self.response["response"] as? NSArray
                        dicDataRespo = (data?[0] as? NSDictionary)!
//                        let arrTag = dicDataRespo.value(forKey: "tag") as? NSArray
                        
                        
                        let imageFile = dicDataRespo.value(forKey: "file") as? String?
                        self.scaiImage = String(describing: imageFile)
                        
                        self.guidelines = (dicDataRespo.value(forKey: "safety_guideline") as? NSDictionary)!
                        self.concerns = (dicDataRespo.value(forKey: "safety_concern") as? NSDictionary)!
                        self.tags = (dicDataRespo.value(forKey: "tag") as? NSArray)!
                        print("Tags:\(tags[0] as? String)")
                        
                        var strGuidelineDes:[String] = []
                        for number in 0..<(tags.count){
                            print( "Tag: \(tags[number] as? String)")
                            tagString.append( (tags[number] as? String)!)
                            print("Guidline: \((guidelines.value(forKey: tags[number] as! String) as! String?)!)")
                            strGuidelineDes.append((guidelines.value(forKey: tags[number] as! String) as! String?)!)
                            strConcerns.append((concerns.value(forKey: tags[number] as! String) as! String?)!)
                        }
                        print("Guidelines: \(strGuidelineDetails)")
                        self.strGuidelineDetails = strGuidelineDes[0].components(separatedBy: "\n")
//                        print("Guidelines ")
//                        let strGuidelineDetails = guidelines?.value(forKey: <#T##String#>)
//
//                        print("Guidelines: \()")

                        
                        
                        
                    } else {
                        print("\(String(describing: error?.localizedDescription))") // 4
                    }
                }
    }
    
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
//        InfoView()
        Text("aa")
    }
}



