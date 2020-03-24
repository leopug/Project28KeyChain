//
//  ViewController.swift
//  Project28KeyChain
//
//  Created by Ana Caroline de Souza on 23/03/20.
//  Copyright © 2020 Ana e Leo Corp. All rights reserved.
//

import UIKit
import LocalAuthentication

enum KeyChainKeys: String {
    case password = "password"
    case secretMessage = "SecretMessage"
}

class ViewController: UIViewController {

    @IBOutlet var secret: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)

        title = "Nothing to see here"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close , target: self, action: #selector(lockScreen))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
    }
    
    @objc func lockScreen(){
        
        saveSecretMessage()
        navigationItem.rightBarButtonItem?.isEnabled = false
        secret.isHidden = true
        
    }
    
    fileprivate func biometricLogin() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            let reason = "Identify Yourself"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        let ac = UIAlertController(title: "Authentication Failed", message: "You can't be verified", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Biometry Unavaliable",
                                       message: "Your device is not configured for biometric authentication", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    @IBAction func authenticateTapped(_ sender: Any) {
        
        if let password = KeychainWrapper.standard.string(forKey: KeyChainKeys.password.rawValue) {
            let ac = UIAlertController(title: "Password step", message: "Please fill your password below", preferredStyle: .alert)
            ac.addTextField()
            ac.textFields?.first?.isSecureTextEntry = true
            ac.addAction(UIAlertAction(title: "send", style: .default, handler: { [weak self] _ in
                if ac.textFields?[0].text == password {
                    self?.biometricLogin()
                }
            }))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Create password", message: "Create or own password below...", preferredStyle: .alert)
            ac.addTextField()
            ac.addAction(UIAlertAction(title: "create", style: .default, handler: { [weak self] _ in
                
                if let password = ac.textFields?[0].text {
                    KeychainWrapper.standard.set(password, forKey: KeyChainKeys.password.rawValue)
                    let ac2 = UIAlertController(title: "Password created", message: "Your password is safe with us (:", preferredStyle: .alert)
                    ac2.addAction(UIAlertAction(title: "Ok", style: .default))
                    self?.present(ac2, animated: true)
                } else {
                    fatalError()
                }
            }))
            present(ac, animated: true)
        }
    }
    
    // MARK: this is the keyboard frame adjustment
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue =
            notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return}
        
        let keyboardScreenEnd = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEnd, to: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        secret.scrollIndicatorInsets = secret.contentInset
        
        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
    
    func unlockSecretMessage(){
        secret.isHidden = false
        navigationItem.rightBarButtonItem?.isEnabled = true
        title = "Secret Stuff!"
        
        secret.text = KeychainWrapper.standard.string(forKey: KeyChainKeys.secretMessage.rawValue) ?? ""
    }
    
    @objc func saveSecretMessage() {
        guard secret.isHidden == false else {return}
        
        KeychainWrapper.standard.set(secret.text, forKey: KeyChainKeys.secretMessage.rawValue)
        secret.resignFirstResponder()
        secret.isHidden = true
        title = "Nothing to see here"
    }
    
}

