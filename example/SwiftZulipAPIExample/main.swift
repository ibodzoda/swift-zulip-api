#!/usr/bin/swift

import Foundation
import SwiftZulipAPI

print("Which function would you like to test?")
print("(possible options: `messages.send`, `messages.get`, `messages.render`, `messages.update`, `streams.getAll`, `streams.getID`, `streams.getSubscribed`, `streams.subscribe`, `streams.unsubscribe`, `users.getAll`, `users.getCurrent`, `users.create`, `events.register`, `events.get`, or `events.deleteQueue`)")

guard let command = readLine(), command != "" else {
    print("Error: No command entered.")
    exit(0)
}

print("\nEmail address:")

guard let emailAddress = readLine(), emailAddress != "" else {
    print("\nError: No email address entered.")
    exit(0)
}

print("\nAPI key:")

guard let apiKey = readLine(), apiKey != "" else {
    print("\nError: No API key entered.")
    exit(0)
}

print("\nRealm URL:")

guard let realmURL = readLine(), realmURL != "" else {
    print("\nError: No realm URL entered.")
    exit(0)
}

let config = Config(
    emailAddress: emailAddress,
    apiKey: apiKey,
    realmURL: realmURL
)

let zulip = Zulip(config: config)

func getParam(name: String) -> String? {
    print("\n" + name + ":")

    guard let param = readLine(), param != "" else {
        print("Error: No " + name + " entered.")
        exit(0)
    }

    return param
}

func getParamAllowEmpty(name: String) -> String? {
    print("\n" + name + ":")

    guard let param = readLine() else {
        print("Error: No " + name + " entered.")
        exit(0)
    }

    return param
}

func handleError(error: Error?) {
    guard let error = error else {
        return
    }

    printErrorString(string: String(describing: error))
}

func printErrorString(string: String) {
    print("\nError: " + string + ".")
    exit(0)
}

func printSuccess(name: String, value: Any?) {
    print("\n" + name + ": " + String(describing: value))
    exit(0)
}

func printSuccessWithNoValue() {
    print("\nSuccess.")
    exit(0)
}

