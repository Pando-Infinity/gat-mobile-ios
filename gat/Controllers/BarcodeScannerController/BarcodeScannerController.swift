//
//  BarcodeScanner.swift
//  gat
//
//  Created by HungTran on 3/1/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift

//https://gatbook.org/gat_up/{gatup_id}

protocol BarcodeScannerDelegate: class {
    func startSearch()
}

class BarcodeScannerController: UIViewController {
    //MARK: - UI Properties

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var previousVC: UIViewController?
    var controllers: [UIViewController] = []
    var type: BarcodeContainerViewController.ScanBarcodeType = .all
    let isShowSearchBar: BehaviorSubject<Bool> = .init(value: true)
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let statusSearch = BehaviorSubject<Bool>(value: false)

    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        self.performSegue(withIdentifier: "showBarcode", sender: nil)
        self.setupUI()
        self.setupEvent()
    }
    
    // MARK: - Data
    fileprivate func getUserInfo() -> Observable<UserPrivate> {
        return UserNetworkService.shared.privateInfo().flatMap { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }.flatMap { _ in Repository<UserPrivate, UserPrivateObject>.shared.getFirst() }
    }
    
    //MARK: - UI
    private func setupUI() {
        self.searchBar.placeholder = Gat.Text.SEARCH_PLACEHOLDER.localized()
        self.setupSearchBar()
    }
    fileprivate func setupSearchBar() {
        self.isShowSearchBar
            .map { !$0 }
            .subscribe(self.searchBar.rx.isHidden)
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - Event
    private func setupEvent() {
        self.setupBackButtonEvent()
        self.didBeginEditingSearchEvent()
        self.cancelSearchEvent()
        self.buttonClickSearchEvent()
    }
    
    private func setupBackButtonEvent() {
        self.backButton
            .rx
            .tap
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                guard let isModal = self?.isModal() else {
                    return
                }
                if isModal {
                    self?.dismiss(animated: true, completion: nil)
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func didBeginEditingSearchEvent() {
        self.searchBar
            .rx
            .textDidBeginEditing
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.searchBar.showsCancelButton = true
                self?.performSegue(withIdentifier: "showSearch", sender: nil)
                self?.statusSearch.onNext(false)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func cancelSearchEvent() {
        self.searchBar
            .rx
            .cancelButtonClicked
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.searchBar.showsCancelButton = false
                self?.performSegue(withIdentifier: "showBarcode", sender: nil)
                self?.searchBar.text = ""
                self?.searchBar.resignFirstResponder()
                self?.controllers.removeLast()
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func buttonClickSearchEvent() {
        self.searchBar
            .rx
            .searchButtonClicked
            .do(onNext: { [weak self] (_) in
                self?.searchBar.resignFirstResponder()
            })
            .flatMapLatest { _ in Observable<Bool>.just(true) }
            .bind(to: self.statusSearch)
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - Prepare Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearch" {
            let vc = segue.destination as? SearchViewController
//            vc?.isHiddenTabbar.onNext(true)
            vc?.hidesBottomBarWhenPushed = true
            vc?.delegate = self
        } else if segue.identifier == "showBarcode" {
            let vc = segue.destination as? BarcodeContainerViewController
            vc?.delegate = self
            vc?.showJoin = self.showJoin(bookstopId:)
            vc?.type = self.type
        } else if segue.identifier == BookstopOriganizationViewController.segueIdentifier {
            let vc = segue.destination as? BookstopOriganizationViewController
            vc?.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
        }
    }
    
    fileprivate func showJoin(bookstopId: Int) {
        let bookstop = self.getUserInfo().map { $0.bookstops }.map { $0.first(where: { $0.id == bookstopId }) }.share()
        bookstop.filter { $0 == nil }
            .subscribe(onNext: { [weak self] (_) in
                let storyboard = UIStoryboard(name: "BookstopOrganization", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: JoinBookstopViewController.className) as! JoinBookstopViewController
                vc.gotoBookstop = { bookstop in
                    self?.performSegue(withIdentifier: BookstopOriganizationViewController.segueIdentifier, sender: bookstop)
                }
                let bookstop = Bookstop()
                bookstop.id = bookstopId
                vc.bookstop.onNext(bookstop)
                self?.navigationController?.pushViewController(vc, animated: true)
            }).disposed(by: self.disposeBag)

        bookstop.filter { $0 != nil }.map { $0! }
            .subscribe(onNext: { [weak self] (bookstop) in
                self?.performSegue(withIdentifier: BookstopOriganizationViewController.segueIdentifier, sender: bookstop)
            }).disposed(by: self.disposeBag)
    }
}

extension BarcodeScannerController: SearchDelegate {
    
    var activeSearch: Observable<Bool> {
        return self.statusSearch.asObservable()
    }
    
    var textSearch: Observable<String> {
        return self.searchBar.rx.text.orEmpty.asObservable()
    }
    
    func updateTextInSearchBar(text: String) {
        self.searchBar.text = text
        self.searchBar.resignFirstResponder()
    }
}

extension BarcodeScannerController: BarcodeScannerDelegate {
    func startSearch() {
        self.searchBar.becomeFirstResponder()
    }
}
