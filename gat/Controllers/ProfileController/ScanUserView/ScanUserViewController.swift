//
//  ScanUserViewController.swift
//  gat
//
//  Created by macOS on 8/12/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ColorsGradientUserScan {
  let gl: CAGradientLayer

  init() {
    let colorTop = UIColor(red: 74.0/255.0, green: 178.0/255.0, blue: 218.0/255.0, alpha: 1.0).cgColor
    let colorBottom = UIColor(red: 165.0/255.0, green: 165.0/255.0, blue: 223.0/255.0, alpha: 1.0).cgColor

    self.gl = CAGradientLayer()
    self.gl.colors = [ colorTop, colorBottom]
    self.gl.locations = [ 0.0, 1.0]
  }
}

class ScanUserViewController: UIViewController {
    
    @IBOutlet weak var btnExit:UIButton!
    @IBOutlet weak var btnShare:UIButton!
    @IBOutlet weak var viewScan:UIView!
    @IBOutlet weak var imgScanQRCode:UIImageView!
    @IBOutlet weak var lbUserId:UILabel!
    @IBOutlet weak var btnScan:UIButton!
    @IBOutlet weak var viewShare:UIView!
    
    let userPrivate = BehaviorSubject<UserPrivate>(value: UserPrivate())
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
 
    
//MARK: - UI
    func setupUI(){
        self.view.bringSubviewToFront(self.btnExit)
        self.view.bringSubviewToFront(self.btnScan)
        self.view.bringSubviewToFront(self.btnShare)
        self.setupGradientBackground()
        self.cornerRadiusScanView()
        
        self.btnScan.setTitle(" "+"SCAN_USER".localized(), for: .normal)
        
        if Session.shared.isAuthenticated {
            if let user = Session.shared.user {
               let userId = user.profile?.username
                guard let username = userId else {return}
                let userIdString = String(username)
                self.setupQRcode(string: userIdString)
                self.setupTextUserID(string: userIdString)
            }
        }
    }
    
    func setupGradientBackground(){
        let color = ColorsGradientUserScan()
        
        self.viewShare.frame = self.view.frame
        self.viewShare.backgroundColor = UIColor.clear
        let backgroundLayer = color.gl
        backgroundLayer.frame = self.viewShare.frame
        self.viewShare.layer.insertSublayer(backgroundLayer, at: 0)
        self.view.backgroundColor = UIColor(red: 74.0/255.0, green: 178.0/255.0, blue: 218.0/255.0, alpha: 1.0)
    }
    
    func cornerRadiusScanView(){
        self.viewScan.cornerRadius = 13.0
    }
    
    func setupTextUserID(string:String){
        self.lbUserId.text = string
        self.lbUserId.textColor = UIColor.init(red: 96.0/255.0, green: 175.0/255.0, blue: 219.0/255.0, alpha: 1.0)
    }
    
    func setupQRcode(string: String){
        let url = AppConfig.sharedConfig.get("web_url") + "users/\(string)"
        let imageQRcode = generateQRCode(from: url)
        self.imgScanQRCode.image = imageQRcode
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 5, y: 5)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
    
//MARK: - EVENT
    func event(){
        self.exitBtnEvent()
        self.scanBtnEvent()
        self.shareBtnEvent()
    }
    
    func exitBtnEvent(){
        self.btnExit
            .rx
            .controlEvent(.touchUpInside)
            .bind{ [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)
    }
    
    func scanBtnEvent(){
        self.btnScan
            .rx
            .controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                let storyboard = UIStoryboard(name: "Barcode", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "Barcode") as! BarcodeScannerController
                vc.type = .username
                vc.isShowSearchBar.onNext(false)
                self?.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    func shareBtnEvent(){
        self.btnShare
            .rx
            .controlEvent(.touchUpInside)
            .bind{ [weak self] (_) in
                guard let image = self?.viewShare.takeScreenshot() else { return }
                let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                self?.present(controller, animated: true, completion: nil)
        }.disposed(by: disposeBag)
    }
}

extension UIView {

    func takeScreenshot() -> UIImage {

        // Begin context
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)

        // Draw view in that context
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)

        // And finally, get image
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if (image != nil)
        {
            return image!
        }
        return UIImage()
    }
}
