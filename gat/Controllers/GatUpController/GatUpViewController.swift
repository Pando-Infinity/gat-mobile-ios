//
//  GatUpViewController.swift
//  gat
//
//  Created by jujien on 12/28/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import CoreLocation

class GatUpViewController: UIViewController {
    
    class var segueIdentifier: String { "showGatUp" }
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleImg: UIImageView!
    
    fileprivate let data = BehaviorSubject<[SectionModel<Section, Any>]>(value: [])
    fileprivate var datasource: RxCollectionViewSectionedReloadDataSource<SectionModel<Section, Any>>!
    fileprivate let page: BehaviorSubject<Int> = .init(value: 1)
    fileprivate var showStatus: SearchState = .new
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.setupUI()
        self.event()
    }
    
    //MARK: - Data
    fileprivate func getData() {
        self.data.onNext([
            SectionModel<Section, Any>(model: .barcode, items: [1])
        ])
        if var data = try? self.data.value(), !UserDefaults.standard.bool(forKey: "hideGatupBanner") {
            data.append(SectionModel<Section, Any>(model: .gatup, items: [1]))
            self.data.onNext(data)
        }
        self.getBookstop()
        self.getNews()
    }
    
    private func setUpTitle(){
        self.titleLabel.isHidden = true
        self.titleImg.isHidden = false
    }
    
    fileprivate func getBookstop() {
        Repository<UserPrivate, UserPrivateObject>.shared.getFirst().map { $0.bookstops }.filter { !$0.isEmpty }
        .subscribe(onNext: { [weak self] (bookstops) in
            guard let value = try? self?.data.value(), var data = value else { return }
            if #available(iOS 13.0, *) {
                data.append(.init(model: .bookstop, items: bookstops))
            } else {
                data.append(.init(model: .bookstop, items: [bookstops]))
            }
            
            data.sort(by: { $0.identity.rawValue < $1.identity.rawValue })
            self?.data.onNext(data)
        }).disposed(by: self.disposeBag)
        
        self.getLocation().filter { _ in Status.reachable.value }
            .flatMap { (location) -> Observable<[Bookstop]> in
                return BookstopNetworkService.shared.findBookstop(location: location, searchKey: "", option: .organization, showDetail: .detail, sortingBy: .distance, page: 1, per_page: 10)
                    .catchError { (error) -> Observable<[Bookstop]> in
                        HandleError.default.showAlert(with: error)
                        return .empty()
                }
            }
        .subscribe(onNext: { [weak self] (bookstops) in
            guard let value = try? self?.data.value(), var data = value else { return }
            if #available(iOS 13.0, *) {
                if let index = data.firstIndex(where: { $0.identity == .bookstop }) {
                    if data[index].items.isEmpty {
                        data[index].items = bookstops
                    } else {
                        let items = data[index].items.compactMap { $0 as? Bookstop }
                        let lists = bookstops.compactMap { bookstop in items.contains(where: { $0.id == bookstop.id }) ? nil : bookstop }
                        data[index].items.append(contentsOf: lists)
                    }
                } else {
                    data.append(.init(model: .bookstop, items: bookstops))
                    data.sort(by: { $0.identity.rawValue < $1.identity.rawValue })
                }
            } else {
                if let index = data.firstIndex(where: { $0.identity == .bookstop }) {
                    if data[index].items.isEmpty {
                        data[index].items = [bookstops]
                    } else {
                        var items = data[index].items.compactMap { ($0 as? [Any])?.compactMap { $0 as? Bookstop } }.first!
                        let lists = bookstops.compactMap { bookstop in items.contains(where: { $0.id == bookstop.id }) ? nil : bookstop }
                        items.append(contentsOf: lists)
                        data[index].items = [items]
                    }
                } else {
                    data.append(.init(model: .bookstop, items: [bookstops]))
                    data.sort(by: { $0.identity.rawValue < $1.identity.rawValue })
                }
            }
            self?.data.onNext(data)
            
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getLocation() -> Observable<CLLocationCoordinate2D> {
        return LocationManager
            .manager
            .location
            .catchError { (error) -> Observable<CLLocationCoordinate2D> in
                return Repository<UserPrivate, UserPrivateObject>
                    .shared.getFirst()
                    .flatMapLatest({ (userPrivate) -> Observable<CLLocationCoordinate2D> in
                        return Observable<CLLocationCoordinate2D>.from(optional: userPrivate.profile?.location)
                    })
            }
            .map { (location) -> CLLocationCoordinate2D in
                if (location != CLLocationCoordinate2D()) {
                    return location
                } else {
                    return CLLocationCoordinate2D(latitude: 21.022736, longitude: 105.8019441)
                }
            }
        .do(onNext: { [weak self] (_) in
            self?.showStatus = .new
        })
    }
    
    fileprivate func getNews() {
        self.page.filter { _ in Status.reachable.value }
            .flatMap { (page) -> Observable<[NewsBookstop]> in
                return GatupService.shared.news(page: page)
                    .catchError { (error) -> Observable<[NewsBookstop]> in
                        HandleError.default.showAlert(with: error)
                        return .empty()
                }
            }
        .filter { !$0.isEmpty }
        .subscribe(onNext: { [weak self] (lists) in
            guard let value = try? self?.data.value(), var data = value, let status = self?.showStatus else { return }
            if let index = data.firstIndex(where: { $0.identity == .information }) {
                switch status {
                case .new: data[index].items = lists
                case .more: data[index].items.append(contentsOf: lists)
                }
            } else {
                data.append(.init(model: .information, items: lists))
                data.sort(by: { $0.identity.rawValue < $1.identity.rawValue })
            }
            self?.data.onNext(data)
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func hide() {
        guard var data = try? self.data.value() else { return }
        data.removeAll(where: { $0.identity == .gatup })
        UserDefaults.standard.set(true, forKey: "hideGatupBanner")
        self.data.onNext(data)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = "GAT-UP"
        self.setupCollectionView()
        self.setUpTitle()
    }
    
    fileprivate func setupCollectionView() {
        self.registerCell()
        if #available(iOS 13.0, *) {
            self.setupCollectionLayout()
        } else {
            self.collectionView.register(UINib(nibName: ListBookstopGatupCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: ListBookstopGatupCollectionViewCell.identifier)
            self.collectionView.delegate = self
        }
        self.datasource = .init(configureCell: { [weak self] (datasource, collectionView, indexPath, element) -> UICollectionViewCell in
            let section = datasource.sectionModels[indexPath.section].identity
            if section == .barcode {
                return collectionView.dequeueReusableCell(withReuseIdentifier: ScanCollectionViewCell.identifier, for: indexPath)
            } else if section == .gatup {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GatupBannerCollectionViewCell.identifier, for: indexPath) as! GatupBannerCollectionViewCell
                cell.showAction = self?.showPage
                cell.hideAction = self?.hide
                return cell
            } else if let bookstop = element as? Bookstop {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BookstopGatUpCollectionViewCell.identifier, for: indexPath) as! BookstopGatUpCollectionViewCell
                cell.bookstop.accept(bookstop)
                return cell
            } else if let news = element as? NewsBookstop {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsGatupCollectionViewCell.identifier, for: indexPath) as! NewsGatupCollectionViewCell
                cell.news.accept(news)
                cell.seperateView.isHidden = indexPath.row == 0
                cell.showBookEdtion = self?.showBook
                cell.showBookstop = self?.showBookstop
                return cell
            } else if let bookstops = element as? [Bookstop] {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ListBookstopGatupCollectionViewCell.identifier, for: indexPath) as! ListBookstopGatupCollectionViewCell
                cell.bookstops.accept(bookstops)
                cell.showBookstop = self?.showBookstop
                return cell
            } else {
                fatalError()
            }
        }, configureSupplementaryView: { (datasource, collectionView, kind, indexPath) -> UICollectionReusableView in
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: GatUpCollectionReusableView.identifier, for: indexPath) as! GatUpCollectionReusableView
            view.section.accept(datasource.sectionModels[indexPath.section].identity)
            return view
        })
        self.data.bind(to: self.collectionView.rx.items(dataSource: self.datasource)).disposed(by: self.disposeBag)
    }
    
    fileprivate func registerCell() {
        self.collectionView.register(UINib(nibName: BookstopGatUpCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: BookstopGatUpCollectionViewCell.identifier)
        self.collectionView.register(UINib(nibName: NewsGatupCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: NewsGatupCollectionViewCell.identifier)
    }
    
    @available(iOS 13.0, *)
    fileprivate func setupCollectionLayout() {
        self.collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] (sectionNumber, env) -> NSCollectionLayoutSection? in
            guard let value = try? self?.data.value(), let data = value else { return nil }
            let section = data[sectionNumber].identity
            switch section {
            case .barcode: return self?.scanSection()
            case .gatup: return self?.gatupSection()
            case .bookstop: return self?.bookstopSection()
            case .information: return self?.informationSection()
            }
        })
    }
    
    @available(iOS 13.0, *)
    fileprivate func scanSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(88.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.contentInsets = .init(top: 16.0, leading: 16.0, bottom: 0.0, trailing: 16.0)
        
        group.interItemSpacing = .fixed(16.0)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 16.0, leading: 0.0, bottom: 16.0, trailing: 0.0)
        return section
    }
    
    @available(iOS 13.0, *)
    fileprivate func gatupSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(300.0)))
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(300.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.contentInsets = .init(top: 0.0, leading: 16.0, bottom: 16.0, trailing: 16.0)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 16.0, leading: 0.0, bottom: 16.0, trailing: 0.0)
        return section
    }

    @available(iOS 13.0, *)
    fileprivate func bookstopSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(135.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0.0, leading: 8.0, bottom: 0.0, trailing: 8.0)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(156.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0.0, leading: 8.0, bottom: 16.0, trailing: 8.0)
        section.orthogonalScrollingBehavior = .continuous
        section.boundarySupplementaryItems = [self.headerItem()]
        return section
    }
    
    @available(iOS 13.0, *)
    fileprivate func informationSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(105.0)))
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(105.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.edgeSpacing = .init(leading: .none, top: .none, trailing: .none, bottom: .fixed(8.0))
        let section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = [self.headerItem()]
        return section
    }
    
    @available(iOS 13.0, *)
    fileprivate func headerItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        return sectionHeader
    }
    
    // MARK: - Event
    fileprivate func event() {
        LanguageHelper.changeEvent.subscribe(onNext: self.collectionView.reloadData).disposed(by: self.disposeBag)
        self.selectCollectionViewEvent()
        self.scrollEvent()
        self.backEvent()
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func selectCollectionViewEvent() {
        self.collectionView.rx.itemSelected.asObservable().subscribe(onNext: { [weak self] (indexPath) in
            guard let value = try? self?.data.value(), let data = value else { return }
            if data[indexPath.section].identity == .barcode {
                self?.performSegue(withIdentifier: "showBarcode", sender: nil)
            } else if let bookstop = data[indexPath.section].items[indexPath.row] as? Bookstop {
                self?.performSegue(withIdentifier: BookstopOriganizationViewController.segueIdentifier, sender: bookstop)
            } else if let news = data[indexPath.section].items[indexPath.row] as? NewsBookstop, let url = news.url {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func scrollEvent() {
        self.collectionView.rx.didScroll.asObservable().flatMap { [weak self] _ in Observable.from(optional: self?.collectionView) }
            .filter({ (collectionView) -> Bool in
                let translation = collectionView.panGestureRecognizer.translation(in: collectionView.superview)
                return Status.reachable.value && collectionView.contentOffset.y == 0 && translation.y > 100.0
            })
            .flatMap { (_) -> Observable<UserPrivate> in
                return UserNetworkService.shared.privateInfo().catchError { _ in .empty() }
            }
            .map { _ in Repository<UserPrivate, UserPrivateObject>.shared.get() }.filter { $0 != nil }.map { $0! }
            .subscribe(onNext: { [weak self] (user) in
                guard let value = try? self?.data.value(), var data = value else { return }
                if let index = data.firstIndex(where: { $0.identity == .bookstop }) {
                    var bookstops = user.bookstops
                    if #available(iOS 13.0, *) {
                        let items = data[index].items.compactMap { $0 as? Bookstop }.compactMap { bookstop in bookstops.contains(where: { $0.id == bookstop.id }) ? nil : bookstop }
                        bookstops.append(contentsOf: items)
                        data[index] = SectionModel<Section, Any>(model: .bookstop, items: bookstops)
                    } else {
                        let items = data[index].items.compactMap { ($0 as? [Any])?.compactMap { $0 as? Bookstop} }.first?.compactMap { bookstop in bookstops.contains(where: { $0.id == bookstop.id }) ? nil : bookstop } ?? []
                        if !items.isEmpty {
                            bookstops.append(contentsOf: items)
                        }
                        data[index] = SectionModel<Section, Any>(model: .bookstop, items: [bookstops])
                    }
                    self?.data.onNext(data)
                }

            }).disposed(by: self.disposeBag)
        
        self.collectionView.rx.willBeginDecelerating.asObservable().flatMap { [weak self] _ in Observable.from(optional: self?.collectionView) }
            .filter({ (collectionView) -> Bool in
                return collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.frame.height) && Status.reachable.value
            })
            .filter({ (collectionView) -> Bool in
                let translation = collectionView.panGestureRecognizer.translation(in: collectionView.superview)
                return translation.y < -70.0
            })
            .do(onNext: { [weak self] (_) in
                self?.showStatus = .more
            })
            .flatMap { [weak self] (_) -> Observable<Int> in
                guard let value = try? self?.page.value(), let page = value else { return .empty() }
                return .just(page + 1)
            }
            .subscribe(onNext: self.page.onNext)
            .disposed(by: self.disposeBag)
        
            
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == BookstopOriganizationViewController.segueIdentifier {
            let vc = segue.destination as! BookstopOriganizationViewController
            vc.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
            vc.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
        } else if segue.identifier == "showBookDetail" {
            let vc = segue.destination as! BookDetailViewController
            vc.bookInfo.onNext(sender as! BookInfo)
        }
    }
    
    fileprivate func showBook(_ book: BookInfo) {
        self.performSegue(withIdentifier: "showBookDetail", sender: book)
    }
    
    fileprivate func showBookstop(_ bookstop: Bookstop) {
        self.performSegue(withIdentifier: BookstopOriganizationViewController.segueIdentifier, sender: bookstop)
    }
    
    fileprivate func showPage() {
        guard let url = URL(string: AppConfig.sharedConfig.get("landing_page")) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

extension GatUpViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let data = try? self.data.value() else { return .zero }
        switch data[indexPath.section].identity {
        case .barcode: return .init(width: collectionView.frame.width - 32.0, height: 88.0)
        case .gatup: return GatupBannerCollectionViewCell.size(in: collectionView)
        case .bookstop: return .init(width: collectionView.frame.width, height: 172.0)
        case .information: return NewsGatupCollectionViewCell.size(news: data[indexPath.section].items[indexPath.row] as! NewsBookstop, in: collectionView)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let data = try? self.data.value() else { return .zero }
        if data[section].identity == .barcode || data[section].identity == .gatup { return .init(top: 16.0, left: 0.0, bottom: 16.0, right: 0.0) }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let data = try? self.data.value() else { return .zero }
        if data[section].identity == .bookstop || data[section].identity == .information { return .init(width: collectionView.frame.width, height: 25.0) }
        return .zero
    }
}

extension GatUpViewController {
    enum Section: Int {
        case barcode = 1
        case gatup = 0
        case bookstop = 2
        case information = 3
        
        var name: String {
            switch self {
            case .bookstop: return Gat.Text.Gatup.BOOKSTOP_GATUP.localized()//"Tủ sách GAT-UP"
            case .information: return Gat.Text.Gatup.INFORMATION_GATUP.localized()//"Thông tin từ GAT-UP"
            default: return ""
            }
        }
    }
}
