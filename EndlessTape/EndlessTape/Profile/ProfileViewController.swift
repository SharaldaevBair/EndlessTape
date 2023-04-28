import UIKit

final class ProfileViewController: UIViewController {
    private var avatarImage: UIImageView!
    private var nameLabel: UILabel!
    private var loginNameLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        avatarImageView(safeArea: view.safeAreaLayoutGuide)
        nameLabelView(safeArea: view.safeAreaLayoutGuide)
        loginNameLabelView(safeArea: view.safeAreaLayoutGuide)
        descriptionLabelView(safeArea: view.safeAreaLayoutGuide)
        logoutButtonView(safeArea: view.safeAreaLayoutGuide)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    //MARK: - Private func
    private func avatarImageView(safeArea: UILayoutGuide) {
        avatarImage = UIImageView()
        avatarImage.image = UIImage(named: "Photo")
        avatarImage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarImage)
        
        avatarImage.widthAnchor.constraint(equalToConstant: 70).isActive = true
        avatarImage.heightAnchor.constraint(equalToConstant: 70).isActive = true
        avatarImage.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        avatarImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32).isActive = true
    }
    
    private func nameLabelView(safeArea: UILayoutGuide) {
        nameLabel = UILabel()
        nameLabel.text = "Екатерина Новикова"
        nameLabel.textColor = .white
        nameLabel.font = UIFont.boldSystemFont(ofSize: 23)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        nameLabel.leadingAnchor.constraint(equalTo: avatarImage.leadingAnchor).isActive = true
        nameLabel.topAnchor.constraint(equalTo: avatarImage.bottomAnchor, constant: 8).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 16).isActive = true
    }
    
    private func loginNameLabelView(safeArea: UILayoutGuide) {
        loginNameLabel = UILabel()
        loginNameLabel.text = "@ekaterina_nov"
        loginNameLabel.textColor = .gray
        loginNameLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginNameLabel)
        
        loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8).isActive = true
        loginNameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor).isActive = true
        loginNameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor).isActive = true
    }
    
    private func descriptionLabelView(safeArea: UILayoutGuide) {
        descriptionLabel = UILabel()
        descriptionLabel.text = "Hello, world!"
        descriptionLabel.textColor = .white
        descriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor).isActive = true
    }
    
    private func logoutButtonView(safeArea: UILayoutGuide) {
        logoutButton = UIButton.systemButton(
            with: UIImage(named: "Exit") ?? UIImage(),
            target: self,
            action: nil
        )
        logoutButton.tintColor = .ypRed
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        
        logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        logoutButton.centerYAnchor.constraint(equalTo: avatarImage.centerYAnchor).isActive = true
    }
}
