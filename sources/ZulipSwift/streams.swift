import Foundation
import Alamofire

//: A client for interacting with Zulip's messaging functionality.
public class Streams {
    private var config: Config

    /*:
        Initializes a `Streams` client.

         - Parameters:
            - config: The `Config` to use.
     */
    init(config: Config) {
        self.config = config
    }

    /*:
        Gets all streams that a user can access.

         - Parameters:
            - includePublic: Whether all public streams should be included.
            - includeSubscribed: Whether all subscribed-to streams should be
              included
            - includeDefault: Whether all default streams should be included.
            - includeActive: Whether all active streams should be included.
              This option will cause a `ZulipError` if the user not an admin.
            - callback: A callback, which will be passed the streams, or an
              error.
     */
    func getAll(
        includePublic: Bool = true,
        includeSubscribed: Bool = true,
        includeDefault: Bool = false,
        includeAllActive: Bool = false,
        callback: @escaping (
            Array<Dictionary<String, Any>>?,
            Error?
        ) -> Void
    ) {
        let params = [
            "include_public": includePublic ? "true" : "false",
            "include_subscribed": includeSubscribed ? "true" : "false",
            "include_default": includeDefault ? "true" : "false",
            "include_all_active": includeAllActive ? "true" : "false",
        ]

        makeGetRequest(
            url: self.config.apiURL + "/streams",
            params: params,
            username: config.emailAddress,
            password: config.apiKey,
            callback: { (response) in
                guard
                    let streams = getChildFromJSONResponse(
                        response: response,
                        childKey: "streams"
                    ) as? Array<Dictionary<String, Any>>
                else {
                    callback(
                        nil,
                        getZulipErrorFromResponse(response: response)
                    )
                    return
                }

                callback(streams, nil)
            }
        )
    }

    /*:
        Gets the ID of a stream.

         - Parameters:
            - name: The name of the stream.
            - callback: A callback, which will be passed the ID, or an error.
     */
    func getID(
        name: String,
        callback: @escaping (Int?, Error?) -> Void
    ) {
        let params = [
            "stream": name,
        ]

        makeGetRequest(
            url: self.config.apiURL + "/get_stream_id",
            params: params,
            username: config.emailAddress,
            password: config.apiKey,
            callback: { (response) in
                guard
                    let id = getChildFromJSONResponse(
                        response: response,
                        childKey: "stream_id"
                    ) as? Int
                else {
                    callback(
                        nil,
                        getZulipErrorFromResponse(response: response)
                    )
                    return
                }

                callback(id, nil)
            }
        )
    }

    /*:
        Gets the user's subscribed streams.

         - Parameters:
            - callback: A callback, which will be passed the streams, or an
              error.
     */
    func getSubscribed(
        callback: @escaping (
            Array<Dictionary<String, Any>>?,
            Error?
        ) -> Void
    ) {
        makeGetRequest(
            url: self.config.apiURL + "/users/me/subscriptions",
            params: [:],
            username: config.emailAddress,
            password: config.apiKey,
            callback: { (response) in
                guard
                    let streams = getChildFromJSONResponse(
                        response: response,
                        childKey: "subscriptions"
                    ) as? Array<Dictionary<String, Any>>
                else {
                    callback(
                        nil,
                        getZulipErrorFromResponse(response: response)
                    )
                    return
                }

                callback(streams, nil)
            }
        )
    }
}
