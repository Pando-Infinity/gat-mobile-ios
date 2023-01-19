//
//  StartPageCarouselSeeder.swift
//  gat
//
//  Created by HungTran on 4/14/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

extension Seeder {
    func seedDataStartPageCarousel() {
        let carousels = AppConfig.sharedConfig.get(Gat.Text.StartApp.START_PAGE_CAROUSEL_DATA.localized()) as [[String : AnyObject]]
        for carouselItem in carousels {
            let carousel = StartPageCarousel()
            carousel.id = carouselItem["id"] as! Int
            carousel.title = carouselItem["title"] as! String
            carousel.image = carouselItem["image"] as! String
            carousel.content = carouselItem["content"] as! String
            try? self.realm?.write { [weak self] in
                self?.realm?.add(carousel, update:.modified)
            }
        }
    }
}
