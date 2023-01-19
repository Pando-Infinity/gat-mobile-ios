//
//  GlobalLoadingViewController.swift
//  gat
//
//  Created by HungTran on 4/6/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import SwiftyGif

class GlobalLoadingViewController: UIViewController {
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        let gifManager = SwiftyGifManager(memoryLimit:20)
        let gif = UIImage(gifName: Gat.Image.gifLoading)
        let imageview = UIImageView(gifImage: gif, manager: gifManager)
        imageview.frame = CGRect(x: view.frame.width/2.0 - 25, y: view.frame.height/2 - 25, width: 50.0, height: 50.0)
        view.addSubview(imageview)
        view.layer.backgroundColor = UIColor.clear.cgColor
    }
    
    //MARK: - Deinit
    deinit {
        print("Đã huỷ: ", className)
    }
}
