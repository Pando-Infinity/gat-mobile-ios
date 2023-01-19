//
//  ListBookstopOrganizationViewController.swift
//  gat
//
//  Created by jujien on 12/7/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import WebKit

class ListBookstopOrganizationViewController: UIViewController {
    
    class var segueIdentifier: String { return "showListBookstopOrganization" }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backButton: UIButton!
    fileprivate let disposeBag = DisposeBag()
    fileprivate let bookstop: BehaviorRelay<[Bookstop]> = .init(value: [])
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getData()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        Observable.of(
            Repository<UserPrivate, UserPrivateObject>.shared.getFirst(),
            self.getUserInfo()
        )
            .merge()
            .map { $0.bookstops }
            .subscribe(onNext: self.bookstop.accept).disposed(by: self.disposeBag)
    }
    
    fileprivate func getUserInfo() -> Observable<UserPrivate> {
        return UserNetworkService.shared.privateInfo()
            .catchError({ (error) -> Observable<UserPrivate> in
                return .empty()
            })
            .flatMap { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
            .flatMap { _ in Repository<UserPrivate, UserPrivateObject>.shared.getFirst() }
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.collectionView.alwaysBounceVertical = true 
        let size = CGSize.init(width: UIScreen.main.bounds.width - 32.0, height: 80.0)
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = size
            layout.scrollDirection = .vertical
            layout.minimumLineSpacing = 16.0
            layout.sectionInset = .init(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
        }
        self.bookstop
            .do(onNext: { [weak self] (bookstops) in
                self?.collectionView.isHidden = bookstops.isEmpty
                self?.view.subviews.first(where: { $0.isKind(of: WKWebView.self) })?.isHidden = !bookstops.isEmpty
            })
            .bind(to: self.collectionView.rx.items(cellIdentifier: ListBookstopCollectionViewCell.identifier, cellType: ListBookstopCollectionViewCell.self)) { [weak self] (index, bookstop, cell) in
            cell.bookstop.accept(bookstop)
            cell.actionHandler = self?.remove(bookstop:)
                cell.sizeCell = size
        }.disposed(by: self.disposeBag)
        
        self.bookstop.map { $0.isEmpty }.filter { $0 }
            .subscribe(onNext: { [weak self] (_) in
                self?.collectionView.isHidden = true
                self?.setupWeb()
            }).disposed(by: self.disposeBag)
        
    }
    
    fileprivate func setupWeb() {
        let webView = WKWebView()
        webView.frame = .init(x: 0.0, y: UIScreen.main.bounds.height * 0.1, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.9)
        webView.allowsBackForwardNavigationGestures = false
        self.view.addSubview(webView)
        guard let url = URL(string: AppConfig.sharedConfig.get("landing_page")) else { return }
        webView.load(URLRequest(url: url))
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.backButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
        
        self.collectionView.rx.modelSelected(Bookstop.self).subscribe(onNext: { [weak self] (bookstop) in
            self?.performSegue(withIdentifier: "showBookstopOrganization", sender: bookstop)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func remove(bookstop: Bookstop) {
        var bookstops = self.bookstop.value
        bookstops.removeAll(where: { $0.id == bookstop.id })
        self.bookstop.accept(bookstops)
    }
    

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBookstopOrganization" {
            let vc = segue.destination as? BookstopOriganizationViewController
            vc?.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
        }
    }

}

extension ListBookstopOrganizationViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: collectionView.frame.width - 32.0, height: 80.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
    }
}

extension ListBookstopOrganizationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
