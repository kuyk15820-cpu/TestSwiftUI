import SwiftUI

// กำหนดชื่อแบบเจาะจงเพื่อให้ Objective-C ค้นหาตัวแปรเจอตรงๆ
@objc(SwiftViewFactory)
class SwiftViewFactory: NSObject {
    
    @objc static func createMainView() -> UIViewController {
        let mainView = MainView()
        let hostingController = UIHostingController(rootView: mainView)
        hostingController.view.backgroundColor = .black
        return hostingController
    }
}
