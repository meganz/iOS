import Foundation

let templates = ["MVVM.xctemplate", "Use Case.xctemplate", "Repository.xctemplate"]
let destinationRelativePath = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Templates/File Templates/iOS"
let fileManager = FileManager.default
let customMEGATemplatesFolderName = "MEGA Templates"

print("Welcome to MEGA Xcode Templates. This program allows you to install our own Xcode Templates")

func selectAnyOption() {
    print("""
        
        Select an option:
            
        1. 🛠️  Install or update all MEGA templates.
        2. 🛠️  Install or update the MVVM template.
        3. 🛠️  Install or update the Use Case template.
        4. 🛠️  Install or update the Repository template.
        5. 🗑️  Uninstall all templates.
        6. 🚪🚶 Exit
        
        """)

    evaluateUser(option: getInput())
}

func evaluateUser(option: String) {
    switch option {
    case "1":
        templates.forEach(installOrUpdate(template:))
    case "2", "3", "4":
        guard let currentPosition = Int(option) else {
            print("🛑  incorrect option, choose one of the following options.... 🛑")
            selectAnyOption()
            return
        }
        
        installOrUpdate(template: templates[currentPosition - 2])
    case "5":
        uninstallAllTemplates()
    case "6":
        print("....🚶 🚪 ..... 👋👋 Bye! 👋👋")
        break
    default:
        print("🛑  incorrect option, choose one of the following options.... 🛑")
        selectAnyOption()
    }
}

func getInput() -> String {
    let keyboard = FileHandle.standardInput
    let inputData = keyboard.availableData
    guard let strData = String(data: inputData, encoding: String.Encoding.utf8) else {
        return ""
    }
    return strData.trimmingCharacters(in: CharacterSet.newlines)
}
                             
func installOrUpdate(template: String){
    do {
        var isDir: ObjCBool = true
        
        if !fileManager.fileExists(atPath: "\(destinationRelativePath)/\(customMEGATemplatesFolderName)", isDirectory:&isDir) {
            do {
                try fileManager.createDirectory(atPath: "\(destinationRelativePath)/\(customMEGATemplatesFolderName)", withIntermediateDirectories: true, attributes: nil)
                print("✅  MEGA Custom Templates root folder created succesfully 🎉")
            } catch {
                print("❌  Ooops! Something went wrong 😡. Creating MEGA Templates Folder: \(error.localizedDescription)")
            }
        }
        
        if !fileManager.fileExists(atPath:"\(destinationRelativePath)/\(customMEGATemplatesFolderName)/\(template)"){
            try fileManager.copyItem(atPath: template, toPath: "\(destinationRelativePath)/\(customMEGATemplatesFolderName)/\(template)")
            print("✅  The \(template) template was installed succesfully 🎉. Enjoy it 🙂")
        }else{
            try uninstall(template: template)
            try fileManager.copyItem(atPath: template, toPath: "\(destinationRelativePath)/\(customMEGATemplatesFolderName)/\(template)")
            print("✅  The \(template) template already exists. So has been replaced succesfully 🎉. Enjoy it 🙂")
        }
    }
    catch let error as NSError {
        print("❌  Ooops! Something went wrong 😡. The \(template) template wasn't installed: \(error.localizedFailureReason!)")
    }
}

func uninstallAllTemplates() {
    print("You are going to uninstall all custom templates from Mega. Are you sure? (Y|N)")
    let optionSelected = getInput()
    if optionSelected.lowercased() == "y" {
        do {
            try templates.forEach(uninstall(template:))
            print("All templates have been successfully removed, we hope to see you again soon 😭")
        } catch let error as NSError {
            print("❌  Ooops! Something went wrong 😡. Error: \(error.localizedFailureReason!)")
        }
    } else {
        selectAnyOption()
    }
}

func uninstall(template: String) throws {
    do {
        try fileManager.removeItem(atPath: "\(destinationRelativePath)/\(customMEGATemplatesFolderName)/\(template)")
    } catch let error as NSError {
        throw error
    }
}

selectAnyOption()
