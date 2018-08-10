//
//  ViewController.swift
//  WhatFlower
//
//  Created by Aaron John on 6/13/18.
//  Copyright © 2018 Aaron John. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire    //Using Alamofire to make HTTP Get requests to wikipedia's API or any other API for that matter
import SwiftyJSON   //Using SwiftyJSON to Parse the JSON data recieved by Alamofire...  so that we can grab data to display in app
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()  //UIImagePickerController
    
    @IBOutlet weak var imageView: UIImageView!   //UIImagePickerController
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let userPickedImage = info[UIImagePickerControllerEditedImage] as? UIImage { //UIImagePickerController
        
            guard let convertedCIImage = CIImage(image: userPickedImage) else {  //turns UIImage to CIImage
                fatalError("Could not convert image to CIImage.")
            }
            
            //imageView.image = userPickedImage  //UIImagePickerController
            
         
            detect(image: convertedCIImage)  //coreImage Image
        }
        
        imagePicker.dismiss(animated: true, completion: nil)   //UIImagePickerController
    }
    
    func detect(image: CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else{
            fatalError("Cannot import model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let classification = request.results?.first as? VNClassificationObservation else{
                    fatalError("Could not classify image ")
            }
            
            self.navigationItem.title = classification.identifier.capitalized //identifier is a string that describes what the classification was
            
            self.requestInfo(flowerName: classification.identifier)
            
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        }
        
        catch{
            print(error)
        }
        
    }
    
    func requestInfo(flowerName: String){
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess{
                print("Got the wikipedia info")
                print(response)

                 let flowerJSON : JSON = JSON(response.result.value!) //Contains JSON Object and this will be parsed using SwiftyJSON library
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue

                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string : flowerImageURL)) //Using SDWebImage to set UIImageView image to an URL
                
                self.label.text = flowerDescription
                
            }
        }
    
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    

}

