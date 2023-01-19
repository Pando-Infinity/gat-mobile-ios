//
//  Category.swift
//  gat
//
//  Created by Vũ Kiên on 23/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift

class Category {
    var id: Int = 0
    var title: String = ""
    var image: String = ""
    
    init(id: Int, title: String) {
        self.id = id
        self.title = title
        self.image = "category-\(self.id)"
    }
    
    static var all: [Category] = [
        Category(id: 1, title: Gat.Text.Category.LITERATURE_CATEGORY_TITLE.localized()),
        Category(id: 3, title: Gat.Text.Category.SKILL_CATEGORY_TITLE.localized()),
        Category(id: 5, title: Gat.Text.Category.ECONOMIC_CATEGORY_TITLE.localized()),
        Category(id: 15, title: Gat.Text.Category.ART_CATEGORY_TITLE.localized()),
        Category(id: 16, title: Gat.Text.Category.RELIGION_CATEGORY_TITLE.localized()),
        Category(id: 13, title: Gat.Text.Category.HISTORY_AND_GEOGRAPHY_CATEGORY_TITLE.localized()),
        Category(id: 14, title: Gat.Text.Category.SCIENCE_CATEGORY_TITLE.localized()),
        Category(id: 2, title: Gat.Text.Category.CHILDREN_CATEGORY_TITLE.localized()),
        Category(id: 10, title: Gat.Text.Category.COMIC_CATEGORY_TITLE.localized()),
        Category(id: 7, title: Gat.Text.Category.TEXTBOOK_CATEGORY_TITLE.localized()),
        Category(id: 8, title: Gat.Text.Category.FOREIGN_LANGUAGE_CATEGORY_TITLE.localized()),
        Category(id: 11, title: Gat.Text.Category.SYLLABUS_CATEGORY_TITLE.localized()),
        Category(id: 12, title: Gat.Text.Category.SYNTHESIS_CATEGORY_TITLE.localized()),
        Category(id: 17, title: Gat.Text.Category.MAGAZINE_CATEGORY_TITLE.localized()),
        Category(id: 4, title: Gat.Text.Category.MOM_AND_BABY_CATEGORY_TITLE.localized())
    ]
}

extension Category: Equatable {
    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.id == rhs.id
    }
    
    
}

extension Category: CustomStringConvertible {
    var description: String {
        return "Category = {\n\tid = \(self.id),\n\ttitle = \(self.title),\n\timage = \(self.image)\n}"
    }
    

}

extension Category: ObjectConvertable {
    typealias Object = CategoryObject
    
    func asObject() -> CategoryObject {
        let object = CategoryObject()
        object.id = self.id
        object.title = self.title
        return object
    }
    
}

class CategoryObject: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var title: String = ""
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

extension CategoryObject: DomainConvertable {
    typealias Domain = Category
    
    func asDomain() -> Category {        
        return Category(id: self.id, title: self.title)
    }
    
}

extension CategoryObject: PrimaryValueProtocol {
    typealias K = Int
    
    func primaryValue() -> Int {
        return self.id
    }
    
    
}

