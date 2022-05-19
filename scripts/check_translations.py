#!/usr/bin/python3
import glob
import json
import sys

def getKeysInFile(filePath):
    try:
        file = open(filePath, 'r')
    except OSError:
        print("Error loading file: ", filePath)
        sys.exit(-1)
    lines = file.readlines()
    keys = []
    for line in lines:
        line = line.strip()
        if "=" in line and not line.startswith("/*"):
            key, _ = line.split("=", 1)
            keys.append(key.replace('"', ''))
    return keys

def checkIfKeyIsPresent(key, filePath):
    try:
        f = open(filePath, 'r')
    except OSError:
        print("Error loading file: ", filePath)
        sys.exit(-1)
    with open(filePath) as f:
        lines = f.readlines()
        for line in lines:
            line = line.strip()
            if "=" in line and not line.startswith("/*"):
                line, _ = line.split("=", 1)
                line = line.strip().replace('"', '')
                if key == line:
                    return True
        return False  


print("Loading base file")
baseKeys = getKeysInFile("./../iMEGA/Languages/Base.lproj/Localizable.strings")

missingKeys = {}

for baseKey in baseKeys:
    print("scanning key: " + baseKey)
    directories = glob.glob("./../iMEGA/Languages/*.lproj")
    directories.remove('./../iMEGA/Languages/Base.lproj')

    missingFiles = []
    for languageDir in directories:
        localizedFilePath = languageDir + "/Localizable.strings"
        if not checkIfKeyIsPresent(baseKey, localizedFilePath):
            relativePath = localizedFilePath.split("/")[-2].split(".")[-2]
            missingFiles.append(relativePath)
    
    if len(missingFiles) > 0:
        missingKeys[baseKey] = missingFiles


if len(missingKeys) > 0:
    print("\n\n❌ Following are the missing localization keys and files")
    print(json.dumps(missingKeys, sort_keys=True, indent=2))
    sys.exit(-1)
else:
    print("✅ no missing keys. Perfect!")
    sys.exit(0)
