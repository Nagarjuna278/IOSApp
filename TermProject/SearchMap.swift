import SwiftUI
import MapKit

struct AnnotationItem: Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct SearchMap : Identifiable {
    
    let id=UUID()
    private var mapItem: MKMapItem
    
    init(mapItem: MKMapItem){
        self.mapItem = mapItem
    }
    
    var center : CLLocationCoordinate2D{ CLLocationCoordinate2D(latitude : mapItem.placemark.coordinate.latitude , longitude: mapItem.placemark.coordinate.longitude)
    }
    var name: String {
        mapItem.name ?? ""
    }
}

class SearchResultsViewModel: ObservableObject {
    
    @Published var searchPlaces = [SearchMap]()
    @Published var region = MKCoordinateRegion()

    func search(text: String, region: MKCoordinateRegion){
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = text
        searchRequest.region = region
        
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unkonown error")")
                return
            }
            
            self.searchPlaces = response.mapItems.map(SearchMap.init)
        }
    }
}
