//
//  JoinBarcodeViewController.swift
//  gat
//
//  Created by jujien on 12/12/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
class JoinBarcodeViewController: UIViewController {
    
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var previousVC: UIViewController?
    var controllers: [UIViewController] = []
    
    var bookstop: Bookstop!
    
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.performSegue(withIdentifier: "showBarcode", sender: nil)
        self.event()
    }
    
    fileprivate func handler(value: Int) -> Bool {
        return value == self.bookstop.id
    }
    
    fileprivate func showAlert() {
        let ok = ActionButton(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized()) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        AlertCustomViewController.showAlert(title: Gat.Text.CommonError.NOTIFICATION_TITLE.localized(), message: Gat.Text.JoinBarcode.JOIN_MESSAGE.localized(), actions: [ok], in: self)
    }
    
    fileprivate func showJoin(value: Int) {
        let status = Repository<UserPrivate, UserPrivateObject>.shared.getFirst().map { $0.bookstops }.map { $0.contains(where: { $0.id == value }) }.share()
        status.filter { !$0 }
            .subscribe(onNext: { [weak self] (_) in
                guard let bookstop = self?.bookstop else { return }
                let storyboard = UIStoryboard(name: "BookstopOrganization", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: JoinBookstopViewController.className) as! JoinBookstopViewController
                vc.bookstop.onNext(bookstop)
                self?.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: self.disposeBag)
        
        status.filter { $0 }
            .subscribe(onNext: { [weak self] (_) in
                self?.showAlert()
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - Event
    fileprivate func event() {
        self.backButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBarcode" {
            let vc = segue.destination as? BarcodeContainerViewController
            vc?.type = .join
            vc?.joinHandler = self.handler(value:)
            vc?.showJoin = self.showJoin
        }

    }

}
