### Re-develop the app with a modern technology stack
* no German-isms in code
* app sandbox, hardened runtime
* layered architecture
* Swift, SwiftUI
* [CoreData with value types and SwiftUI](https://davedelong.com/blog/2021/04/03/core-data-and-swiftui/)
* automated testing
* [Big-Sur-style icon](https://github.com/elrumo/macOS_Big_Sur_icons_replacements/blob/master/icons/Cardhop.icns)

### Address shortcomings of current app
* regularly persist CoreData in the background
* whenever an `NSTextField` loses focus (e.g., by selecting something from the `KindMenu`) its content is reset
* when multiple items are selected, tabbing through the input fields will perform edits
* cut, copy, paste does not work
* undo menu item does not show a textual action description
