//
//  PriceViewController.swift
//  gat
//
//  Created by Vũ Kiên on 15/11/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class PriceViewController: UIViewController {
    
    class var segueIdentifier: String {
        return "showPrice"
    }
    
    @IBOutlet weak var tableView: UITableView!
    weak var bookDetailController: BookDetailViewController?
    
    var height: CGFloat = 0.0
    var book: BehaviorSubject<BookInfo> = .init(value: BookInfo())
    fileprivate let prices: BehaviorSubject<[PriceBook]> = .init(value: [])
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.height = self.bookDetailController!.heightDetailContainerConstraint.multiplier * self.bookDetailController!.view.frame.height
        self.getData()
        self.setupUI()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        self.getPriceShopee()
        self.getPriceTiki()
        self.getPriceFahasha()
        self.getPriceVinabook()
    }
    
    fileprivate func getPriceShopee() {
        self.book
            .filter { !$0.title.isEmpty }
            .elementAt(0)
            .flatMap {
                PriceBookNetworkService
                    .shared
                    .topMostPriceShopee(book: $0)
                    .catchError { (error) -> Observable<PriceBook?> in
                        print(error.localizedDescription)
                        return Observable.empty()
                }
            }
            .filter { $0 != nil }
            .map { $0! }
            .withLatestFrom(self.prices, resultSelector: { (price, prices) -> [PriceBook] in
                var list = prices
                list.append(price)
                return list
            })
            .subscribe(onNext: { [weak self] (prices) in
                self?.prices.onNext(prices)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getPriceTiki() {
        self.book
            .filter { !$0.title.isEmpty }
            .elementAt(0)
            .flatMap {
                PriceBookNetworkService
                    .shared
                    .topMostPriceTiki(book: $0)
                    .catchError { (error) -> Observable<PriceBook?> in
                        print("error tiki: \(error.localizedDescription)")
                        return Observable.empty()
                    }
            }
            .filter { $0 != nil }
            .map { $0! }
            .withLatestFrom(self.prices, resultSelector: { (price, prices) -> [PriceBook] in
                var list = prices
                list.append(price)
                return list
            })
            .subscribe(onNext: { [weak self] (prices) in
                self?.prices.onNext(prices)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getPriceFahasha() {
        self.book
            .filter { !$0.title.isEmpty }
            .elementAt(0)
            .flatMap {
                PriceBookNetworkService
                    .shared
                    .topMostPriceFahasha(book: $0)
                    .catchError { (error) -> Observable<PriceBook?> in
                        print(error.localizedDescription)
                        return Observable.empty()
                }
            }
            .filter { $0 != nil }
            .map { $0! }
            .withLatestFrom(self.prices, resultSelector: { (price, prices) -> [PriceBook] in
                var list = prices
                list.append(price)
                return list
            })
            .subscribe(onNext: { [weak self] (prices) in
                self?.prices.onNext(prices)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getPriceVinabook() {
        self.book
            .filter { !$0.title.isEmpty }
            .elementAt(0)
            .flatMap {
                PriceBookNetworkService
                    .shared
                    .topMostPriceVinaBook(book: $0)
                    .catchError { (error) -> Observable<PriceBook?> in
                        print(error.localizedDescription)
                        return Observable.empty()
                }
            }
            .filter { $0 != nil }
            .map { $0! }
            .withLatestFrom(self.prices, resultSelector: { (price, prices) -> [PriceBook] in
                var list = prices
                list.append(price)
                return list
            })
            .subscribe(onNext: { [weak self] (prices) in
                self?.prices.onNext(prices)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = 125.0
        self.tableView.delegate = self
        self.prices
            .map({ (prices) -> [PriceBook] in
                var list = prices
                list.sort(by: { $0.price.isLess(than: $1.price) })
                let price = PriceBook()
                price.price = 1.0
                list.append(contentsOf: [price, price])
                return list.filter { !$0.price.isZero }
            })
            .bind(to: self.tableView.rx.items(cellIdentifier: PriceTableViewCell.identifier, cellType: PriceTableViewCell.self))
            { (index, price, cell) in
                cell.price.onNext(price)
            }
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.tableView
            .rx
            .modelSelected(PriceBook.self)
            .filter { !$0.url.isEmpty }
            .map({ (price) -> URL? in
                guard var urlComponents = URLComponents.init(string: "https://fast.accesstrade.com.vn/deep_link/4811771966185685636") else { return nil }
                urlComponents.queryItems = [URLQueryItem(name: "url", value: price.url)]
                return urlComponents.url
            })
            .filter { $0 != nil }
            .map { $0! }
            .flatMap { (url) -> Observable<Bool> in
                return Observable<Bool>.create({ (observer) -> Disposable in
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: { (status) in
                            observer.onNext(status)
                        })
                    } else {
                        observer.onNext(UIApplication.shared.openURL(url))
                    }
                    return Disposables.create()
                })
            }
            .subscribe()
            .disposed(by: self.disposeBag)
    }

}

extension PriceViewController: BookDetailComponents { }

extension PriceViewController: UITableViewDelegate {}

extension PriceViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let relativeYOffset = scrollView.contentOffset.y - self.bookDetailController!.heightDetailContainerConstraint.multiplier * self.bookDetailController!.view.frame.height
        self.height = max(-relativeYOffset, self.bookDetailController!.view.frame.height * self.bookDetailController!.headerViewHeightConstraint.multiplier) < self.bookDetailController!.heightDetailContainerConstraint.multiplier * self.bookDetailController!.view.frame.height ? max(-relativeYOffset, self.bookDetailController!.view.frame.height * self.bookDetailController!.headerViewHeightConstraint.multiplier) : self.bookDetailController!.heightDetailContainerConstraint.multiplier * self.bookDetailController!.view.frame.height
        self.bookDetailController?.view.layoutIfNeeded()
        self.bookDetailController?.changeFrameProfileView(height: height)
    }
}
