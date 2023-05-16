import SwiftUI

struct LocalRegion: Decodable {
    let apiVersion: Int
    let version: String
    let data: Data
    
    struct Data: Decodable {
        let content: [Channels]
        let map: String
        let type: String
        let count: Int
        let utcOffset: Int
        let subtitle: String
        let url: String
        
        struct Channels: Decodable {
            let itemsType: String
            let type: String
            let items: [ChannelData]
            
            struct ChannelData: Decodable, Identifiable {
                var id: String {
                    "\(href)"
                }
                
                let href: String
                let title: String
                
                enum CodingKeys: String, CodingKey {
                    case href
                    case title
                }
                
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.href = try container.decode(String.self, forKey: .href)
                    self.title = try container.decode(String.self, forKey: .title)
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case itemsType
                case type
                case items
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.itemsType = try container.decode(String.self, forKey: .itemsType)
                self.type = try container.decode(String.self, forKey: .type)
                self.items = try container.decode([ChannelData].self, forKey: .items)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case content
            case map
            case type
            case count
            case utcOffset
            case subtitle
            case url
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.content = try container.decode([Channels].self, forKey: .content)
            self.map = try container.decode(String.self, forKey: .map)
            self.type = try container.decode(String.self, forKey: .type)
            self.count = try container.decode(Int.self, forKey: .count)
            self.utcOffset = try container.decode(Int.self, forKey: .utcOffset)
            self.subtitle = try container.decode(String.self, forKey: .subtitle)
            self.url = try container.decode(String.self, forKey: .url)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case apiVersion
        case version
        case data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.apiVersion = try container.decode(Int.self, forKey: .apiVersion)
        self.version = try container.decode(String.self, forKey: .version)
        self.data = try container.decode(Data.self, forKey: .data)
    }
}


class ChannelsViewAPI: ObservableObject {
    
    func getChannels(placeId: String, completion: @escaping (LocalRegion) -> Void) {
        
        
        print(placeId, " d fsa")
        guard let url = URL(string: "https://radio.garden/api/ara/content/page/\(placeId)/channels") else {
            return
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                return
            }
            do {
                
                let localRegion = try   decoder.decode(LocalRegion.self, from: data)
                print(localRegion)
                DispatchQueue.main.async {
                    print(localRegion)
                    completion(localRegion)
                }
            } catch {
                print("Error in decoding JSON: \(error)")
            }
            
        }.resume()
    }

}
