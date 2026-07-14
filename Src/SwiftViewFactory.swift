import SwiftUI

@objc class SwiftViewFactory: NSObject {
    @objc static func createMainView() -> UIViewController {
        let mainView = MainView()
        let hostingController = UIHostingController(rootView: mainView)
        hostingController.view.backgroundColor = .black
        return hostingController
    }
}
