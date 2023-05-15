//
//  AlertPresenter.swift
//  EndlessTape
//
//  Created by Баир Шаралдаев on 13.05.2023.
//

import UIKit

protocol AlertPresenterProtocol: AnyObject {
    func showAlert(alert: UIAlertController)
}

final class AlertPresenter {
    static let shared = AlertPresenter()
    
    weak var delegate: AlertPresenterProtocol?
    
    func createAlert(title: String, message: String, handler: @escaping () -> Void) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
            handler()
        }
        alert.addAction(alertAction)
        delegate?.showAlert(alert: alert)
    }
}
