//
//  QRScannerViewController.swift
//  gat
//
//  Created by jujien on 12/12/2022.
//  Copyright © 2022 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import MTBBarcodeScanner

class QRScannerViewController: UIViewController {
    
    class var segueIdentifier: String { "showCamera" }
    
    @IBOutlet weak var backButton: UIButton!
    
    var resultHandler: ((String) -> Void)?
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate var scanner: MTBBarcodeScanner?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.scanner = MTBBarcodeScanner(previewView: self.view)
        self.backButton.setTitle("", for: .normal)
        self.backButton.rx.tap.bind { _ in
            self.navigationController?.popViewController(animated: true)
        }
        .disposed(by: self.disposeBag)
        self.startBarcodeScanner()
    }
    
    fileprivate func startBarcodeScanner() {
        // Kiểm tra người dùng đã cấp quyền sử dụng Camera.
        MTBBarcodeScanner.requestCameraPermission(success: { [weak self] success in
            if success {
                self?.startScan()
            } else {
                self?.showAlertPermission()
            }
        })
    }
    
    fileprivate func showAlertPermission() {
        let settingAction = ActionButton.init(titleLabel: Gat.Text.CommonError.SETTING_ALERT_TITLE.localized()) {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: { (status) in
                
            })
        }
        AlertCustomViewController.showAlert(title: Gat.Text.CommonError.ERROR_CAMERA_TITLE.localized(), message: Gat.Text.CommonError.CAMERA_ALERT_MESSAGE.localized(), actions: [settingAction], in: self)
    }
    
    fileprivate func startScan() {
        do {
            try self.scanner?.startScanning(resultBlock: { results in
                let value = results?.filter { $0.stringValue != nil }.filter { !($0.stringValue?.isEmpty ?? true) }.map { $0.stringValue! }.first
                guard let result = value else { return }
                self.scanner?.stopScanning()
                self.resultHandler?(result)
                self.navigationController?.popViewController(animated: true)
            })
        } catch {
            print("\(error)")
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
