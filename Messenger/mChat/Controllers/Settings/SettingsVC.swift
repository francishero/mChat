//
//  SettingsVC.swift
//  mChat
//
//  Created by Vitaliy Paliy on 11/17/19.
//  Copyright © 2019 PALIY. All rights reserved.
//

import UIKit
import Firebase

class SettingsVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    var logoutButton = UIButton(type: .system)
    var tableView = UITableView()
    
    var settingsItems = ["Appearance", "Maps"]
    var settingsImages = ["paint_icon","map_icon"]
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Settings"
        view.backgroundColor = .white
        setupTableView()
        setupLeftNavButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
        tabBarController?.tabBar.isHidden = false
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func setupLeftNavButton(){
        logoutButton.setTitle("Sign out", for: .normal)
        logoutButton.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 18)
        logoutButton.setTitleColor(.systemRed, for: .normal)
        logoutButton.addTarget(self, action: #selector(setupLogoutView), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: logoutButton)
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func setupTableView(){
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.backgroundColor = .clear
        tableView.register(ProfileCell.self, forCellReuseIdentifier: "ProfileCell")
        tableView.register(SettingsCell.self, forCellReuseIdentifier: "SettingsCell")
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    @objc func setupLogoutView() {
        let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to sign out?", preferredStyle: .alert)
        let exitAction = UIAlertAction(title: "Exit", style: .destructive) { (true) in
            self.logoutButtonPressed()
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(exitAction)
        present(alert, animated: true, completion: nil)
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    @objc func logoutButtonPressed(){
        do{
            UserActivity.observe(isOnline: false)
            try Auth.auth().signOut()
            let controller = SignInVC()
            ChatKit.mapTimer.invalidate()
            Friends.list = []
            Database.database().reference().child("friendsList").child(CurrentUser.uid).removeAllObservers()
            Database.database().reference().child("users").removeAllObservers()
            Database.database().reference().child("userActions").removeAllObservers()
            view.window?.rootViewController = controller
            view.window?.makeKeyAndVisible()
        }catch{
            showAlert(title: "Error", message: error.localizedDescription)
        }
        
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func changeProfileImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { (alertAction) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.sourceType = .camera
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Open Photo Library", style: .default, handler: { (alertAction) in
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }))
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        cancelAction.setValue(UIColor.systemRed, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        uploadImageToStorage(originalImage) { (url, error) in
            guard error == nil , let url = url else { return }
            self.updateCurrentUserInfo(url)
        }
        dismiss(animated: true, completion: nil)
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func uploadImageToStorage(_ image: UIImage, completion: @escaping (_ imageUrl: URL?, _ error: Error?) -> Void) {
        let uniqueName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("ProfileImages").child("\(uniqueName).jpg")
        if let uploadData = image.jpegData(compressionQuality: 0.1) {
            storageRef.putData(uploadData, metadata: nil) { (metaData, error) in
                if let error = error { return completion(nil, error) }
                storageRef.downloadURL { (url, error) in
                    if let error = error { return completion(nil, error) }
                    if let url = url { return completion(url, nil) }
                }
            }
        }
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func updateCurrentUserInfo(_ url: URL) {
        Database.database().reference().child("users").child(CurrentUser.uid).updateChildValues(["profileImage":url.absoluteString]) { (error, databaseRef) in
            guard error == nil else { return }
            self.removeOldStorageImage()
            CurrentUser.profileImage = url.absoluteString
            self.tableView.reloadData()
        }
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func removeOldStorageImage() {
        Storage.storage().reference(forURL: CurrentUser.profileImage).delete { (error) in
            guard error == nil else { return }
        }
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
}

extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        return headerView
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 { return 30 } else { return 0.1 }
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 1 } else { return 2 }
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            tableView.rowHeight = 100
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell") as! ProfileCell
            cell.emailLabel.text = CurrentUser.email
            cell.nameLabel.text = CurrentUser.name
            cell.profileImage.loadImage(url: CurrentUser.profileImage)
            cell.settingsVC = self
            return cell
        }else{
            tableView.rowHeight = 45
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell") as! SettingsCell
            let item = settingsItems[indexPath.row]
            let itemImg = settingsImages[indexPath.row]
            cell.settingsLabel.text = item
            cell.settingsImage.image = UIImage(named: itemImg)
            return cell
        }
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0{
            let controller = CurrentUserVC()
            show(controller, sender: self)
        }else{
            let item = settingsItems[indexPath.row]
            if item == "Appearance"{
                let controller = AppearanceVC()
                show(controller, sender: nil)
            }else{
                let controller = MapsSettingsVC()
                show(controller, sender: self)
            }
        }
    }
    
    // ---------------------------------------------------------------------------------------------------------------------------------------------------- //
    
}
