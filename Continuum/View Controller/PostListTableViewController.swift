//
//  PostListTableViewController.swift
//  Continuum
//
//  Created by John Tate on 9/25/18.
//  Copyright © 2018 John Tate. All rights reserved.
//

import UIKit

class PostListTableViewController: UITableViewController, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    
    var isSearching: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
        // perform full sync when view first loaded
        performFullSync { (success) in
            
        }
        
        // perform update when posts changed by observing notification
        NotificationCenter.default.addObserver(self, selector: #selector(updateView), name: PostController.PostsChangedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // before searching, display all posts
        resultsArray = PostController.shared.posts
        tableView.reloadData()
    }

    @objc func updateView() {
        tableView.reloadData()
    }
    
    func performFullSync(completion: @ escaping (Bool) -> Void) {

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        PostController.shared.fetchPostsFromCloudKit { (posts) in

            if posts != nil {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.tableView.reloadData()
                }
            } else {
                self.presentAlertControllerWith(title: "error fetching posts", message: "Please troubleshoot fetching operation")
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
    // MARK: - Search Bar Functionality
    
    // results array for search function; optional don't have to initialize
    var resultsArray: [SearchableRecord]?
   
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        guard let searchText = searchBar.text else { return }
        let posts = PostController.shared.posts
        
        // iterate through text from posts and return an array of those that match the search
        let filteredPosts = posts.filter{ $0.matches(searchTerm: searchText) }
        let results = filteredPosts.compactMap{ $0 as SearchableRecord}
        resultsArray = results
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.text = ""
        searchBar.resignFirstResponder()
        resultsArray = PostController.shared.posts
        tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearching = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isSearching = false
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      
        // could use ternary operator here instead
        if isSearching {
            return resultsArray?.count ?? 0
        } else {
            return PostController.shared.posts.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as? PostTableViewCell
        
        let dataSource = isSearching ? resultsArray : PostController.shared.posts
        let post = dataSource?[indexPath.row]
        cell?.post = post as? Post
        return cell ?? UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 400
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPostDetailVC" {
                let destinationVC = segue.destination as? PostDetailTableViewController
            guard let indexPath = tableView.indexPathForSelectedRow else { return }
            let post = PostController.shared.posts[indexPath.row]
            destinationVC?.post = post
        }
    }
}
