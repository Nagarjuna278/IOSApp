import SwiftUI

struct Geo: Decodable,Identifiable {
    
    var id: String {
        "\(latitude)_\(longitude)"
    }
    
    let eu: Bool
    let country_code: String
    let region_code: String
    let latitude: Double
    let longitude: Double
    let city: String
    
    enum CodingKeys: String, CodingKey {
        case eu
        case country_code = "country_code"
        case region_code = "region_code"
        case latitude
        case longitude
        case city
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.eu = try container.decode(Bool.self, forKey: .eu)
        self.country_code = try container.decode(String.self, forKey: .country_code)
        self.region_code = try container.decode(String.self, forKey: .region_code)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.city = try container.decode(String.self, forKey: .city)
    }
}

struct Place: Decodable {
    let apiVersion: Int
    let version: String
    let data: Data
    
    struct Data: Decodable {
        let list: [Coord]
        let version: String
        
        struct Coord: Decodable, Identifiable {
            let id: String
            let geo: [Double]
            let url: String
            let size: Int
            let boost: Bool
            let title: String
            let country: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case geo
                case url
                case size
                case boost
                case title
                case country
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.id = try container.decode(String.self, forKey: .id)
                self.geo = try container.decode([Double].self, forKey: .geo)
                self.url = try container.decode(String.self, forKey: .url)
                self.size = try container.decode(Int.self, forKey: .size)
                self.boost = try container.decode(Bool.self, forKey: .boost)
                self.title = try container.decode(String.self, forKey: .title)
                self.country = try container.decode(String.self, forKey: .country)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case list
            case version
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.list = try container.decode([Coord].self, forKey: .list)
            self.version = try container.decode(String.self, forKey: .version)
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

class PlacesAPI: ObservableObject {
    
    @Published var place: Place?
    
    
    func getGeo(completion: @escaping (Geo) -> Void){
        guard let url = URL(string: "https://radio.garden/api/geo") else {
            return
        }

        let decoder = JSONDecoder()
        //decoder.keyDecodingStrategy = .convertFromSnakeCase

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                return
            }
            
            do {
                let geo = try decoder.decode(Geo.self, from: data)
                print(geo)
                DispatchQueue.main.async {
                    completion(geo)
                }
            } catch {
                print("Error in decoding JSON: \(error)")
            }
            
        }.resume()

    }
    
    func fetchPlaces(completion: @escaping (Place) -> Void) {
            
        guard let url = URL(string: "https://radio.garden/api/ara/content/places") else {
            return
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                return
            }
            
            do {
                var place = try decoder.decode(Place.self, from: data)
                DispatchQueue.main.async {
                    place = place
                    completion(place)
                }
            } catch {
                print("Error in decoding JSON: \(error)")
            }
            
        }.resume()
    }

}
