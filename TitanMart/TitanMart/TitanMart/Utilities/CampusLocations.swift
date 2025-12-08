import Foundation

struct CampusLocation: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let buildingCode: String
    let instructions: String
    
    static let popularMeetupSpots = [
        CampusLocation(
            id: "library_front",
            name: "Pollak Library - Front Entrance",
            description: "Main library entrance near the circular plaza",
            buildingCode: "PL",
            instructions: "Meet at the main entrance under the large 'Pollak Library' sign. Look for the circular seating area."
        ),
        CampusLocation(
            id: "library_second",
            name: "Pollak Library - 2nd Floor",
            description: "Quiet study area near the elevators",
            buildingCode: "PL",
            instructions: "Take elevator to 2nd floor, turn right. Meet near the group study tables by the windows."
        ),
        CampusLocation(
            id: "tsu_food",
            name: "TSU Food Court",
            description: "Central food court area with tables",
            buildingCode: "TSU",
            instructions: "Enter TSU main doors, food court is straight ahead. Meet near the Panda Express."
        ),
        CampusLocation(
            id: "tsu_lobby",
            name: "TSU Main Lobby",
            description: "Spacious lobby with seating",
            buildingCode: "TSU",
            instructions: "Main entrance lobby. Look for the large Titan statue and seating area."
        ),
        CampusLocation(
            id: "langsdorf_quad",
            name: "Langsdorf Hall Quad",
            description: "Open grassy area between buildings",
            buildingCode: "LH",
            instructions: "Between Langsdorf Hall and McCarthy Hall. Meet near the large tree in the center."
        ),
        CampusLocation(
            id: "mihaylo_lobby",
            name: "Mihaylo Hall Lobby",
            description: "Business building main lobby",
            buildingCode: "MHI",
            instructions: "Main entrance lobby. Look for the digital screens and seating area."
        ),
        CampusLocation(
            id: "ec_courtyard",
            name: "Engineering Courtyard",
            description: "Outdoor courtyard between engineering buildings",
            buildingCode: "EC",
            instructions: "Between Engineering buildings E-100 and E-200. Meet near the fountain."
        ),
        CampusLocation(
            id: "src_entrance",
            name: "Student Rec Center Entrance",
            description: "Main entrance to recreation center",
            buildingCode: "SRC",
            instructions: "Main SRC entrance. Meet under the overhang near the check-in desks."
        )
    ]
    
    static var allBuildings: [String] {
        let codes = popularMeetupSpots.map { $0.buildingCode }
        return Array(Set(codes)).sorted()
    }
}