switch command {
case "messages.send":
    guard
        let messageTypeString = getParam(name: "message type"),
        let to = getParam(name: "to"),
        let subject = getParam(name: "subject"),
        let content = getParam(name: "content")
    else {
        break
    }

    let messageType = (
        messageTypeString == "MessageType.streamMessage"
            ? MessageType.streamMessage
            : MessageType.privateMessage
    )

    zulip.messages().send(
        messageType: messageType,
        to: to,
        subject: subject,
        content: content,
        callback: { (id, error) in
            handleError(error: error)
            printSuccess(name: "id", value: id)
        }
    )
case "messages.get":
    guard
        let streamString = getParam(name: "stream"),
        let anchorString = getParam(name: "anchor"),
        let amountBeforeString = getParam(name: "amount before"),
        let amountAfterString = getParam(name: "amount after")
    else {
        break
    }

    let narrow = [["stream", streamString]]

    guard
        let anchor = Int(anchorString),
        let amountBefore = Int(amountBeforeString),
        let amountAfter = Int(amountAfterString)
    else {
        break
    }

    zulip.messages().get(
        narrow: narrow,
        anchor: String(anchor),
        amountBefore: amountBefore,
        amountAfter: amountAfter,
        callback: { (messages, error) in
            handleError(error: error)
            printSuccess(name: "messages", value: messages)
        }
    )
case "messages.render":
    guard
        let content = getParam(name: "content")
    else {
        break
    }

    zulip.messages().render(
        content: content,
        callback: { (rendered, error) in
            handleError(error: error)
            printSuccess(name: "rendered", value: rendered)
        }
    )
case "messages.update":
    guard
        let messageIDString = getParam(name: "message ID"),
        let content = getParam(name: "content")
    else {
        break
    }

    guard
        let messageID = Int(messageIDString)
    else {
        break
    }

    zulip.messages().update(
        messageID: messageID,
        content: content,
        callback: { (error) in
            handleError(error: error)
            printSuccessWithNoValue()
        }
    )
case "streams.getAll":
    guard
        let includePublicString = getParam(name: "include public"),
        let includeSubscribedString = getParam(name: "include subscribed"),
        let includeDefaultString = getParam(name: "include default"),
        let includeAllActiveString = getParam(name: "include all active")
    else {
        break
    }

    let includePublic = includePublicString == "true" ? true : false
    let includeSubscribed = includeSubscribedString == "true" ? true : false
    let includeDefault = includeDefaultString == "true" ? true : false
    let includeAllActive = includeAllActiveString == "true" ? true : false

    zulip.streams().getAll(
        includePublic: includePublic,
        includeSubscribed: includeSubscribed,
        includeDefault: includeDefault,
        includeAllActive: includeAllActive,
        callback: { (streams, error) in
            handleError(error: error)
            printSuccess(name: "streams", value: streams)
        }
    )
case "streams.getID":
    guard
        let name = getParam(name: "name")
    else {
        break
    }

    zulip.streams().getID(
        name: name,
        callback: { (id, error) in
            handleError(error: error)
            printSuccess(name: "ID", value: id)
        }
    )
case "streams.getSubscribed":
    zulip.streams().getSubscribed(
        callback: { (streams, error) in
            handleError(error: error)
            printSuccess(name: "streams", value: streams)
        }
    )
case "streams.subscribe":
    guard
        let streamString = getParam(name: "stream"),
        let principalsString = getParamAllowEmpty(
            name: "principals (comma-separated)"
        )
    else {
        break
    }

    let streams = [["name": streamString]]
    let principals = (
        principalsString == ""
            ? [] : principalsString.components(separatedBy: ",")
    )

    zulip.streams().subscribe(
        streams: streams,
        principals: principals,
        callback: { (subscribed, alreadySubscribed, unauthorized, error) in
            handleError(error: error)
            printSuccess(
                name: "`subscribed`, `alreadySubscribed`, `unauthorized`",
                value: [
                    "subscribed": subscribed as Any,
                    "alreadySubscribed": alreadySubscribed as Any,
                    "unauthorized": unauthorized as Any,
                ]
            )
        }
    )
case "streams.unsubscribe":
    guard
        let streamString = getParam(name: "stream"),
        let principalsString = getParamAllowEmpty(
            name: "principals (comma-separated)"
        )
    else {
        break
    }

    let streams = [streamString]
    let principals = (
        principalsString == ""
            ? [] : principalsString.components(separatedBy: ",")
    )

    zulip.streams().unsubscribe(
        streamNames: streams,
        principals: principals,
        callback: { (unsubscribed, notSubscribed, error) in
            handleError(error: error)
            printSuccess(
                name: "`unsubscribed`, `notSubscribed`",
                value: [
                    "unsubscribed": unsubscribed as Any,
                    "notSubscribed": notSubscribed as Any,
                ]
            )
        }
    )
case "users.getAll":
    guard
        let clientGravatarString = getParam(name: "client gravatar")
    else {
        break
    }

    let clientGravatar = clientGravatarString == "true" ? true : false

    zulip.users().getAll(
        clientGravatar: clientGravatar,
        callback: { (users, error) in
            handleError(error: error)
            printSuccess(name: "users", value: users)
        }
    )
case "users.getCurrent":
    guard
        let clientGravatarString = getParam(name: "client gravatar")
    else {
        break
    }

    let clientGravatar = clientGravatarString == "true" ? true : false

    zulip.users().getCurrent(
        clientGravatar: clientGravatar,
        callback: { (profile, error) in
            handleError(error: error)
            printSuccess(name: "profile", value: profile)
        }
    )
case "users.create":
    guard
        let email = getParam(name: "email"),
        let password = getParam(name: "password"),
        let fullName = getParam(name: "full name"),
        let shortName = getParam(name: "short name")
    else {
        break
    }

    zulip.users().create(
        email: email,
        password: password,
        fullName: fullName,
        shortName: shortName,
        callback: { (error) in
            handleError(error: error)
            printSuccessWithNoValue()
        }
    )
case "events.register":
    guard
        let applyMarkdownString = getParam(name: "apply markdown"),
        let clientGravatarString = getParam(name: "client gravatar"),
        let eventTypesString = getParamAllowEmpty(
            name: "event types (comma-separated)"
        ),
        let allPublicStreamsString = getParam(name: "all public streams"),
        let includeSubscribersString = getParam(name: "include subscribers"),
        let streamName = getParam(name: "stream name")
    else {
        break
    }

    let applyMarkdown = applyMarkdownString == "true" ? true : false
    let clientGravatar = clientGravatarString == "true" ? true : false

    let eventTypes = (
        eventTypesString == ""
            ? [] : eventTypesString.components(separatedBy: ",")
    )

    let allPublicStreams = allPublicStreamsString == "true" ? true : false
    let includeSubscribers = includeSubscribersString == "true" ? true : false

    let narrow = [["stream", streamName]]

    zulip.events().register(
        applyMarkdown: applyMarkdown,
        clientGravatar: clientGravatar,
        eventTypes: eventTypes,
        allPublicStreams: allPublicStreams,
        includeSubscribers: includeSubscribers,
        narrow: narrow,
        callback: { (queue, error) in
            handleError(error: error)
            printSuccess(name: "queue", value: queue)
        }
    )
case "events.get":
    guard
        let queueID = getParam(name: "queue ID"),
        let lastEventIDString = getParam(name: "last event ID"),
        let dontBlockString = getParam(name: "don't block")
    else {
        break
    }

    guard
        let lastEventID = Int(lastEventIDString)
    else {
        break
    }

    let dontBlock = dontBlockString == "true" ? true : false

    zulip.events().get(
        queueID: queueID,
        lastEventID: lastEventID,
        dontBlock: dontBlock,
        callback: { (events, error) in
            handleError(error: error)
            printSuccess(name: "events", value: events)
        }
    )
case "events.deleteQueue":
    guard
        let queueID = getParam(name: "queue ID")
    else {
        break
    }

    zulip.events().deleteQueue(
        queueID: queueID,
        callback: { (error) in
            handleError(error: error)
            printSuccessWithNoValue()
        }
    )
default:
    print("\nError: Incorrect command.")
    exit(0)
}

RunLoop.main.run()
