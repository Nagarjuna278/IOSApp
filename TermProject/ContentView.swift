import SwiftUI
import MapKit
import AVFoundation

struct ContentView: View {
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40, longitude: 120), span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
    @StateObject private var placesAPI = PlacesAPI()
    @State private var coords = [Place.Data.Coord]()
    
    @StateObject private var channelsView = ChannelsViewAPI()
    
    @State private var channelsData : [String : LocalRegion.Data] = [:]
    
    private let mapViewDelegate = MapViewDelegate()
    
    @StateObject private var radioplayer = RadioPlayer()
    
    @State private var player : AVPlayer?
    
    @State private var channelList : [String: Int] = [:]
    @State private var MaxChannelList : [String : Int] = [:]
    
    @State private var playerItem: AVPlayerItem?
    
    @State private var nearestCoordinate : Place.Data.Coord? = nil
    
    @State private var currentCoord: Place.Data.Coord? = nil
    
    @State private var is_playing : Bool = false
    @State private var pause_station : Bool = false
    
    @State private var currentPlace : String = ""
    
    @State var currentTitle : String = ""
    
    @State var currentItemId : String = ""
    
    @State var isSelected : Bool = false
    @State var search : Bool = false
    
    @State private var searchText = ""
    @StateObject private var searchMap = SearchResultsViewModel()

    
    @State private var coordscopy = [Place.Data.Coord]()
    var body: some View {
        HStack(alignment: .top){
            if search {
                NavigationView {
                    ZStack{
                        if searchMap.searchPlaces.isEmpty {
                            
                        } else {
                            List(searchMap.searchPlaces) { place in
                                Text(place.name)
                                    .onTapGesture {
                                        region.center = place.center
                                        searchMap.searchPlaces = []
                                        search = false
                                    }
                            }
                        }
                    }.searchable(text: $searchText)
                        .onChange(of: searchText, perform: { searchText in
                            
                            if !searchText.isEmpty {
                                searchMap.search(text: searchText, region: region)
                                
                            } else {
                                searchMap.searchPlaces = []
                                search = false
                            }
                        })
                }
                .frame(height: searchText.isEmpty ? 100 : .infinity)
            } else {
                Text("Search for places")
            }
            
            Image(systemName: "magnifyingglass")
                .onTapGesture {
                    search.toggle()
                }
                //.frame(alignment: .topTrailing)
        
        }
        
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, annotationItems: coords) { item in
                //Marks the elements in coords on the map
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: item.geo[1], longitude: item.geo[0])) {
                    // created a button
                    Button(action: {
                        handleTapOnMap(item: item)
                    }){
                        Image(systemName: "mappin")
                            .resizable()
                            .frame(width: 10, height: 20)
                            .foregroundColor(.red)
                    }
                    //Text("\(item.title) \(item.id)")
                }
            }
            .onAppear{
                fetchPlaces()
            }
            .onChange(of: region) { _ in
                filterVisibleCoords()
                print(isSelected)
                searchMap.searchPlaces = []
                print(searchMap.searchPlaces)
            }
            .ignoresSafeArea()
            .tint(.blue)
            
            if is_playing {
                RoundedRectangle(cornerRadius: 20)
                    .fill().opacity(0.5)
                    .foregroundColor(.black)
                    .frame(height: 180)
                    .edgesIgnoringSafeArea(.all)
            }
            VStack {
                if is_playing {
                    VStack{
                        Text("\(currentTitle)")
                            .font(.system(size: 28))
                        Text("\(currentPlace)")
                    }
                    .padding(.bottom).padding(10)
                    Spacer(minLength: 5)
                    .foregroundColor(.white)
                    HStack {
                        Button(action : {
                            prevRadioStation()
                        }){
                            Image(systemName: "backward.frame.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                
                        }
                        if pause_station == false {
                            Button(action : {
                                pauseRadio()
                            }){
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Button(action : {
                                pauseAndPlay()
                            }){
                                Image(systemName: "play.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                        }
                        Button(action: {
                            stopRadio()
                        }){
                            Image(systemName: "square.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        Button(action : {
                            nextRadioStation()
                        }){
                            Image(systemName: "forward.frame.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                    }
                    
                }
            }
            .frame(height : 100)
            .padding(.bottom).padding(40)
            .edgesIgnoringSafeArea(.all)
            
        }
        
        .edgesIgnoringSafeArea(.all)
    }
    
    private func nextRadioStation(){
        stopRadio()
        channelList[currentItemId] = ((channelList[currentItemId] ?? 0 )+1) % (MaxChannelList[currentItemId] ?? 1)
        playRadio()
    }
    
    private func prevRadioStation(){
        stopRadio()
        channelList[currentItemId] = ((channelList[currentItemId] ?? 0 )-1) % (MaxChannelList[currentItemId] ?? 1)
        playRadio()
    }
    
    
    private func pauseRadio(){
        player?.pause()
        pause_station = true
    }
    
    private func pauseAndPlay(){
        player?.play()
        pause_station = false
    }
    
    private func stopRadio(){
        isSelected = false
        player?.seek(to: CMTime.zero)
        player?.pause()
        is_playing = false
        pause_station = false
    }
    
    private func playRadio(){
        stopRadio()
        let substr : String = channelsData[currentItemId]!.content.first?.items[channelList[currentItemId] ?? 0].href.components(separatedBy: "/").last ?? ""
        
        currentTitle = channelsData[currentItemId]?.content.first?.items[channelList[currentItemId] ?? 0].title ?? ""
        
        print(currentTitle)
        print(currentItemId)
        print(channelsData[currentItemId]?.count ?? 0)
        player = radioplayer.getRadioStation(stationId: substr)
        player?.play()
        is_playing = true
        pause_station = false
    }
    
    private func handleTapOnMap(item : Place.Data.Coord) {
        
        
        channelList[item.id] = 0
        
        currentPlace = item.title
        
        player?.seek(to: CMTime.zero)
        player?.pause()

        channelsView.getChannels(placeId: item.id) { localRegion in
            print(localRegion, " handleTap")
            channelsData[item.id] = localRegion.data;
            
            currentItemId = item.id;
            
            region.center = CLLocationCoordinate2D(latitude: item.geo[1], longitude: item.geo[0])
            
            MaxChannelList[currentItemId] = localRegion.data.count
            
            playRadio()
            
            isSelected = true
            
        }
        
        
    }
    
    
    private func fetchPlaces() {
        let map = MKMapView.appearance()
                        //map.cameraZoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 1000000)
        
        placesAPI.getGeo { geo in
            region.center = CLLocationCoordinate2D(latitude: geo.latitude, longitude: geo.longitude)
        }
        placesAPI.fetchPlaces { place in
            coordscopy = place.data.list
            filterVisibleCoords()
            showMinDistance()
            map.delegate = mapViewDelegate
            
        }
        
    }
    
    private func showMinDistance() {
        
        var shortestDistance: CLLocationDistance = Double.infinity
        
        if(coords.count>0){
            
            nearestCoordinate = coords.first
            
            for coord in coords {
                let distance = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude).distance(from: CLLocation(latitude: coord.geo[1], longitude: coord.geo[0]))
                
                if distance < shortestDistance {
                    shortestDistance = distance
                    nearestCoordinate = coord
                }
            }
            
            //handleTapOnMap(item: nearestCoordinate!)
            
            region.center = CLLocationCoordinate2D(latitude: nearestCoordinate!.geo[1], longitude: nearestCoordinate!.geo[0])
            
            handleTapOnMap(item: nearestCoordinate!)
        }
    }
    
    private func filterVisibleCoords() {
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        

        coords = coordscopy.filter { coord in
            let lat = coord.geo[1]
            let lon = coord.geo[0]
            return (minLat...maxLat).contains(lat) && (minLon...maxLon).contains(lon)
        }
        
        coords = coords.sorted(by: { coord1, coord2 in
            let center = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
            let coord1Location = CLLocation(latitude: coord1.geo[1], longitude: coord1.geo[0])
            let coord2Location = CLLocation(latitude: coord2.geo[1], longitude: coord2.geo[0])
            return center.distance(from: coord1Location) < center.distance(from: coord2Location)
        })
         
        
        
        
        if coords.count>50 {
            let randomcoords = Array(coords.suffix(coords.count - 15).shuffled().prefix(35))
            coords.remove(atOffsets: IndexSet(integersIn: 15...coords.count))
            randomcoords.forEach { coord in
                coords.append(coord)
            }
        }
        
        print(coords.count)
    }
}


extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        return lhs.center == rhs.center && lhs.span == rhs.span
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension MKCoordinateSpan: Equatable {
    public static func == (lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool {
        return lhs.latitudeDelta == rhs.latitudeDelta && lhs.longitudeDelta == rhs.longitudeDelta
    }
}

class MapViewDelegate: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        // Customize the annotation view
        annotationView?.canShowCallout = true
        annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        // Return the annotation view
        return annotationView
    }
}

