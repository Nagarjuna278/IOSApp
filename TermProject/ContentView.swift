import SwiftUI
import MapKit
import AVFoundation

struct ContentView: View {
    
    //Map Visible region
    @State var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40, longitude: 120), span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
    
    //fetchPlacesAPI to get the locations
    @StateObject private var placesAPI = PlacesAPI()
    @State private var coords = [Place.Data.Coord]()
    
    //Channels of a particular location
    @StateObject private var channelsView = ChannelsViewAPI()
    @State private var channelsData : [String : LocalRegion.Data] = [:]
    
    //MapViewDelegate
    private let mapViewDelegate = MapViewDelegate()
    
    //RadioPlayer for a particular channel
    @StateObject private var radioplayer = RadioPlayer()
    @State private var player : AVPlayer?
    @State private var playerItem: AVPlayerItem?
    
    //Variables to keep the track of radio station of a particular location
    @State private var channelList : [String: Int] = [:]
    @State private var MaxChannelList : [String : Int] = [:]
    
    
    //nearest coordinate to play on the startup
    @State private var nearestCoordinate : Place.Data.Coord? = nil
    
    //current coord of the radiostation playing
    @State private var currentCoord: Place.Data.Coord? = nil
    
    //Information to display the current radioStatoin content
    @State private var is_playing : Bool = false
    @State private var pause_station : Bool = false
    @State private var currentPlace : String = ""
    @State var currentTitle : String = ""
    @State var currentItemId : String = ""
    
    //used for search function
    @State var isSelected : Bool = false
    @State var search : Bool = false
//    @State private var searchText = ""
    @StateObject private var searchMapViewModel = SearchResultsViewModel()

    
    @State private var coordscopy = [Place.Data.Coord]()
    
    
    var radioView: some View {
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
    
    
    
    var searchMapView: some View {
        HStack(alignment: .top){
            if search {
                NavigationStack {
                    ZStack{
                        if search {
                            List(searchMapViewModel.searchPlaces) { place in
                                Text(place.name)
                                    .onTapGesture {
                                        region.center = place.center
                                        searchMapViewModel.searchPlaces = []
                                        search = false
                                    }
                            }
                        }
                    }
                    .searchable(text: $searchMapViewModel.searchText)
                    .onChange(of: searchMapViewModel.searchText, perform: { searchText in
                        
                        if !searchText.isEmpty {
                            searchMapViewModel.search(text: searchText, region: region)
                            
                        } else {
                            searchMapViewModel.searchPlaces = []
                            search = false
                        }
                    })
                }
                .frame(height: searchMapViewModel.searchPlaces.isEmpty ? 100 : 400)
                .navigationTitle("Search Places")
                //.frame(height: searchText.isEmpty ? 100 : .infinity )
            }
            if !search {
    
                Text("Search Places")
                    .font(.system(size: 22)).bold()
                    .padding(.horizontal).padding().frame(width: 300)
                    .background(.black).opacity(0.5)
                    .foregroundColor(.white)
                    .onTapGesture {
                        search = true
                    }
            }
        }
    }
    
    
    var body: some View {
        
        
        //Map
        ZStack(alignment: .top){
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $region, annotationItems: coords) { item in
                    //Marks the elements in coords on the map
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: item.geo[1], longitude: item.geo[0])) {
                        // A button to click on the location to start the radio
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
                }
                .ignoresSafeArea()
                .tint(.blue)
                
                
                if is_playing {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill().opacity(0.5)
                            .foregroundColor(.black)
                            .frame(height: 180)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack {
                            VStack{
                                Text("\(currentTitle)")
                                    .font(.system(size: 28))
                                Text("\(currentPlace)")
                            }
                            .padding(.bottom).padding(10)
                            Spacer(minLength: 5)
                                .foregroundColor(.white)
                            
                            radioView
                            
                        }
                        .frame(height : 100)
                        //                    .padding(.bottom).padding(40)
                        .edgesIgnoringSafeArea(.all)
                    }
                }
                
            }
            ZStack{
                searchMapView
                    .cornerRadius(5)
                    .foregroundColor(.black)
                    .cornerRadius(20)
                    .padding(.top).padding(40)
            }
        }
        
        .edgesIgnoringSafeArea(.all)
    }
    
    //To play the next Station
    private func nextRadioStation(){
        stopRadio()
        channelList[currentItemId] = ((channelList[currentItemId] ?? 0 )+1) % (MaxChannelList[currentItemId] ?? 1)
        playRadio()
    }
    
    //previous Station of current location
    private func prevRadioStation(){
        stopRadio()
        if channelList[currentItemId] == 0 {
            channelList[currentItemId] = MaxChannelList[currentItemId]!-1
        } else {
            channelList[currentItemId] = channelList[currentItemId]! - 1
        }
        playRadio()
    }
    
    //pause the current radio station
    private func pauseRadio(){
        player?.pause()
        pause_station = true
    }
    
    //play the current radio station
    private func pauseAndPlay(){
        player?.play()
        pause_station = false
    }
    
    //stop the current radio station
    private func stopRadio(){
        isSelected = false
        player?.seek(to: CMTime.zero)
        player?.pause()
        is_playing = false
        pause_station = false
    }
    
    //play the radio
    private func playRadio(){
        stopRadio()
        print(currentItemId)
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
    
    //OnTap playing a location radio
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
    
    //fetches the places and plots the coordinates on the map
    private func fetchPlaces() {
        
        let map = MKMapView.appearance()
                        
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
    
    //Finds the coordinate which is nearest to the region center
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
    
    //Filtering the coordinates which are only visible
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
        
        //sorting the coordinates based on the distance from the center
        coords = coords.sorted(by: { coord1, coord2 in
            let center = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
            let coord1Location = CLLocation(latitude: coord1.geo[1], longitude: coord1.geo[0])
            let coord2Location = CLLocation(latitude: coord2.geo[1], longitude: coord2.geo[0])
            return center.distance(from: coord1Location) < center.distance(from: coord2Location)
        })
         
        
        
        //taking the 15 coordinates from the center and the remaining 35 random coordinates
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

