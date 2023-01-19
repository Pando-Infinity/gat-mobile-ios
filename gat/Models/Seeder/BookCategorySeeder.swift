//
//  BookCategorySeeder.swift
//  gat
//
//  Created by HungTran on 4/14/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation

extension Seeder {
    
    func seedDataBookCategory() {
        let bookCategories = AppConfig.sharedConfig.get("book_categories") as [[String : AnyObject]]
        for category in bookCategories {
            let bookCategory = BookCategory()
            bookCategory.id = category["id"] as! Int
            bookCategory.name = NSLocalizedString(category["name"] as! String, comment: "")
            bookCategory.image = category["image"] as! String
            bookCategory.selected = category["selected"] as! Bool
            bookCategory.priority = category["priority"] as! Int
            try? self.realm?.write { [weak self] in
                self?.realm?.add(bookCategory, update:.modified)
            }
        }
    }
}
