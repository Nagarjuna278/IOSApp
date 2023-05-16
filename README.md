This repository contains an iOS app built with SwiftUI and MapKit.

Term Project CSC 780

Nagarjuna Reddy Guntaka

Project Idea:

A User can access the available local radio stations from anywhere in the world by tapping on the Radio Stations marks on the map.

The final UI looks like this :
![Alt Text](https://drive.google.com/file/d/1MblsctdjAtrMDsvi3yX32pHBQui6TyCH/preview)

##Project Struture

The project consists of the following files:

- ChannelView.swift
- ContentView.swift
- RadioMap.swift
- RadioPlayer.swift
- SearchMap.swift
- TermProjectApp.swift

RadioMap.swift : 

    Geo struct: Represents geographical information obtained from a JSON response. It includes properties such as eu, country_code, region_code, latitude, longitude, and city. It adopts the Decodable and Identifiable protocols.

    Place struct: Represents a place object obtained from a JSON response. It includes properties such as apiVersion, version, and data. The Data struct inside Place contains an array of Coord objects and a version property. Both Place and Data structs adopt the Decodable protocol.

    Coord struct: Represents coordinate information for a place. It includes properties such as id, geo, url, size, boost, title, and country. It adopts the Decodable and Identifiable protocols.

    PlacesAPI class: Manages the API requests to retrieve geographical information and places. It includes a place property that stores the retrieved place data and publishes updates using @Published. The class includes two methods:

        getGeo(completion:): Sends an API request to retrieve geographical information and calls the completion closure with the decoded Geo object.
        fetchPlaces(completion:): Sends an API request to retrieve places and calls the completion closure with the decoded Place object.
    
            The code makes use of the URLSession.shared.dataTask method to perform the network requests and the JSONDecoder class for JSON decoding.

RadioPlayer.swift :
    
    RadioPlayer class that handles playing radio stations by creating an AVPlayer instance
    
    RadioPlayer class: Acts as a radio player and conforms to the ObservableObject protocol. It includes a method called getRadioStation(stationId:) that takes a station ID as input and returns an AVPlayer instance.

    getRadioStation(stationId:): Creates an AVPlayer instance with the URL of the radio station. The URL is constructed using the provided station ID by appending it to the base URL. If the URL cannot be created, nil is returned. The URL is then used to initialize the AVPlayer, which is returned.
    The code relies on the AVFoundation framework and utilizes the AVPlayer and URL classes for playing audio from the specified radio station URL.


ChannelsView.swift 

    LocalRegion struct and a ChannelsViewAPI class for fetching channel data from a specific place
    
    LocalRegion struct: Represents a local region and conforms to the Decodable protocol. It includes properties for the API version, version, and data.

    Data struct: Represents the data contained within the local region, including properties for content, map, type, count, utcOffset, subtitle, and url.

    Channels struct: Represents the channels within the local region's content. It includes properties for itemsType, type, and items.

    ChannelData struct: Represents the data for an individual channel. It includes properties for the channel's ID, href, and title.
    ChannelsViewAPI class: Handles fetching channel data from a specific place. It includes a method called getChannels(placeId:completion:) that takes a place ID as input and a completion closure to handle the fetched LocalRegion data.

    getChannels(placeId:completion:): Constructs the URL using the provided place ID and makes a network request to fetch the channel data. Upon receiving the data, it is decoded into a LocalRegion instance using a JSON decoder. The decoded data is then passed to the completion closure for further processing.
    The code relies on the URLSession and JSONDecoder classes for making network requests and decoding JSON data.

SearchMap.swift :

    includes a struct and a class related to searching and displaying map locations in SwiftUI.
    
    SearchMap struct: Represents a map item obtained from a search result. It includes properties for the item's ID, a private MKMapItem instance, a computed property for the item's center coordinate, and a computed property for the item's name.

    SearchResultsViewModel class: Manages the search results and region for map locations. It is an ObservableObject, meaning it can be used with SwiftUI's @Published property wrapper to automatically update views when the published properties change.

    searchPlaces: An array of SearchMap instances representing the search results.

    region: The current map region.

    search(text:region:) method: Performs a search for map items based on the provided text and region. It constructs an MKLocalSearch.Request with the specified search text and region, then performs the search using MKLocalSearch. Upon receiving the search response, the method updates the searchPlaces property with the map items from the response.

    The code relies on the MapKit framework to handle map-related operations and searching for map items.


ContentView.swift :
    
    The ContentView struct represents the main view of the app.
    It includes several state variables for managing the map, search functionality, radio player, and channel selection.
    The view contains a search bar and a magnifying glass button for toggling the search view.
    The map is displayed using Map and annotations are added using MapAnnotation.
    Tapping on an annotation triggers the handleTapOnMap function, which retrieves channels for the selected place and starts playing a radio station.
    The view also includes controls for managing radio playback (play, pause, stop, previous, next).
    The MapViewDelegate class implements the MKMapViewDelegate protocol and customizes the appearance of the map annotations.
    Helper functions like fetchPlaces, showMinDistance, and filterVisibleCoords are used for fetching and filtering map coordinates.
    The code uses various frameworks, including SwiftUI, MapKit, and AVFoundation.


The ContentView fetches the coordinates of the current user location using the getGeo function call and retrieves all the coordinates of the local areas that have radio stations using the fetchPlaces function call. It then finds the nearest local place to the user's location and uses that as the initial radio player.

Once the map displays all the coordinates where there are one or multiple radio stations, tapping on a marker at those coordinates calls the ChannelsView function and plays the first radio station using the AVFoundation AVPlayer function.

If a user wants to jump to a specific location, they can search for the place using the search bar at the top.


