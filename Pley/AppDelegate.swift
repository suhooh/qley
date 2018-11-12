import UIKit
import Pulley

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let mainContentVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "BusinessMapViewController")
        let drawerContentVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "BusinessTableViewController")
        let businessViewController = BusinessViewController(contentViewController: mainContentVC,
                                                            drawerViewController: drawerContentVC)
        window?.rootViewController = businessViewController
        window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }
}
