//: Playground - noun: a place where people can play

import JavaScriptCore
import WebKit
import PlaygroundSupport

///1
@objc protocol ContactDrawableExport: JSExport {
    var script: String { get set }
    var firstName: String { get set }
}

@objc class ContactDrawable: NSObject, ContactDrawableExport {
    var canvas: WKWebView!
    var config: WKWebViewConfiguration!
    var html: String!

    var firstName: String = ""
    var script: String = ""

    init(fname: String, script: String) {
        self.firstName = fname
        self.script = script
        config = WKWebViewConfiguration()
        let scriptContent = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(scriptContent)
        canvas = WKWebView(frame: CGRect.zero, configuration: config)
        
        guard let htmlPath = Bundle.main.path(forResource: "page", ofType: "html"),
            let html = try? String(contentsOfFile: htmlPath) else {
            return
        }
        canvas.loadHTMLString(html, baseURL: nil)
    }
}


@objc protocol ContactProtocol: JSExport {
    var firstName: String { get set }
    var lastName: String { get set }
    var email: String { get set }
    var phone: String { get set }
}

@objc class Contact: NSObject, ContactProtocol {
    dynamic var firstName: String
    dynamic var lastName: String
    dynamic var email: String
    dynamic var phone: String
    
    init(fname: String, lname: String, email: String, phone: String) {
        self.firstName = fname
        self.lastName = lname
        self.email = email
        self.phone = phone
    }
}

let createContactScript: @convention(block)(String, String, String, String) -> Contact = { fname, lname, email, phone in
    return Contact(fname: fname, lname: lname, email: email, phone: phone)
}


func testJSVM() {
    let jsVM = JSVirtualMachine()

//    if let jsContext = JSContext(virtualMachine: jsVM),
//        let momentPath = Bundle.main.path(forResource: "moment.min", ofType: "js"),
//        let momentLib = try? String(contentsOfFile: momentPath) {
//        jsContext.evaluateScript(momentLib)
//        let moment = jsContext.evaluateScript("moment().format()")
//        let fn = jsContext.objectForKeyedSubscript("moment")
//        let fn1 = fn?.construct(withArguments: nil)
//        let currentMin = fn1?.invokeMethod("minute", withArguments: nil)
//        let yesterday = fn1?.invokeMethod("add", withArguments: ["-1", "days"])
//    }
}

func testSetObj() {
    let context = JSContext()
    context?.setObject(Contact.self, forKeyedSubscript: "Contact" as NSString)
    context?.setObject(unsafeBitCast(createContactScript, to: AnyObject.self), forKeyedSubscript: "createContact" as (NSCopying & NSObjectProtocol))
}

///Faker
func injectFaker() {
    guard let context = UIWebView().value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as? JSContext,
        let fakerPath = Bundle.main.path(forResource: "faker.min", ofType: "js"),
        let fakerLib = try? String(contentsOfFile: fakerPath),
        let contactPath = Bundle.main.path(forResource: "contact", ofType: "js"),
        let contactLib = try? String(contentsOfFile: contactPath) else { return }
    let logFunction : @convention(block) (String) -> Void = { (msg: String) in
        print("console: \(msg)")
    }
    context.objectForKeyedSubscript("console").setObject(unsafeBitCast(logFunction, to: AnyObject.self),
                                                            forKeyedSubscript: "log" as NSCopying & NSObjectProtocol)
    context.setObject(ContactDrawable.self, forKeyedSubscript: "ContactDrawable" as (NSCopying & NSObjectProtocol))
    context.setObject(Contact.self, forKeyedSubscript: "Contact" as (NSCopying & NSObjectProtocol))

    let mainView = UIView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 200))
    let addToViewScript: @convention(block) (JSValue) -> Void = { value in
        let drawableValue: JSManagedValue = JSManagedValue(value: value)
        let dict = drawableValue.value.toObject() as? [String: String]
        let drawable = ContactDrawable(fname: dict?["firstName"] ?? "unknown", script: dict?["script"] ?? "unknown")
        drawable.canvas.frame = mainView.bounds
        context.virtualMachine.addManagedReference(drawableValue, withOwner: mainView)
        mainView.addSubview(drawable.canvas)
        print("1234")

        PlaygroundPage.current.liveView = mainView
        context.virtualMachine.removeManagedReference(drawableValue, withOwner: mainView)
    }
    context.setObject(unsafeBitCast(createContactScript, to: AnyObject.self), forKeyedSubscript: "createContact" as (NSCopying & NSObjectProtocol))
    context.setObject(unsafeBitCast(addToViewScript, to: AnyObject.self), forKeyedSubscript: "addToView" as (NSCopying & NSObjectProtocol))
    context.evaluateScript(fakerLib)
    context.evaluateScript(contactLib)
    let createFakeContactFn = context.objectForKeyedSubscript("createFakeContact")
    if let contact = createFakeContactFn?.call(withArguments: []).toObject() as? Contact {
        contact.firstName
        contact.lastName
        contact.email
        contact.phone
    }
    
}
injectFaker()
