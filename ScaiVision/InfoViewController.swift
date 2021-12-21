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

class InfoViewController:UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    var filePath: String = ""
    
    @IBOutlet weak var Coew: NSLayoutConstraint!
    @IBOutlet weak var viewTagggg: UIView!
    @IBOutlet weak var Widthfdf: NSLayoutConstraint!
    @IBOutlet weak var Heigthconr: NSLayoutConstraint!
    @IBOutlet weak var imgTrainlingCont: NSLayoutConstraint!
    @IBOutlet weak var imgLeadingCont: NSLayoutConstraint!
    @IBOutlet weak var heeghtConts: NSLayoutConstraint!
    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var collectionViewCrane: UICollectionView!
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var videoView: UIView!
    
    var dicDataRespo = NSDictionary()
    var objImage = UIImageView()
    var recordedVideoURL: String?
    let sectionInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    let itemsPerRow: CGFloat = 2
    var flowLayoutSubCat: UICollectionViewFlowLayout {
        let _flowLayout = UICollectionViewFlowLayout()
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        _flowLayout.itemSize = CGSize(width: 170, height: 70)
        _flowLayout.sectionInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        _flowLayout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        _flowLayout.minimumInteritemSpacing = 0.0
        _flowLayout.minimumLineSpacing = 10.0
        return _flowLayout
    }

    override func viewDidLoad() {
        imgPhoto.isHidden = true
        videoView.isHidden = true
        
        if UI_USER_INTERFACE_IDIOM() == .pad
        {
            Widthfdf.constant = 90
            Heigthconr.constant = 90
            Coew.constant = 70
            heeghtConts.constant = self.view.frame.size.height / 3
            imgTrainlingCont.constant = 120
            imgLeadingCont.constant = 120
            
        }
        else
        {
            Widthfdf.constant = 54
            Heigthconr.constant = 54
            Coew.constant = 40
            heeghtConts.constant = self.view.frame.height / 3
            imgTrainlingCont.constant = 45
            imgLeadingCont.constant = 45

        }
        
        let arrTag = dicDataRespo.value(forKey: "tag") as? NSArray
        
        if arrTag?.count == 0
        {
            viewTagggg.isHidden = true
        }
        else
        {
            viewTagggg.isHidden = false
        }
        
        self.tblView.contentInset = UIEdgeInsets(top: 10,left: 0,bottom: 0,right: 0)
        
        print("let me see what data is printed from data")
        print ("filePath : \(filePath)")
        ScaiAPIManager().getInfo(withFilePath: filePath){(data) in
            print("data:\(data)")
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let dicData = appDelegate.dicDataResponse["response"] as? NSArray
        
        dicDataRespo = (dicData?[0] as? NSDictionary)!
        
        tblView.delegate = self
        tblView.dataSource = self
        
        collectionViewCrane.delegate = self
        collectionViewCrane.dataSource = self
                
        
        self.tblView.register(UINib(nibName: "HeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "HeaderView")
        
        if let url = NSURL(string: filePath){
            if url.path!.suffix(3) != "mp4"{
                print("aaa: \(url)")
                let data = NSData(contentsOf: url as URL)
                let image = UIImage(data: data! as Data)
                imgPhoto.image = image
                videoView.isHidden = true
                imgPhoto.isHidden = false
            } else {
                videoView.isHidden = true
                imgPhoto.isHidden = false
                print("video filePath: \(filePath)")

                let playVideothumbnail = UIImage(systemName: "play.fill") ?? UIImage()
                let resizedimage = resizeImage(image: playVideothumbnail, width: 60, height: 60)
                imgPhoto.image = resizedimage
                
                
            }
            
        }
                
    }
    func numberOfSections(in tableView: UITableView) -> Int {
       
        let arrTag = dicDataRespo.value(forKey: "tag") as? NSArray
        
        let arrSafetyConcern = dicDataRespo.value(forKey: "safety_concern") as? NSDictionary
        
        return (arrTag?.count ?? 0) + (arrSafetyConcern?.allKeys.count ?? 0)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        let arrSafetyConcern = dicDataRespo.value(forKey: "safety_concern") as? NSDictionary
        
        if arrSafetyConcern?.allKeys.count == 0
        {
            let dicSafety = dicDataRespo.value(forKey: "safety_guideline") as? NSDictionary
            let arrTag = dicDataRespo.value(forKey: "tag") as? NSArray
            let strDetails = dicSafety?.value(forKey: arrTag?.object(at: section) as! String) as! String
            let array = strDetails.components(separatedBy: "\n")
            
            return array.count
        }
        else
        {
            if section == 0
            {
                
                return arrSafetyConcern?.allKeys.count ?? 0
            }
            else
            {
                let dicSafety = dicDataRespo.value(forKey: "safety_guideline") as? NSDictionary
                let arrTag = dicDataRespo.value(forKey: "tag") as? NSArray
                let strDetails = dicSafety?.value(forKey: arrTag?.object(at: section-1) as! String) as! String
                let array = strDetails.components(separatedBy: "\n")
                
                return array.count
            }

        }
 
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
    
        
        let arrSafetyConcern = dicDataRespo.value(forKey: "safety_concern") as? NSDictionary
        
        if arrSafetyConcern?.allKeys.count == 0
        {
            
            let arrTag = dicDataRespo.value(forKey: "tag") as? NSArray

            let dicSafety = dicDataRespo.value(forKey: "safety_guideline") as? NSDictionary

            let strDetails = dicSafety?.value(forKey: arrTag?.object(at: indexPath.section-1) as! String) as! String

            let array = strDetails.components(separatedBy: "\n")
            
            
            let cell = tblView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
            
            cell.lblDes.text = "\(array[indexPath.row])"

            if indexPath.row == 0
            {

                if UI_USER_INTERFACE_IDIOM() == .pad
                {

                    let attributedString1 = NSMutableAttributedString(string: cell.lblDes.text!, attributes: [
                        .font: UIFont.boldSystemFont(ofSize: 28.0),
                        .foregroundColor: UIColor.black
                    ])

                    let priceNSMutableAttributedString = NSMutableAttributedString()
                    priceNSMutableAttributedString.append(attributedString1)

                    cell.lblDes.attributedText = priceNSMutableAttributedString


                }
                else
                {

                    let attributedString1 = NSMutableAttributedString(string: cell.lblDes.text!, attributes: [
                        .font: UIFont.boldSystemFont(ofSize: 15.0),
                        .foregroundColor: UIColor.black
                    ])

                    let priceNSMutableAttributedString = NSMutableAttributedString()
                    priceNSMutableAttributedString.append(attributedString1)

                    cell.lblDes.attributedText = priceNSMutableAttributedString

                }


            }
            else
            {

                if UI_USER_INTERFACE_IDIOM() == .pad
                {

                    let attributedString1 = NSMutableAttributedString(string: "•  \(cell.lblDes.text!)", attributes: [
                        .font: UIFont.systemFont(ofSize: 20.0),
                        .foregroundColor: UIColor.black
                    ])

                    let priceNSMutableAttributedString = NSMutableAttributedString()
                    priceNSMutableAttributedString.append(attributedString1)

                    cell.lblDes.attributedText = priceNSMutableAttributedString


                }
                else
                {

                    let attributedString1 = NSMutableAttributedString(string: "•  \(cell.lblDes.text!)", attributes: [
                        .font: UIFont.systemFont(ofSize: 13.0),
                        .foregroundColor: UIColor.black
                    ])

                    let priceNSMutableAttributedString = NSMutableAttributedString()
                    priceNSMutableAttributedString.append(attributedString1)

                    cell.lblDes.attributedText = priceNSMutableAttributedString

                }

            }
            
            return cell
        }
        else
        {
            if indexPath.section == 0
            {
                
                
                let arrTag = dicDataRespo.value(forKey: "tag") as? NSArray

                let dicSafety = dicDataRespo.value(forKey: "safety_concern") as? NSDictionary

                let strDetails = dicSafety?.value(forKey: arrTag?.object(at: indexPath.section) as! String) as! String

                let array = strDetails.components(separatedBy: "\n")
                
                let cell = tblView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
                
                cell.lblDes.text = "\(array[indexPath.row])"

                if indexPath.row == 0
                {

                    if UI_USER_INTERFACE_IDIOM() == .pad
                    {

                        let attributedString1 = NSMutableAttributedString(string: "•  \(cell.lblDes.text!)", attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 21.0),
                            .foregroundColor: UIColor.red
                        ])

                        let priceNSMutableAttributedString = NSMutableAttributedString()
                        priceNSMutableAttributedString.append(attributedString1)

                        cell.lblDes.attributedText = priceNSMutableAttributedString


                    }
                    else
                    {

                        let attributedString1 = NSMutableAttributedString(string: "•  \(cell.lblDes.text!)", attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 15.0),
                            .foregroundColor: UIColor.red
                        ])

                        let priceNSMutableAttributedString = NSMutableAttributedString()
                        priceNSMutableAttributedString.append(attributedString1)

                        cell.lblDes.attributedText = priceNSMutableAttributedString

                    }


                }
                else
                {
                    

                    if UI_USER_INTERFACE_IDIOM() == .pad
                    {

                        let attributedString1 = NSMutableAttributedString(string: "•  \(cell.lblDes.text!)", attributes: [
                            .font: UIFont.systemFont(ofSize: 20.0),
                            .foregroundColor: UIColor.black
                        ])

                        let priceNSMutableAttributedString = NSMutableAttributedString()
                        priceNSMutableAttributedString.append(attributedString1)

                        cell.lblDes.attributedText = priceNSMutableAttributedString


                    }
                    else
                    {

                        let attributedString1 = NSMutableAttributedString(string: "•  \(cell.lblDes.text!)", attributes: [
                            .font: UIFont.systemFont(ofSize: 13.0),
                            .foregroundColor: UIColor.black
                        ])

                        let priceNSMutableAttributedString = NSMutableAttributedString()
                        priceNSMutableAttributedString.append(attributedString1)

                        cell.lblDes.attributedText = priceNSMutableAttributedString

                    }

                }
                
                return cell
            }
            else
            {
                
                
                let arrTag = dicDataRespo.value(forKey: "tag") as? NSArray

                let dicSafety = dicDataRespo.value(forKey: "safety_guideline") as? NSDictionary

                let strDetails = dicSafety?.value(forKey: arrTag?.object(at: indexPath.section-1) as! String) as! String

                let array = strDetails.components(separatedBy: "\n")
                
                let cell = tblView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
                
                cell.lblDes.text = "\(array[indexPath.row])"

                if indexPath.row == 0
                {

                    if UI_USER_INTERFACE_IDIOM() == .pad
                    {

                        let attributedString1 = NSMutableAttributedString(string: cell.lblDes.text!, attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 28.0),
                            .foregroundColor: UIColor.black
                        ])

                        let priceNSMutableAttributedString = NSMutableAttributedString()
                        priceNSMutableAttributedString.append(attributedString1)

                        cell.lblDes.attributedText = priceNSMutableAttributedString


                    }
                    else
                    {

                        let attributedString1 = NSMutableAttributedString(string: cell.lblDes.text!, attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 15.0),
                            .foregroundColor: UIColor.black
                        ])

                        let priceNSMutableAttributedString = NSMutableAttributedString()
                        priceNSMutableAttributedString.append(attributedString1)

                        cell.lblDes.attributedText = priceNSMutableAttributedString

                    }


                }
                else
                {

                    if UI_USER_INTERFACE_IDIOM() == .pad
                    {

                        let attributedString1 = NSMutableAttributedString(string: "•  \(cell.lblDes.text!)", attributes: [
                            .font: UIFont.systemFont(ofSize: 20.0),
                            .foregroundColor: UIColor.black
                        ])

                        let priceNSMutableAttributedString = NSMutableAttributedString()
                        priceNSMutableAttributedString.append(attributedString1)

                        cell.lblDes.attributedText = priceNSMutableAttributedString


                    }
                    else
                    {

                        let attributedString1 = NSMutableAttributedString(string: "•  \(cell.lblDes.text!)", attributes: [
                            .font: UIFont.systemFont(ofSize: 13.0),
                            .foregroundColor: UIColor.black
                        ])

                        let priceNSMutableAttributedString = NSMutableAttributedString()
                        priceNSMutableAttributedString.append(attributedString1)

                        cell.lblDes.attributedText = priceNSMutableAttributedString

                    }

                }
                
                return cell
            }

        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = Bundle.main.loadNibNamed("HeaderView", owner: self, options: nil)?.first as? HeaderView
        
        let dicSafety = dicDataRespo.value(forKey: "safety_guideline") as? NSDictionary

        
        if section == 1
        {
            headerView?.lblName.text = "Guidelines"
            headerView?.lblName.textColor = .black
        }
        else
        {
            if section == 1
            {
                headerView?.lblName.text = "Guidelines"
                headerView?.lblName.textColor = .black

            }
            else
            {
                headerView?.lblName.text = "Concerns"
                headerView?.lblName.textColor = .red

            }
        }
            
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 15
    }
    
    func resizeImage(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    //MARK:- CollectionView Delegate & DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let arrTag = dicDataRespo.value(forKey: "tag") as? NSArray
        return arrTag?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCollectionViewCell", for: indexPath) as! SliderCollectionViewCell
        
        let arrTag = dicDataRespo.value(forKey: "tag") as? NSArray
        
        cell.btnadasfgs.setTitle(arrTag?.object(at: indexPath.row) as? String, for: .normal)
        
        
        if UI_USER_INTERFACE_IDIOM() == .pad
        {
            cell.Hijkfdfd.constant = 70
            cell.btnadasfgs.layer.cornerRadius = 35
            
        }
        else
        {
            cell.Hijkfdfd.constant = 40
            cell.btnadasfgs.layer.cornerRadius = 20
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtinsetForSectionAt section: Int) -> UIEdgeInsets {
        
        if UI_USER_INTERFACE_IDIOM() == .pad
        {
            
            let totalCellWidth = 170 * collectionView.numberOfItems(inSection: 0)
            let totalSpacingWidth = 10 * (collectionView.numberOfItems(inSection: 0) - 1)
            
            let leftInset = (collectionView.layer.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
            let rightInset = leftInset
            
            return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        }
        else
        {
            
            let totalCellWidth = 120 * collectionView.numberOfItems(inSection: 0)
            let totalSpacingWidth = 10 * (collectionView.numberOfItems(inSection: 0) - 1)
            
            let leftInset = (collectionView.layer.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
            let rightInset = leftInset
            
            return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        }
        
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        
        if UI_USER_INTERFACE_IDIOM() == .pad
        {
            return CGSize(width: 170, height: 70)
        }
        else
        {
            return CGSize(width: 120, height: 40)
        }
        
    }
    
    @IBAction func clickedBack(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appDelegate.window?.rootViewController = vc
        
        appDelegate.window?.makeKeyAndVisible()
    }
    
}

