import Foundation
import UIKit

extension NSObject {
    class var name: String {
        return String(describing: self)
    }
}
