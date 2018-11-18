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
            .instantiateViewController(withIdentifier: RestaurantMapViewController.identifier)
        let drawerContentVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: RestaurantTableViewController.identifier)
        let restaurantViewController = RestaurantViewController(contentViewController: mainContentVC,
                                                                drawerViewController: drawerContentVC)

        restaurantViewController.viewModel = RestaurantViewModel()

        let navigationController = UINavigationController(rootViewController: restaurantViewController)
        navigationController.setNavigationBarHidden(true, animated: false)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }
}
