#!/usr/bin/python3

import localizable
import glob

print("Loading base file")

baseStrings = localizable.parse_strings(filename="../Base.lproj/Localizable.strings")
baseKeys = []

#print(baseStrings)

for string in baseStrings:
    #print("Key found: " + string['key'])
    baseKeys.append(string['key'])

directories = glob.glob("../*.lproj")
directories.remove("../Base.lproj")
for languageDir in directories:
    print("dir " + languageDir)
    trKeys = []
    translatedStrings = localizable.parse_strings(filename=languageDir + "/Localizable.strings")  

    for trString in translatedStrings:
        trKeys.append(trString['key'])

    missingKeys = set(baseKeys).difference(set(trKeys))

    for mk in missingKeys:
        print("missing key: " + mk)
