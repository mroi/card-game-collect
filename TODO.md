### Re-develop the app with a moden technology stack
* no German-isms in code
* app sandbox, hardened runtime
* layered architecture
* Swift, SwiftUI
* automated testing

### Address shortcomings of current app
* regularly persist CoreData in the background
* whenever an `NSTextField` loses focus (e.g., by selecting something from the `KindMenu`) its content is reset
* when multiple items are selected, tabbing through the input fields will perform edits
* cut, copy, paste does not work
* undo menu item does not show a textual action description
