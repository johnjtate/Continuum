//
//  AddPostTableViewController.swift
//  Continuum
//
//  Created by John Tate on 9/25/18.
//  Copyright © 2018 John Tate. All rights reserved.
//

import UIKit

class AddPostTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - IBOutlet
    @IBOutlet weak var captionTextField: UITextField!
    
    var photo: UIImage?
    
    // MARK: - Lifecycle Functions
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // blank out caption text field
        captionTextField.text = ""
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      
        if segue.identifier == "toPhotoSelectVC" {
            guard let destinationVC = segue.destination as? PhotoSelectViewController else { return }
            destinationVC.delegate = self
        }
    }
    
    // MARK: - IBActions

    @IBAction func addPostButtonTapped(_ sender: Any) {
        guard let image = photo, let caption = captionTextField.text, !caption.isEmpty else { return }
        PostController.shared.createPostWith(image: image, caption: caption) { (post) in
            
        }
        // navigate back to the Post List Table View Controller
        self.tabBarController?.selectedIndex = 0
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        // navigate back to the Post List Table View Controller
        self.tabBarController?.selectedIndex = 0
    }
}

extension AddPostTableViewController: PhotoSelectViewControllerDelegate {
    
    func photoSelected(_ photo: UIImage) {
        self.photo = photo
    }
}
