//
//  PriceBookNetworkService.swift
//  gat
//
//  Created by Vũ Kiên on 15/11/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import SwiftyJSON

class PriceBookNetworkService {
    
    static let shared = PriceBookNetworkService()
    
    private static let PRICE_SHOPEE = "99.000"
    private static let PRICE_TIKI = "150.000"
    private static let PRICE_FAHASHA = "140.000"
    private static let PRICE_VINABOOK = "140.000"
    
    fileprivate init() { }
    
    func topMostPriceShopee(book: BookInfo) -> Observable<PriceBook?> {
        let parameters: Parameters = ["by": "relevancy", "keyword": book.title, "limit": 50, "newest": 0, "page_type": "search", "match_id": 10256]
        return Observable<DataRequest>
            .just(Alamofire.request("https://shopee.vn/api/v2/search_items/", method: .get, parameters: parameters, encoding: URLEncoding.default, headers: ["if-none-match-": "55b03-f36c1bee6a045b8a620b9df0998fb2fa"]))
            .flatMap { (request) -> Observable<JSON> in
                return Observable<JSON>.create({ (observer) -> Disposable in
                    request.responseJSON(completionHandler: { (response) in
                        print("Result \(response.request?.url?.absoluteString as Any)")
                        switch response.result {
                        case .success(let value):
                            let json = JSON(value)
                            if response.response?.statusCode == 200 {
                                observer.onNext(json)
                            }
                            break
                        case .failure(let error):
                            observer.onError(error)
                            break
                        }
                    })
                    return Disposables.create {
                        request.cancel()
                    }
                })
            }
            .map { (json) -> PriceBook? in
                guard let item = json["items"].array?.first else { return nil }
                let price = PriceBook()
                price.currency = item["currency"].string ?? "VND"
                price.description = String(format: Gat.Text.FREE_PRICE_ORDER_TITLE.localized(), PriceBookNetworkService.PRICE_SHOPEE)
                price.discount = item["raw_discount"].double ?? 0.0
                price.from = "Shopee"
                price.price = (item["price"].double ?? 0.0) / 100_000.0
                price.priceBeforeDiscount = (item["price_before_discount"].double ?? 0.0) / 100_000.0
                price.statusStock = (item["stock"].int ?? 0) != 0
                price.url = "https://shopee.vn/\(item["name"].string?.replacingOccurrences(of: " ", with: "-") ?? "")-i.\(item["shopid"].int ?? 0).\(item["itemid"].int ?? 0)"
                return price
        }
    }
    
    func topMostPriceTiki(book: BookInfo) -> Observable<PriceBook?> {
        return Observable<DataRequest>
            .just(Alamofire.request("https://api.tiki.vn/v2/products", method: .get, parameters: ["q": book.title, "page": 1, "aggregations": 1, "limit": 1, "category": 8322], encoding: URLEncoding.default, headers: nil))
            .flatMap { (request) -> Observable<JSON> in
                return Observable<JSON>.create({ (observer) -> Disposable in
                    request.responseJSON(completionHandler: { (response) in
                        print("Result \(response.request?.url?.absoluteString as Any)")
                        switch response.result {
                        case .success(let value):
                            let json = JSON(value)
                            if response.response?.statusCode == 200 {
                                 observer.onNext(json)
                            }
                            break
                        case .failure(let error):
                            observer.onError(error)
                            break
                        }
                    })
                    return Disposables.create {
                        request.cancel()
                    }
                })
            }
            .map { (json) -> PriceBook? in
                json["data"].array?.compactMap({ (item) -> PriceBook? in
                    guard let name = item["name"].string?.lowercased(), name.range(of: book.title.lowercased(), options: .caseInsensitive) != nil else { return nil }
                    let price = PriceBook()
                    price.currency = "VND"
                    price.description = String(format: Gat.Text.FREE_PRICE_ORDER_TITLE.localized(), PriceBookNetworkService.PRICE_TIKI)
                    price.price = item["price"].double ?? 0.0
                    price.priceBeforeDiscount = item["list_price"].double ?? 0.0
                    price.from = "Tiki"
                    price.discount = item["discount_rate"].double ?? 0.0
                    price.statusStock = (item["inventory_status"].string?.lowercased() == "available")
                    price.url = "https://tiki.vn/\(item["url_path"].string ?? "")"
                    return price
                }).first
        }
    }
    
