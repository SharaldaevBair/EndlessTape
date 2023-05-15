import Foundation

struct UserResult: Decodable {
    let profileImage: ProfileImage

    struct ProfileImage: Decodable {
        let small: String
    }
}
