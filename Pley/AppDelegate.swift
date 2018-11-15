import UIKit
import AlamofireNetworkActivityIndicator
import StatusBarOverlay
import Pulley

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        NetworkActivityIndicatorManager.shared.isEnabled = true
        StatusBarOverlay.host = YelpAPIService.Constants.host

        window = UIWindow(frame: UIScreen.main.bounds)
        let mainContentVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "RestaurantMapViewController")
        let drawerContentVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "RestaurantTableViewController")
        let restaurantViewController = RestaurantViewController(contentViewController: mainContentVC,
                                                                drawerViewController: drawerContentVC)
        window?.rootViewController = restaurantViewController
        window?.makeKeyAndVisible()

        return true
    }
}
