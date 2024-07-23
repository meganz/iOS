#!/usr/bin/python
import sys
import requests
import json
import os

# This method returns the header for GET and POST request
def headerJSON(contentType='application/vnd.api+json'):
    return {
        'Accept': '*/*',
        'Content-Type': contentType, 
        'Authorization' : sys.argv[1]
    }

def fetchAndParseChangeLogs(url, body):
    baseURLResponse = requests.post(
        url,
        data= json.dumps(body),
        headers = headerJSON()
    )

    resultJSON = baseURLResponse.json()
    return resultJSON['data']['links']['self']

def fetchBaseChangeLogsURL():
    baseURL = "https://rest.api.transifex.com/resource_strings_async_downloads"
    body = {
        "data": {
            "attributes": {
                "content_encoding": "text",
                "file_type": "default"
            },
            "relationships": {
                "resource": {
                    "data": {
                        "id": "o:meganz-1:p:ios-35:r:changelogs",
                        "type": "resources"
                    }
                }   
            },
            "type": "resource_strings_async_downloads"
        }
    }
    
    return fetchAndParseChangeLogs(baseURL, body)

# Given a language, this method return the url of the change logs.
def fetchChangeLogsURL(language):
    baseURL = "https://rest.api.transifex.com/resource_translations_async_downloads"
    body = {
        "data": {
            "attributes": {
                "content_encoding": "text",
                "file_type": "default",
                "mode": "sourceastranslation"
            },
            "relationships": {
                "language": {
                    "data": {
                        "id": language, 
                        "type": "languages"
                    }
                },
                "resource": {
                    "data": {
                        "id": "o:meganz-1:p:ios-35:r:changelogs",
                        "type": "resources"
                    }
                }
            },
            "type": "resource_translations_async_downloads"
        }
    }
    
    return fetchAndParseChangeLogs(baseURL, body)

def isJSON(text):
  try:
    json.loads(text)
  except ValueError as e:
    return False
  return True

# fetches the change logs as text given the URL. use `fetchChangeLogsURL` method to get the url for language.
def fetchChangeLogsText(url):
    data = requests.get(
        url,
        data = "",
        headers = headerJSON(contentType='text/plain')
    )
    
    if isJSON(data.text):
        print("Oops! The returned response is JSON instead of string. Trying again")
        return fetchChangeLogsText(url)

    return data.text

# Given a string, this method will return the change log for the string. Use `fetchChangeLogsText` to get the change logs.
# For instance, if you want change log for 7.0 pass "7.0" as search text
def getChangeLog(changeLogsText, searchText):
    fallbackReleaseNotesKey = "Changelog basic"
    # changelog does not contain the searchText.
    if searchText not in changeLogsText:
        searchText = fallbackReleaseNotesKey

    lines = changeLogsText.splitlines()
    changeLog = ''
    for line in lines:
        if "=" in line and "/*" not in line:
            key, value = line.split("=", 1)
            if searchText in key:
                changeLog = value[1:-2].replace("[Br]", "\n")

    # Could not extract the change log.
    if changeLog == '':
        changeLog = getChangeLog(changeLogsText, fallbackReleaseNotesKey)

    return changeLog


def releaseNotesPath(locale):
    relativePath = "./../fastlane/metadata/" + locale + "/release_notes.txt"
    dirname = os.path.dirname(__file__)
    filePath = os.path.join(dirname, relativePath)
    return filePath

# writes text to a file.
def writeToFile(filename, text):
    f = open(filename, "w")
    f.write(text)
    f.close()           

def updateChangeLogs(searchText, languageURL, languageFolders):
    changeLogsText = fetchChangeLogsText(languageURL)
    changeLog = getChangeLog(changeLogsText, searchText)
    for languageFolder in languageFolders:
        filepath = releaseNotesPath(languageFolder)
        print("release notes: \n" + changeLog + "\n")
        print("write to file:\n" + filepath)
        writeToFile(filepath, changeLog)

searchText = sys.argv[2]

# Below logic considers only the major and minor version in the version string
periodCount = searchText.count(".")
if periodCount > 1:
    searchText = searchText.rsplit(".", periodCount - 1)[0]

languagesInformation = [
    { "name": "English", "transifixCode": "l:en", "fastlaneMetadataFolders": ["en-US"] },
    { "name": "Spanish", "transifixCode": "l:es", "fastlaneMetadataFolders": ["es-ES", "es-MX"] },
    { "name": "Arabic", "transifixCode": "l:ar", "fastlaneMetadataFolders": ["ar-SA"] },
    { "name": "French", "transifixCode": "l:fr", "fastlaneMetadataFolders": ["fr-CA", "fr-FR"] },
    { "name": "Indonesian", "transifixCode": "l:id", "fastlaneMetadataFolders": ["id"] },
    { "name": "Italian", "transifixCode": "l:it", "fastlaneMetadataFolders": ["it"] },
    { "name": "Japanese", "transifixCode": "l:ja", "fastlaneMetadataFolders": ["ja"] },
    { "name": "Korean", "transifixCode": "l:ko", "fastlaneMetadataFolders": ["ko"] },
    { "name": "Dutch", "transifixCode": "l:nl", "fastlaneMetadataFolders": ["nl-NL"] },
    { "name": "Polish", "transifixCode": "l:pl", "fastlaneMetadataFolders": ["pl"] },
    { "name": "Portuguese", "transifixCode": "l:pt", "fastlaneMetadataFolders": ["pt-BR", "pt-PT"] },
    { "name": "Romanian", "transifixCode": "l:ro", "fastlaneMetadataFolders": ["ro"] },
    { "name": "Thai", "transifixCode": "l:th", "fastlaneMetadataFolders": ["th"] },
    { "name": "Vietnamese", "transifixCode": "l:vi", "fastlaneMetadataFolders": ["vi"] },
    { "name": "Chinese Simpified", "transifixCode": "l:zh_CN", "fastlaneMetadataFolders": ["zh-Hans"] },
    { "name": "Chinese Traditional", "transifixCode": "l:zh_TW", "fastlaneMetadataFolders": ["zh-Hant"] },
    { "name": "German", "transifixCode": "l:de", "fastlaneMetadataFolders": ["de-DE"] }
]


print('Start fetching the URL for all languages\n---------------START---------------------')
for index, languageInformation in enumerate(languagesInformation):
    languageCode = languageInformation["transifixCode"]
    print('Fetching the url for ' + languageInformation['name'])
    if languageCode == 'l:en':
        languagesInformation[index]['url'] = fetchBaseChangeLogsURL()
    else:
        languagesInformation[index]['url'] = fetchChangeLogsURL(languageCode)

# using a different for loop as the url generated above takes time to return the data.
# Observation is that url return json instead of change text if asked for immediately in the same loop.

print('---------------END---------------------\n')

for languageInformation in languagesInformation:
    print('Fetching what\'s new for ' + languageInformation["name"] + ' and writing it to file\n------------------START-------------------------')
    updateChangeLogs(searchText, languageInformation['url'], languageInformation['fastlaneMetadataFolders'])
    print('------------------END-------------------------\n')