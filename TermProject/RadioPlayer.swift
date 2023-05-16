//
//  RadioPlayer.swift
//  TermProject
//
//  Created by Raja Shekhar Reddy Guntaka on 5/10/23.
//

import Foundation
import SwiftUI
import AVFoundation

class RadioPlayer: NSObject, ObservableObject {
    
    func getRadioStation(stationId: String) -> AVPlayer? {
        guard let url=URL(string: "https://radio.garden/api/ara/content/listen/\(stationId)/channel.mp3") else {
            return nil
        }
        
        print(url.absoluteString)
        
        let player = AVPlayer(url: url)
        return player
        
    }
}
