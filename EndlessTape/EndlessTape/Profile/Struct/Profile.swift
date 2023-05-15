import Foundation

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?

    init(result: ProfileResult) {
        self.username = result.username
        self.name = "\(result.firstName)" + " " + "\(result.lastName)"
        self.loginName = "@\(result.username)"
        self.bio = result.bio
    }
}
