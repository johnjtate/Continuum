//
//  PostDetailTableViewController.swift
//  Continuum
//
//  Created by John Tate on 9/25/18.
//  Copyright © 2018 John Tate. All rights reserved.
//

import UIKit

class PostDetailTableViewController: UITableViewController {

    // MARK: - IBOutlet
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var followPostButton: UIButton!
    
    
    // landing pad for segue
    var post: Post? {
        didSet {
            loadViewIfNeeded()
            updateViews()
        }
    }
    
    // MARK: - DateFormatter
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    func updateViews() {
        guard let post = post else { return }
        photoImageView.image = post.photo
        
        // toggle text on Follow/Unfollow button
        PostController.shared.checkForSubscription(to: post) { (isSubscribed) in
            DispatchQueue.main.async {
                // text needs to read the opposite of isSunscribed
                let buttonTitle = isSubscribed ? "Unfollow" : "Follow"
                self.followPostButton.setTitle(buttonTitle, for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let post = post else { return }
        PostController.shared.fetchComments(for: post) { (success) in
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return post?.comments.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath)
        let comment = post?.comments[indexPath.row]
        cell.textLabel?.text = comment?.text
        if let timestamp = comment?.timestamp {
            cell.detailTextLabel?.text = dateFormatter.string(from: timestamp)
        }
        return cell
    }
    
    // MARK: - Comment Alert Controller
    func presentCommentAlertController() {
        
        let commentAlert = UIAlertController(title: "Leave a Comment", message: "How do you feel about this post?", preferredStyle: .alert)
        commentAlert.addTextField { (commentTextField) in
            commentTextField.placeholder = "Write your comment here"
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
            
            // had to change guard let to guard var due to setting commentText = comment.text below
            guard var commentText = commentAlert.textFields?[0].text, let post = self.post else { return }
            // guard against empty comment
            guard !commentText.isEmpty else { return }
            PostController.shared.addComment(text: commentText, to: post, completion: { (comment) in
                DispatchQueue.main.async {
                    guard let comment = comment else { return }
                    commentText = comment.text
                    self.tableView.reloadData()
                }
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        commentAlert.addAction(okAction)
        commentAlert.addAction(cancelAction)
        
        present(commentAlert, animated: true)
    }
        
    // MARK: - IBActions
    @IBAction func commentButtonTapped(_ sender: Any) {
        presentCommentAlertController()
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        
        guard let post = post, let photo = post.photo else { return }
        let activityViewController = UIActivityViewController(activityItems: [photo, post.caption], applicationActivities: nil)
        DispatchQueue.main.async {
            self.present(activityViewController, animated: true)
        }
    }
    
    @IBAction func followPostButtonTapped(_ sender: Any) {
        
        guard let post = post else { return }
        PostController.shared.toggleSubscriptionTo(commentsForPost: post) { (success, error) in
            
            if let error = error {
                print("There was an error in \(#function) ; \(error)  ; \(error.localizedDescription)")
                return
            }
            
            if success {
                DispatchQueue.main.async {
                    self.updateViews()
                }
            }
        }
    }
}
