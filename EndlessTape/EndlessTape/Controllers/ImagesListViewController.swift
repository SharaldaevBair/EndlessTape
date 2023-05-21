import UIKit

final class ImagesListViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!

    private let photosName: [String] = Array(0..<20).map{ "\($0)" }
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    private let imagesListService = ImagesListService.shared

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier,
            let viewController = segue.destination as? SingleImageViewController,
            let indexPath = sender as? IndexPath,
            let image = UIImage(named: photosName[indexPath.row]) {
                viewController.image = image
            } else {
            super.prepare(for: segue, sender: sender)
        }
    }//  Мы проверяем каждый опционал через guard let и выполняем соответствующие действия только в том случае, если все опционалы не равны nil. Если же хотя бы один опционал равен nil, то код внутри блока guard else будет выполнен, и функция prepare(for segue:sender:) завершится без изменений.
}
// MARK: - Extension
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photosName.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)

        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }

        configCell(for: imageListCell, with: indexPath)

        return imageListCell
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            return 0
        }
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = image.size.width
        let scale = imageViewWidth / imageWidth
        let cellHeight = image.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if indexPath.row + 1 == imagesListService.photos.count {
//            imagesListService.fetchPhotosNextPage()
//        }
//    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let photos = imagesListService.photos
        if indexPath.row + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }
}

extension ImagesListViewController {
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            return
        }

        cell.cellImage.image = image
        cell.dateLabel.text = dateFormatter.string(from: Date())

        let isLiked = indexPath.row % 2 == 0
        let likeImage = isLiked ? UIImage(named: "NoActiveOn") : UIImage(named: "NoActiveOff")
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}
