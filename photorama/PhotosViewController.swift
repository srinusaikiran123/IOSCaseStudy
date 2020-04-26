//
//  PhotosViewController.swift
//  photorama
//
//  Created by Joshua Vandermost on 2020-03-23.
//  Copyright © 2020 Joshua Vandermost. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    var store: PhotoStore!
    var imagesList = [Photo]()
    var nextIndex = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showUpdateImages()
        
        store.fetchInterestingPhotos{
            (photosResult) -> Void in
            switch photosResult {
            case let .success(photos):
                self.showUpdateImages()
                if let firstPicture = self.imagesList.first{
                    self.updateImageView(for: firstPicture)
                }
            case let .failure(error):
              print("Error in loading image from database")
            }
        }
        // Do any additional setup after loading the view.
    }
    
    func showUpdateImages(){
        store.fetchAllPhotos{
            (photosResult) -> Void in
            switch photosResult {
            case let .success(imagesList):
                self.imagesList = imagesList
            case let .failure(error):
                print("Error loading images")
            }
        }
    }
    
    @IBAction func nextImage(_ sender: UITapGestureRecognizer) {
     nextIndex+=1
        self.updateImageView(for: imagesList[nextIndex])
    }
    
    func updateImageView(for photo: Photo){
        store.fetchImage(for: photo) {
            (imageResult) -> Void in
            
            switch imageResult {
            case let .success(image):
                self.imageView.image = image
            case let .failure(error):
                print("Error downloading image: \(error)")
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
