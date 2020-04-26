//
//  FlickrAPI.swift
//  photorama
//
//  Created by Joshua Vandermost on 2020-03-23.
//  Copyright © 2020 Joshua Vandermost. All rights reserved.
//

import Foundation
import CoreData

enum FlickrError: Error {
    case invalidJSONData
}

enum Method: String{
    case interestingPhotos = "flickr.interestingness.getList"
}

/*
 A structure to allow all functionality specific to this API; this struct will be used before any request is sent to the server to format the url being sent.
 
 */

struct FlickrAPI{
    // the static keyword means that the variable/function can be accessed by class/structName.variable/function instead of object.variable/function
    private static let baseURLString = "https://api.flickr.com/services/rest"
    private static let apiKey = "35895c33203ed116364680d701f1b370"
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    /*
     flickerURL takes two parameters method and parameters.
     if you look above to the enum method, you'll notice that interestingPhotos has a url style string attribute. there could potentially be more variations of method, you would have to look in the documentation of Flickr
     */
    private static func flickrURL(method: Method, parameters: [String:String]?) -> URL {
        
        
        // URLComponents is a built in swift class that allows you to build a url to send as a request
        var components = URLComponents(string: baseURLString)
        
        var queryItems = [URLQueryItem]()
        
        let baseParams = [
            "method" : method.rawValue,
            "format" : "json",
            "nojsoncallback" : "1",
            "api_key" : apiKey
        ]
        
        for (key, value) in baseParams{
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        
        if let additionalParams = parameters {
            for (key, value) in additionalParams{
                let item = URLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
        }
        components?.queryItems = queryItems
        
        print("URLComponents: \(components?.url)")
        return (components?.url)!
    }
    
    // in this method we request the interesting Photo url
    static var interestingPhotosURL: URL{
        return flickrURL(method: .interestingPhotos, parameters: ["extras": "url_h,date_taken"])
    }
    
    /*
     photos takes 1 paramter data this will be passed in via the json format
     photos return a PhotosResult which is an enum from photoStore class
     */
    static func photos(fromJSON data: Data,
                       into context: NSManagedObjectContext) -> PhotosResult {
        do{
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard
                let jsonDictionary = jsonObject as? [AnyHashable:Any],
                let photos = jsonDictionary["photos"] as? [
            String:Any],
                let photosArray = photos["photo"] as? [[String:Any]] else {
                    return .failure(FlickrError.invalidJSONData)
            }
            
            var finalPhotos = [Photo]()
            for photoJSON in photosArray{
                if let photo = photo(fromJSON: photoJSON, into: context) {
                    finalPhotos.append(photo)
                }
            }
            
            if finalPhotos.isEmpty && !photosArray.isEmpty {
                return .failure(FlickrError.invalidJSONData)
            }
            return .success(finalPhotos)
        } catch let error {
            return .failure(error)
        }
    }
    
    /*
     Photo will have 1 paramter named json, this will be a dictionary with key String and value of Any
     it will return and optional Photo, which is a class created by us
     */
    private static func photo(fromJSON json: [String:Any],
                              into context: NSManagedObjectContext) -> Photo? {
        guard
            let photoID = json["id"] as? String,
            let title = json["title"] as? String,
            let dateString = json["datetaken"] as? String,
            let photoURLString = json["url_h"] as? String,
            let url = URL(string: photoURLString),
            let dateTaken = dateFormatter.date(from: dateString) else {
                return nil
        }
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "\(#keyPath(Photo.photoID)) == \(photoID)")
        fetchRequest.predicate = predicate
        
        var fetchedPhotos: [Photo]?
        context.performAndWait {
            fetchedPhotos = try? fetchRequest.execute()
                
            }
            if let existingPhoto = fetchedPhotos?.first {
                return existingPhoto
            }
        
        var photo: Photo!
    
    context.performAndWait {
            photo = Photo(context: context)
            photo.title = title
            photo.photoID = photoID
            photo.remoteURL = url as NSURL
            photo.dateTaken = dateTaken as NSDate as Date
        }
        return photo
    }

}
