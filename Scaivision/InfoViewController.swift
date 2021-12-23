//
//  InfoViewController.swift
//  ScaiVision
//
//  Created by Liu on 2021/12/13.
//

import UIKit
import Foundation
import MediaPlayer
import AVKit
import AVFoundation

class InfoViewController : UIViewController
{
    // Invoked Variables from AWSS3 File...
    var filePath: String = ""
    var recordedVideoURL: String?
    
    // Variables for Description TableView
    var arr_tags = NSArray()
    var arr_str_guidelines : [String] = []
    var arr_str_concerns : [String] = []
    var tableItems : [String] = []
    var isGuildlineContext = false
    var concernCounts = 0
    
    // Conditional Variables
    var currentDeviceType: DeviceType?
    var currentOrientationType: OrientationType?
    
    // Storyboard Variables
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var mediaView: UIView!
    @IBOutlet weak var tagCollectionView: UICollectionView!
    @IBOutlet weak var descriptionTableView: UITableView!
    @IBOutlet weak var rootView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Storyboard View Variables for Configuring UI
    @IBOutlet weak var rootViewHeight: NSLayoutConstraint!
    @IBOutlet weak var mediaViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var mediaViewLeading: NSLayoutConstraint!
    @IBOutlet weak var mediaViewHeight: NSLayoutConstraint!
    @IBOutlet weak var mediaViewTop: NSLayoutConstraint!
    @IBOutlet weak var tagCollectionViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var tagCollectionViewLeading: NSLayoutConstraint!
    @IBOutlet weak var tagCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tagCollectionViewTop: NSLayoutConstraint!
    @IBOutlet weak var descriptionTableViewTop: NSLayoutConstraint!
    @IBOutlet weak var descriptionTableViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var descriptionTableViewLeading: NSLayoutConstraint!
    @IBOutlet weak var descriptionTableViewHeight: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        
        // Check the current device types and orientation types
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad{
            currentDeviceType = .pad
        } else if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone{
            currentDeviceType = .phone
        }
        
        if UIDevice.current.orientation.isLandscape {
            currentOrientationType = .landscape
        } else if UIDevice.current.orientation.isPortrait{
            currentOrientationType = .portrait
        }
        
        
        
        backButton.setImage(UIImage(systemName: "arrowshape.turn.up.backward.fill"), for: .normal)
        
        // Call ScaiAPI with filePath
        ScaiAPIManager().getInfo(withFilePath: filePath){(data) in}
        
        // Get the Response from ScaiAPI
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let dic_response = ((appDelegate.dicDataResponse["response"] as? NSArray)![0] as? NSDictionary)!
        
        
        
        // Put Image or Video file into UIView
        if filePath.suffix(3) == "jpg"{
            let url = URL(string: filePath)
            let data = try? Data(contentsOf: url!)

            if let imageData = data {
                let image = UIImage(data: imageData)
                let resizedImage = resizeImage(image: image!, width: self.mediaView.frame.width-40, height: self.mediaView.frame.height)
                let imageView = UIImageView(image: resizedImage)
                
                self.mediaView.addSubview(imageView)
            }
        } else if filePath.suffix(3) == "mp4"{
            
        }
        
        // Invoke tags
        self.arr_tags = (dic_response.value(forKey: "tag") as? NSArray)!
        
        // Invoke Guidelines
        if (self.arr_tags.count != 0){
            self.isGuildlineContext = true
            let dic_guidelines = (dic_response.value(forKey: "safety_guideline") as? NSDictionary)!
            self.arr_str_guidelines.append("Guidelines")
            for (_, dic_value) in dic_guidelines{
                let arr_dic_value = (dic_value as! String).components(separatedBy: "\n")
                for arr_dic_item_value in arr_dic_value{
                    self.arr_str_guidelines.append(arr_dic_item_value)
                }
            }
        }
        
