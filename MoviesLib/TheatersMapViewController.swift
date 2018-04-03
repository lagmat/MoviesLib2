//
//  TheatersMapViewController.swift
//  MoviesLib
//
//  Created by Usuário Convidado on 02/04/18.
//  Copyright © 2018 EricBrito. All rights reserved.
//

import UIKit
import MapKit

class TheatersMapViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Properties
    var currentElement: String!
    var theater: Theater!
    var theaters: [Theater] = []
    lazy var locationManager = CLLocationManager()
    var poiAnnotations: [MKPointAnnotation] = []
    
    
    // MARK: - Super Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        loadXML()
        reqstUserLocationAutorization()
    }
    
    // MARK: - Methods
    func loadXML() {
        guard let xml = Bundle.main.url(forResource: "theaters", withExtension: "xml"), let xmlParser = XMLParser(contentsOf: xml) else {return}
        xmlParser.delegate = self
        xmlParser.parse()
    }
    
    func addTheaters() {
        for theater in theaters {
            let coordinate = CLLocationCoordinate2D(latitude: theater.latitude, longitude: theater.longitude)
            
            let annotation = TheaterAnnotation(coordinate: coordinate, title: theater.name, subtitle: theater.address)
            
            mapView.addAnnotation(annotation)
        }
        
        mapView.showAnnotations(mapView.annotations, animated: true)
        
    }
    
    func reqstUserLocationAutorization() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            //locationManager.allowsBackgroundLocationUpdates = true
            
            locationManager.pausesLocationUpdatesAutomatically = true
            
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                
                print("Isuário já autorizou o uso da localização!")
                
            case.denied:
                print("Usuário negou a autorização")
                
            case.notDetermined:
                locationManager.requestWhenInUseAuthorization()
                
            case.restricted:
                print("Siful!")
            }
        }
    }
}

// MARK: - XMLParserDelegate
extension TheatersMapViewController: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        currentElement = elementName
        
        if elementName == "Theater" {
            theater = Theater()
        }
        
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        print(string)
        
        let content = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty {
            switch currentElement {
            case "name":
                theater.name = content
            case "address":
                theater.address = content
            case "latitude":
                theater.latitude = Double(content)!
            case "longitude":
                theater.longitude = Double(content)!
            case "url":
                theater.url = content
            default:
                break
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "Theater" {
            theaters.append(theater)
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        addTheaters()
    }
    
}

//MARK: - MKMapViewDelegate
extension TheatersMapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationview: MKAnnotationView!
        if annotation is TheaterAnnotation {
          
         annotationview = mapView.dequeueReusableAnnotationView(withIdentifier: "Theater")
            
            if annotationview == nil {
                annotationview = MKAnnotationView(annotation: annotation, reuseIdentifier: "Theater")
                annotationview.image = UIImage(named: "theatericon")
                annotationview.canShowCallout = true
            
            } else {
                annotationview.annotation = annotation
                
            }
        }
    return annotationview
    
   }
    
}

extension TheatersMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
        default:
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("Velocidade do usuário: \(userLocation.location?.speed ?? 0)")
        
        //let regio = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 500, 500)
        //mapView.setRegion(regio, animated: true)
    }
}

extension TheatersMapViewController: UISearchBarDelegate {
    func  searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text!
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error == nil {
                guard let response = response else {return}
                self.mapView.removeAnnotation(self.poiAnnotations as! MKAnnotation)
                self.poiAnnotations.removeAll()
                for item in response.mapItems {
                    let place = MKPointAnnotation()
                    place.coordinate = item.placemark.coordinate
                    place.title = item.name
                    place.subtitle = item.phoneNumber
                    self.poiAnnotations.append(place)
                }
                self.mapView.addAnnotations(self.poiAnnotations)
            }
        }
    }
}



