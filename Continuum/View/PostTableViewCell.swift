//
//  PostTableViewCell.swift
//  Continuum
//
//  Created by John Tate on 9/25/18.
//  Copyright © 2018 John Tate. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {

    // MARK: - IBOutlets
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var captionText: UILabel!
    @IBOutlet weak var commentCount: UILabel!
   
    var post: Post? {
        didSet {
            updateViews()
        }
    }
    
    func updateViews() {
        
        guard let post = post else { return }
        
        PostController.shared.fetchComments(for: post) { (success) in
            if success {
                DispatchQueue.main.async {
                    self.commentCount.text = "\(post.comments.count)"
                }
            }
        }
    
        photoImageView.image = post.photo
        captionText.text = post.caption
    }
}
