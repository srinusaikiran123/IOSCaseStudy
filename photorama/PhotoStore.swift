//
//  PhotoStore.swift
//  photorama
//
//  Created by Joshua Vandermost on 2020-03-23.
//  Copyright © 2020 Joshua Vandermost. All rights reserved.
//


/*
 this file contains a few important enums for error checking and a class named PhotoStore that we will be using to retreive and store all the information about the photos
 */
import UIKit
import CoreData

enum ImageResult {
    case success(UIImage)
    case failure(Error)
}

enum PhotoError: Error {
    case imageCreationError
}

enum PhotosResult{
    case success([Photo])
    case failure(Error)
}

class PhotoStore{
    /*
     sessions are apples way of allowing us to comunicate with web services
     */
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Photorama")
        container.loadPersistentStores { (description,error) in
            if let error = error {
                print("Error setting up Core Data (\(error)).")
            }
        }
        return container
    }()
    
    /*
     fetchInterestingPhotos will do exactly like the name implies it will get interesting photos
     it only has one parameter and does not return anything
     the parameter is a function that accepts a PhotoResult enum... this will make more sense when we call the fetchInterestingPhotos function.
     */
    func fetchInterestingPhotos(completion: @escaping (PhotosResult) -> Void){
        // since we used static with the interestingPhotosURL variable name we are able to use it by applying the . method on the class name instead of instantiating an object. (this is an optimization technique)
        let url = FlickrAPI.interestingPhotosURL
        // URLRequest is a built in swift class it will format the url for you with all the necessary policies (readMore: https://developer.apple.com/documentation/foundation/urlrequest)
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) {
            // this is a closure statement, it is much like an annonamous function. dataTask requires a second parameter named completionHandler of type (data, response, error) -> Void. since this is a function we can instead use a closure
            (data, response, error) -> Void in
            
            var result = self.processPhotosRequest(data: data, error: error)
            
            if case.success = result {
                do{
                    try self.persistentContainer.viewContext.save()
                } catch let error {
                    result = .failure(error)
                }
            }
            OperationQueue.main.addOperation {
                completion(result)
            }
            
        }
        task.resume()
    }
    
    // this function will fetch the image in question, the above function will allow you to retreive information about lots of images, but not the actual image, only where to find it.
    func fetchImage(for photo: Photo, completion: @escaping (ImageResult) -> Void){
        guard let photokey = photo.photoID else {
            preconditionFailure("Photo expected to have a photoID.")
        }
        guard let photoURL = photo.remoteURL else{
            preconditionFailure("Photo expected to have a remote URL")
        }
        let request = URLRequest(url: photoURL as URL)
        
        let task = session.dataTask(with: request){
            (data, response, error) -> Void in
            
            let result = self.processImageRequest(data: data, error: error)
            OperationQueue.main.addOperation{
                completion(result)
            }
        }
        task.resume()
    }
    
    func fetchAllPhotos(completion: @escaping (PhotosResult) -> Void) {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortByDateTaken = NSSortDescriptor(key: #keyPath(Photo.dateTaken),
                                                ascending: true)
        fetchRequest.sortDescriptors = [sortByDateTaken]
        
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                let allPhotos = try viewContext.fetch(fetchRequest)
                completion(.success(allPhotos))
            }catch {
                completion(.failure(error))
            }
        }
    }
    
    // after the above function returns it will have the image data, that we will have to process into a visible image
    private func processImageRequest(data: Data?, error: Error?) -> ImageResult{
        guard
            let imageData = data,
            let image = UIImage(data: imageData) else {
                if data == nil {
                    return .failure(error!)
                } else {
                    return .failure(PhotoError.imageCreationError)
                }
        }
        return .success(image)
    }
    
    // this is used to serialize the initial incoming interestinghotos json file
    private func processPhotosRequest(data: Data?, error: Error?) -> PhotosResult{
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return FlickrAPI.photos(fromJSON: jsonData,
                                into: persistentContainer.viewContext)
    }
}
