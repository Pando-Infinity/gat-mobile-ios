//
//  DownloadImage.swift
//  gat
//
//  Created by jujien on 8/20/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct DownloadImageRequest: APIRequest {
    var path: String { "common/get_image/\(self.imageId)" }
    
    var parameters: Parameters? { ["size": self.size] }
    
    let imageId: String
    
    let size: String

}

struct DownloadImageResponse: APIResponse {
    typealias Resource = Data
    
    func map(data: Data?, statusCode: Int) -> Data? {
        guard let data = data, statusCode >= 200 && statusCode < 400 else { return nil }
        return data
    }
}
