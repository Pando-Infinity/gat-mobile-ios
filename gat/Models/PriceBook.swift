//
//  PriceBook.swift
//  gat
//
//  Created by Vũ Kiên on 15/11/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation

class PriceBook {
    var price: Double = 0.0
    var priceBeforeDiscount: Double = 0.0
    var currency: String = "VND"
    var discount: Double = 0.0
    var statusStock: Bool = false
    var description: String = ""
    var from: String = ""
    var url: String = ""
}