        // Invoke Concerns
        let dic_concerns = (dic_response.value(forKey: "safety_concern") as? NSDictionary)!
        if dic_concerns.allKeys.count != 0 {
            self.isGuildlineContext = false
            self.arr_str_concerns.append("Concerns")
            for(_, dic_concern_value) in dic_concerns{
                let arr_dic_concern_value  = (dic_concern_value as! String).components(separatedBy: "\n")
                self.arr_str_concerns.append(contentsOf: arr_dic_concern_value)
            }
        }
        if (self.arr_str_concerns.count != 0){
            self.concernCounts = self.arr_str_concerns.count
            self.tableItems.append(contentsOf: self.arr_str_concerns)
        }
        if (self.arr_str_guidelines.count != 0){
            self.tableItems.append(contentsOf: self.arr_str_guidelines)
        }
        
        configureUI()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.orientation.isLandscape {
            currentOrientationType = .landscape
        } else {
            currentOrientationType = .portrait
        }
        
        configureUI()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = vc
        appDelegate.window?.makeKeyAndVisible()
    }
}

extension InfoViewController : UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arr_tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tagCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCollectionViewCell", for: indexPath) as! TagCollectionViewCell
        tagCollectionViewCell.tagButton.layer.cornerRadius = 20
        tagCollectionViewCell.tagButton.setTitle(arr_tags[indexPath.item] as? String, for: .normal)
        return tagCollectionViewCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        print(indexPath.item)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        let totalCellWidth = 110 * arr_tags.count
        let totalSpacingWidth = 20 * (arr_tags.count - 1)

        let leftInset = (UIScreen.main.bounds.width - 40 - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
        let rightInset = leftInset

        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
    }
}

extension InfoViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let descriptionTableViewCell = tableView.dequeueReusableCell(withIdentifier: "DescriptionTableViewCell", for: indexPath) as! DescriptionTableViewCell
        
        if self.tableItems[indexPath.item] == "Concerns" || self.tableItems[indexPath.item] == "Guidelines"{
            let boldFont = UIFont.boldSystemFont(ofSize: 20)
            descriptionTableViewCell.descriptionText.font = boldFont
            descriptionTableViewCell.descriptionText.text = self.tableItems[indexPath.item]
            
        } else if self.tableItems[indexPath.item].prefix(1) == "＜" && self.tableItems[indexPath.item].suffix(1) == "＞"{
            let semiBoldFont = UIFont.boldSystemFont(ofSize: 18)
            descriptionTableViewCell.descriptionText.font = semiBoldFont
            descriptionTableViewCell.descriptionText.text = self.tableItems[indexPath.item]
            
        } else {
            let normalFont = UIFont.systemFont(ofSize: 16)
            descriptionTableViewCell.descriptionText.font = normalFont
            descriptionTableViewCell.descriptionText.text = "•  \(self.tableItems[indexPath.item])"
        }
        
        if indexPath.item < concernCounts {
            isGuildlineContext = false
        } else {
            isGuildlineContext = true
        }
        
        if !isGuildlineContext {
            descriptionTableViewCell.descriptionText.textColor = .red
        } else {
            descriptionTableViewCell.descriptionText.textColor = .black
        }
        return descriptionTableViewCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.item)
    }
    
}