    func topMostPriceFahasha(book: BookInfo) -> Observable<PriceBook?> {
        return Observable<DataRequest>
            .just(Alamofire.request("https://fahasa.com:88/search", method: .get, parameters: ["queryString": book.title, "page": 1, "pageSize": 12, "show": "InStock"], encoding: URLEncoding.default, headers: nil))
            .flatMap { (request) -> Observable<JSON> in
                return Observable<JSON>.create({ (observer) -> Disposable in
                    request.responseJSON(completionHandler: { (response) in
                        print("Result \(response.request?.url?.absoluteString as Any)")
                        switch response.result {
                        case .success(let value):
                            let json = JSON(value)
                            if response.response?.statusCode == 200 {
                                observer.onNext(json)
                            }
                            break
                        case .failure(let error):
                            observer.onError(error)
                            break
                        }
                    })
                    return Disposables.create {
                        request.cancel()
                    }
                })
            }
            .map { (json) -> PriceBook? in
                return json["cms"]["data"].array?.compactMap({ (item) -> PriceBook? in
                    guard let name = item["name"].string?.lowercased(),name.range(of: book.title.lowercased(), options: .caseInsensitive) != nil else { return nil }
                    let price = PriceBook()
                    price.currency = "VND"
                    price.description = String(format: Gat.Text.FREE_PRICE_ORDER_TITLE.localized(), PriceBookNetworkService.PRICE_FAHASHA)
                    price.discount = item["discount_percent"].double ?? 0.0
                    price.price = Double(item["finalPrice"].string ?? "") ?? 0.0
                    price.priceBeforeDiscount = Double(item["originalPrice"].string ?? "") ?? 0.0
                    price.from = "Fahasha"
                    price.statusStock = (item["stock_available"].string ?? "") == "in_stock"
                    var titles = (item["name"].string ?? "").lowercased().replacingOccurrences(of: "đ", with: "d").folding(options: .diacriticInsensitive, locale: .current).components(separatedBy: CharacterSet.alphanumerics.inverted)
                    titles.removeAll(where: { $0.isEmpty })
                    price.url = "https://www.fahasa.com/\(titles.joined(separator: "-")).html"
                    return price
                }).first
            }
    }
    
    func topMostPriceVinaBook(book: BookInfo) -> Observable<PriceBook?> {
        return Observable<UploadRequest>.create { (observer) -> Disposable in
            Alamofire.upload(multipartFormData: { (formData) in
                if let data = book.title.data(using: .utf8) {
                    formData.append(data, withName: "text")
                }
            }, to: "https://www.vinabook.com/?dispatch=products.suggest", headers: ["Content-Type": "application/form-data"]) { (result) in
                switch result {
                case .success(let request, _, _):
                    observer.onNext(request)
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                    observer.onError(error)
                    break
                }
            }
            return Disposables.create {}
        }
            .flatMap { (request) -> Observable<JSON> in
                return Observable<JSON>.create({ (observer) -> Disposable in
                    request.responseJSON(completionHandler: { (response) in
                        print("Result \(response.request?.url?.absoluteString as Any)")
                        switch response.result {
                        case .success(let value):
                            let json = JSON(value)
                            if response.response?.statusCode == 200 {
                                observer.onNext(json)
                            }
                            break
                        case .failure(let error):
                            observer.onError(error)
                            break
                        }
                    })
                    return Disposables.create {
                        request.cancel()
                    }
                })
            }
            .map { (json) -> PriceBook? in
                return json.array?.compactMap({ (item) -> PriceBook? in
                    guard let name = item["value"].string?.lowercased(),name.range(of: book.title.lowercased(), options: .caseInsensitive) != nil else { return nil }
                    let price = PriceBook()
                    price.currency = "VND"
                    price.description = String(format: Gat.Text.FREE_PRICE_ORDER_TITLE.localized(), PriceBookNetworkService.PRICE_VINABOOK)
                    price.price = item["price"].double ?? 0.0
                    price.priceBeforeDiscount = item["list_price"].double ?? 0.0
                    price.discount = (price.priceBeforeDiscount - price.price) * 100.0 / price.priceBeforeDiscount
                    price.from = "Vinabook"
                    price.statusStock = (item["status"].string ?? "") == "A"
                    price.url = "https://www.vinabook.com/\(item["seo_name"].string ?? "")-p\(item["id"].string ?? "").html"
                    return price
                }).first
        }
    }
}
