import UIKit
import ProgressHUD

final class SplashViewController: UIViewController, AuthViewControllerDelegate {
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let oauth2Service = OAuth2Services.sharedServices
    private let oauth2TokenStorage = OAuth2TokenStorage.sharedTokenStorage
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    private var splashScreenLogo: UIImageView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if oauth2TokenStorage.token != nil {
            guard let token = oauth2TokenStorage.token else { return }
            fetchProfile(token)
        } else {
            switchToAuthViewController()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}

extension SplashViewController {
    private func presentAuthViewController() {
        let authViewController = AuthViewController()
        authViewController.delegate = self
        
        let navigationAuthViewController = UINavigationController(rootViewController: authViewController)
        navigationAuthViewController.modalPresentationStyle = .fullScreen
        present(navigationAuthViewController, animated: true)
    }
    
    private func switchToTabBarController() {
        // Получаем экземпляр `Window` приложения
        guard let window = UIApplication.shared.windows.first else { assertionFailure("Invalid Configuration")
            return
        }
        
        // Cоздаём экземпляр нужного контроллера из Storyboard с помощью ранее заданного идентификатора.
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
           
        // Установим в `rootViewController` полученный контроллер
        window.rootViewController = tabBarController
    }
    
    private func switchToAuthViewController() {
        guard let authVC = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else { return }
        authVC.delegate = self
        authVC.modalPresentationStyle = .fullScreen
        present(authVC, animated: true)
    }
    
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            UIBlockingProgressHUD.show()
            self.fetchOAuthToken(code)
        }
    }
    
    private func fetchOAuthToken(_ code: String) {
        oauth2Service.fetchOAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let token):
                self.switchToTabBarController()
                ProgressHUD.dismiss() // Убрать индикатор
                self.fetchProfile(token)
            case .failure(let error):
                ProgressHUD.dismiss() // Убрать индикатор
                self.showAlert(with: error)
                break
            }
        }
    }
    
    private func fetchProfile(_ token: String) {
        profileService.fetchProfile(token) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let userProfile):
                UIBlockingProgressHUD.dismiss()
                self.profileImageService.fetchProfileImageURL(username: userProfile.username, token: token) { _ in }

                self.switchToTabBarController()
            case .failure(let error):
                UIBlockingProgressHUD.dismiss()
                self.showAlert(with: error)
            }
        }
    }
    
    private func showAlert(with error: Error) {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему. Ошибка: \(error)",
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    //MARK: - Верстка кодом
    private func splashScreenLogoView(safeArea: UILayoutGuide) {
        splashScreenLogo = UIImageView()
        splashScreenLogo.image = UIImage(named: "Vector")
        splashScreenLogo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splashScreenLogo)
        
        splashScreenLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        splashScreenLogo.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
}