extension InfoViewController{
    func resizeImage(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func configureUI(){
        
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        if currentDeviceType == .phone{
            if currentOrientationType == .portrait{
                // Media View
                let mediaViewWidth = (screenHeight / 3 - 20) / 3 * 4
                mediaViewHeight.constant = screenHeight / 2 - 80
                mediaViewLeading.constant = (screenWidth - mediaViewWidth)/2
                mediaViewTrailing.constant = (screenWidth - mediaViewWidth)/2
                mediaViewTop.constant = 30
                
                // Tag Collection View
                tagCollectionViewLeading.constant = 20
                tagCollectionViewTrailing.constant = 20
                tagCollectionViewHeight.constant = 60
                tagCollectionViewTop.constant = mediaViewHeight.constant + 60
                // Description TableView
                descriptionTableViewTop.constant = tagCollectionViewTop.constant + tagCollectionViewHeight.constant
                descriptionTableViewHeight.constant = CGFloat(tableItems.count) * 43.0
                descriptionTableViewLeading.constant = 20
                descriptionTableViewTrailing.constant = 20
                
                rootViewHeight.constant = 60 + descriptionTableViewTop.constant + descriptionTableViewHeight.constant
            } else if currentOrientationType == .landscape{
                let mediaViewWidth = screenHeight / 6 * 4
                mediaViewHeight.constant = screenHeight / 2
                mediaViewLeading.constant = 20
                mediaViewTrailing.constant = screenWidth - 40 - mediaViewWidth
                mediaViewTop.constant = 30
                // Tag Collection View
                tagCollectionViewLeading.constant = mediaViewWidth + 40
                tagCollectionViewTrailing.constant = 20
                tagCollectionViewHeight.constant = CGFloat(arr_tags.count * 50)
                tagCollectionViewTop.constant = 30
                
                // Description TableView
                descriptionTableViewTop.constant = mediaViewTop.constant + mediaViewHeight.constant + 20
                descriptionTableViewHeight.constant = CGFloat(tableItems.count) * 43.0
                descriptionTableViewLeading.constant = 20
                descriptionTableViewTrailing.constant = 20
                
                rootViewHeight.constant = 60 + descriptionTableViewTop.constant + descriptionTableViewHeight.constant
            }
            
            
        } else if currentDeviceType == .pad{
            if currentOrientationType == .portrait{
                let mediaViewWidth = (screenHeight / 4 - 20) / 3 * 4
                mediaViewHeight.constant = screenHeight / 2 - 80
                mediaViewLeading.constant = (screenWidth - mediaViewWidth)/2
                mediaViewTrailing.constant = (screenWidth - mediaViewWidth)/2
                mediaViewTop.constant = 30
                
                // Tag Collection View
                tagCollectionViewLeading.constant = 20
                tagCollectionViewTrailing.constant = 20
                tagCollectionViewHeight.constant = 60
                tagCollectionViewTop.constant = mediaViewHeight.constant + 10
                // Description TableView
                descriptionTableViewTop.constant = tagCollectionViewTop.constant + tagCollectionViewHeight.constant
                descriptionTableViewHeight.constant = CGFloat(tableItems.count) * 43.0
                descriptionTableViewLeading.constant = 20
                descriptionTableViewTrailing.constant = 20
                
                rootViewHeight.constant = 60 + descriptionTableViewTop.constant + descriptionTableViewHeight.constant
            } else if currentOrientationType == .landscape{
                
                let mediaViewWidth = (screenHeight - 40) / 6 * 4
                mediaViewHeight.constant = screenHeight / 2 - 40
                mediaViewLeading.constant = 20
                mediaViewTrailing.constant = screenWidth - 40 - mediaViewWidth
                mediaViewTop.constant = 30
                // Tag Collection View
                tagCollectionViewLeading.constant = mediaViewWidth + 40
                tagCollectionViewTrailing.constant = 20
                tagCollectionViewHeight.constant = 60
                tagCollectionViewTop.constant = 30
                
                // Description TableView
                descriptionTableViewTop.constant = mediaViewTop.constant + mediaViewHeight.constant + 20
                descriptionTableViewHeight.constant = CGFloat(tableItems.count) * 43.0
                descriptionTableViewLeading.constant = 20
                descriptionTableViewTrailing.constant = 20
                
                rootViewHeight.constant = 60 + descriptionTableViewTop.constant + descriptionTableViewHeight.constant
                
            }
        }
    }
}


extension InfoViewController {
    enum DeviceType{
        case phone
        case pad
    }
    enum OrientationType{
        case portrait
        case landscape
    }
}
