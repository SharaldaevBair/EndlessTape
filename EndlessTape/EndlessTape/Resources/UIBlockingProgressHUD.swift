import UIKit
import ProgressHUD

var isProgressHUDVisible: Bool = false

final class UIBlockingProgressHUD {
    private static var window: UIWindow? {
        return UIApplication.shared.windows.first
    }
    
    static func show() {
        window?.isUserInteractionEnabled = false
        ProgressHUD.show()
        isProgressHUDVisible = true
    }
    static func dismiss() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
        isProgressHUDVisible = false
        
    }
}
