This repository contains an iOS app built with SwiftUI and MapKit.

Term Project CSC 780

Nagarjuna Reddy Guntaka

Project Idea:

A User can access the available local radio stations from anywhere in the world by tapping on the Radio Stations marks on the map.

The final UI looks like this :
https://drive.google.com/file/d/1MblsctdjAtrMDsvi3yX32pHBQui6TyCH/view

##Project Struture

The project consists of the following files:

- ChannelView.swift
- ContentView.swift
- RadioMap.swift
- RadioPlayer.swift
- SearchMap.swift
- TermProjectApp.swift


##Algorithm:
    
-    Displays only the coordinates which are in Visible region.
-    Displays the nearest 15 coordinates in the Map Visible Region and 35 random coordinates on the Visible region
-    On Startup, the algorithm chooses the coordinate which is nearest to the center and plays the available radioStations 


The ContentView fetches the coordinates of the current user location using the getGeo function call and retrieves all the coordinates of the local areas that have radio stations using the fetchPlaces function call. It then finds the nearest local place to the user's location and uses that as the initial radio player.

Once the map displays all the coordinates where there are one or multiple radio stations, tapping on a marker at those coordinates calls the ChannelsView function and plays the first radio station using the AVFoundation AVPlayer function.

If a user wants to jump to a specific location, they can search for the place using the search bar at the top.

API Source:

https://jonasrmichel.github.io/radio-garden-openapi/


