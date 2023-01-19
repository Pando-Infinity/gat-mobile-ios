//
//  UIImage+Base64.swift
//  gat
//
//  Created by HungTran on 4/25/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func toBase64() -> String {
        let imageData: Data = self.pngData() ?? Data()
        return imageData.base64EncodedString()
    }
    
    func resizeImage(newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        /*
         let size = CGSize(width: 200.0, height: 200.0)
         let aspectScaledToFitImage = self.af_imageAspectScaled(toFill: size)
         return aspectScaledToFitImage
         */
        
        return newImage!
    }
    
    func scaleImage(toSize newSize: CGSize) -> UIImage? {
        let size = self.size
        
        let widthRatio  = newSize.width  / size.width
        let heightRatio = newSize.height / size.height
        
        var calSize: CGSize
        if(widthRatio > heightRatio) {
            calSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            calSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: calSize.width, height: calSize.height)
        
        UIGraphicsBeginImageContextWithOptions(calSize, false, 0.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func resizeWithPercent(percentage: CGFloat) -> UIImage? {
        let size = self.size
        
        let calSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        
        let rect = CGRect(x: 0, y: 0, width: calSize.width, height: calSize.height)
        
        UIGraphicsBeginImageContextWithOptions(calSize, false, 0.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func resizeAndCompress(_ compressionQuality: CGFloat, maxBytes: Int) -> UIImage? {
        var imageResize: UIImage? = self
        while ((imageResize!.pngData()?.count)! >= maxBytes) {
            guard let tmpImage = imageResize?.resizeWithPercent(percentage: compressionQuality) else {
                    return nil
            }
            imageResize = tmpImage
        }
        // Compress image
        guard let dataCompressed = imageResize?.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        imageResize = UIImage(data: dataCompressed)
        return imageResize
    }
}
