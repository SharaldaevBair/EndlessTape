import UIKit
import ProgressHUD

final class SplashViewController: UIViewController {

    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let oauth2Service = OAuth2Service.shared
    private let oAuth2TokenStorage = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    private let logoImage = UIImage(named: "Vector")

    private lazy var logoImageView : UIImageView = {
        let imageView = UIImageView(image: logoImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        initSplashScreen()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if oAuth2TokenStorage.token != nil {
            guard let token = oAuth2TokenStorage.token else { return }
            fetchProfile(token)
        } else {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            guard let authViewController = storyBoard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {return}
            authViewController.delegate = self
            authViewController.modalPresentationStyle = .fullScreen
            self.present(authViewController, animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }

    private func initSplashScreen(){
        view.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: 77),
            logoImageView.widthAnchor.constraint(equalToConstant: 75),
            logoImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)])
    }

    private func switchToTabBarController() {
        // Получаем экземпляр `Window` приложения
        guard let window = UIApplication.shared.windows.first else {fatalError("Invalid Configuration")}

        // Cоздаём экземпляр нужного контроллера из Storyboard с помощью ранее заданного идентификатора.
        let tapBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")

        // Установим в `rootViewController` полученный контроллер
        window.rootViewController = tapBarController
    }
}

extension SplashViewController: AuthViewControllerDelegate {
     func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        UIBlockingProgressHUD.show()
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.fetchOAuthToken(code)
        }
    }

    private func fetchOAuthToken(_ code: String) {
        oauth2Service.fetchAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success (let token):
                self.fetchProfile(token)
            case .failure:
                self.showAlert()
                break
            }
            UIBlockingProgressHUD.dismiss()
        }
    }

    private func fetchProfile(_ token: String) {
        profileService.fetchProfile(token) { [ weak self ] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                UIBlockingProgressHUD.dismiss()
                switch result {
                case .success (let result):
                    self.profileImageService.fetchProfileImageURL(username: result.username) { _ in }
                    self.switchToTabBarController()
                case .failure:
                    self.showAlert()
                }
            }
        }
    }

    private func showAlert() {
        let alertVC = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default)
        alertVC.addAction(action)
        present(alertVC, animated: true)
    }
}
