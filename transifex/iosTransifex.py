#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json, os, sys, re, subprocess, time, argparse, datetime
from pyexpat import ExpatError
from xml.dom.minidom import parseString
from threading import Thread

version = sys.version_info.major
if version == 2:
    from urllib2 import Request, urlopen, install_opener, build_opener, HTTPRedirectHandler, HTTPError
    reload(sys)
    sys.setdefaultencoding('utf8')
else:
    from urllib.request import Request, urlopen, install_opener, build_opener, HTTPRedirectHandler
    from urllib.error import HTTPError

transifex_token = os.getenv("TRANSIFEX_TOKEN")
gitlab_token = os.getenv("GITLAB_TOKEN")
transifex_bot_token = os.getenv('TRANSIFEX_BOT_TOKEN')
transifex_bot_url = os.getenv('TRANSIFEX_BOT_URL')

config_file = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'transifexConfig.json')
if os.path.exists(config_file):
    transifex_config_file = open(config_file, "r")
    content = transifex_config_file.read()
    transifex_config_file.close()
    transifex_config = json.loads(content)

    transifex_token = transifex_config.get('apiToken') or transifex_token
    gitlab_token = transifex_config.get('gitLabToken') or gitlab_token
    transifex_bot_token = transifex_config.get('botToken') or transifex_bot_token
    transifex_bot_url = transifex_config.get('botUrl') or transifex_bot_url

if not transifex_token:
    print("Error: Missing transifex token.")
    sys.exit(1)

if not gitlab_token:
    print("Error: Missing gitlab token.")
    sys.exit(1)

BASE_URL = "https://rest.api.transifex.com"
GITLAB_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/repository/files/iMEGA%2FLanguages%2FBase.lproj%2F$file/raw?ref=develop"
PROJECT_ID = "o:meganz-1:p:ios-35"
STORES_IOS_ID = "o:meganz-1:p:stores:r:app_store_ios"
HEADER = {
    "Authorization": "Bearer " + transifex_token,
    "Content-Type": "application/vnd.api+json"
}
REMAPPED_CODE = {
    "zh_CN": "zh-Hans",
    "zh_TW": "zh-Hant",
}
I18N_FORMAT = ["STRINGS", "STRINGSDICT"]
RESERVED_RESOURCES = ["Localizable", "InfoPlist", "Plurals", "Changelogs", "LTHPasscodeViewController"]
DOWNLOAD_FOLDER = os.getcwd() + "/download/"
git_path = os.getcwd()
if "/transifex" in git_path:
    git_path = git_path + "/.."
PROD_FOLDER = git_path + "/iMEGA/Languages/"
if not os.path.isdir(PROD_FOLDER):
    os.makedirs(PROD_FOLDER)
if not os.path.isdir(DOWNLOAD_FOLDER):
    os.makedirs(DOWNLOAD_FOLDER)

resources = {}
language_cache = {}
base_strings = []
branch_strings = {}
user_cache = {}
# re.sub compatible version of PHP regex: /^[\pZ\pC]+|[\pZ\pC]+$/u as \p is not supported
unicode_regex = re.compile('^[\u0000-\u0020\u007F-\u00A0\u00AD\u0600-\u0605\u061C\u06DD\u070F\u08E2\u1680\u180E\u2000-\u200F\u2028-\u202F\u205F-\u2064\u2066-\u206F\u3000\uFEFF\uFFF9-\uFFFB\U000110BD\U000110CD\U00013430-\U00013438\U0001BCA0\U0001BCA3\U0001D173-\U0001D17A\U000E0001\U000E0020-\U000E007F]+|[\u0000-\u0020\u007F-\u00A0\u00AD\u0600-\u0605\u061C\u06DD\u070F\u08E2\u1680\u180E\u2000-\u200F\u2028-\u202F\u205F-\u2064\u2066-\u206F\u3000\uFEFF\uFFF9-\uFFFB\U000110BD\U000110CD\U00013430-\U00013438\U0001BCA0\U0001BCA3\U0001D173-\U0001D17A\U000E0001\U000E0020-\U000E007F]+$', re.UNICODE)
xml_tag_regex = re.compile(r'<[^[sd][^>]*>')

# Call this function to create a new resource in Transifex for the current git branch and create a local file for string additions/edits
def run_branch(resource):
    branch = get_branch_name()
    if branch == False:
        print("Error: Not allowed to create resources for develop/master branch")
        return False
    resource_name = resource + "-" + branch
    is_plurals = "Plurals" in resource
    if is_plurals:
        i18n_format = I18N_FORMAT[1]
    else:
        i18n_format = I18N_FORMAT[0]
    if does_resource_exist(resource_name):
        print("Resource " + resource_name + " already exists.")
        return None
    create_payload = {
        "data": {
            "attributes": {
                "name": resource_name,
                "slug": resource_name.lower()
            },
            "relationships": {
                "i18n_format": {
                    "data": {
                        "id": i18n_format,
                        "type": "i18n_formats",
                    },
                },
                "project": {
                    "data": {
                        "id": PROJECT_ID,
                        "type": "projects",
                    },
                },
            },
            "type": "resources",
        }
    }
    result = do_request(BASE_URL + "/resources", create_payload)
    if "errors" in result:
        print("Error: Resource " + resource_name + " was not created")
        print_error(result["errors"])
        return False
    print("Successfully created new resource " + resource_name)
    return True

# Call this function to download the resource to the specified folder
def run_download(resource, folder = DOWNLOAD_FOLDER):
    if folder != DOWNLOAD_FOLDER and not os.path.isdir(folder):
        os.makedirs(folder)
    if does_resource_exist(resource):
        print("Downloading " + resource)
        is_plurals = "Plurals" in resource
        content = resource_get_english(resource, is_plurals)
        if content:
            if folder == PROD_FOLDER:
                store_file(resource, process_as_download(content, is_plurals))
            else:
                file_path = folder + "/" + get_file_basename(resource)
                file_put_contents(file_path, content)
                print("File saved to " + file_path)
        else:
            print("Error: Failed to download resource " + resource)
    else:
        print("Error: Resource " + resource + " not found")

# Call this function to download each reserved resource to the Production folder
def run_fetch(merge = False):
    resources = get_resources()
    branch = get_branch_name()
    for resource in resources:
        resource_name = resources[resource]["name"]
        if resource_name in RESERVED_RESOURCES:
            if merge:
                if branch and does_resource_exist(resource_name + "-" + branch):
                    run_merge(resource_name, resource_name + "-" + branch)
                else:
                    run_download(resource_name, PROD_FOLDER)
            else:
                print("Downloading " + resource_name)
                is_plurals = "Plurals" in resource_name
                content = resource_get_english(resource_name, is_plurals)
                if content:
                    store_file(resource_name, process_as_download(content, is_plurals))
                else:
                    print("Error: Failed to download resource " + resource_name)
    return True

# Call this function to download each reserved resource and each language to the Production folder
def run_export(merge = False, spec_resource = False):
    languages = get_languages()
    branch = ""
    if merge:
        if get_branch_name():
            branch = get_branch_name()
        else:
            print("Error: Cannot export and merge for a branch on master/develop")
            merge = False
    def export_resource_language(resource, language):
        if merge and does_resource_exist(resource + "-" + branch):
            run_merge(resource, resource + "-" + branch, language, languages[language]["code"])
            return
        is_plurals = "Plurals" in resource
        content = resource_get_language(resource, language, is_plurals)
        if content:
            code = languages[language]["code"]
            if code in REMAPPED_CODE:
                code = REMAPPED_CODE[code]
            store_file(resource, process_as_download(content, is_plurals), code)
        else:
            print("Error: Failed to download resource " + resource + " in language " + languages[language]["name"])

    resources = get_resources()
    print("Exporting English")
    if spec_resource:
        if branch != "" and does_resource_exist(spec_resource + "-" + branch):
            run_merge(spec_resource, spec_resource + "-" + branch)
        elif does_resource_exist(spec_resource):
            run_download(spec_resource, PROD_FOLDER)
        else:
            print("Error: Resource does not exist")
            return False
    else:
        run_fetch(merge)
    threads = []
    for resource in resources:
        if resources[resource]["name"] in RESERVED_RESOURCES:
            if spec_resource and resources[resource]["name"] == spec_resource:
                print("Exporting languages for " + resources[resource]["name"])
                for id in languages.keys():
                    t = Thread(target=export_resource_language, args=(resources[resource]["name"], id))
                    threads.append(t)
                    t.start()
            elif not spec_resource:
                print("Exporting languages for " + resources[resource]["name"])
                for id in languages.keys():
                    t = Thread(target=export_resource_language, args=(resources[resource]["name"], id))
                    threads.append(t)
                    t.start()

    for thread in threads:
        thread.join()
    print("Export finished")
    return True

# Call this function to upload the strings file supplied as the base file of the resource it is named for
def run_upload(file_content, resource, branch):
    is_plurals = "Plurals" in resource
    if not validate_file(file_content, is_plurals):
        print("Error: Invalid file content")
        return False
    if branch:
        resource_key = does_resource_exist(resource + "-" + branch)
        if resource_key == False:
            if run_branch(resource) == False:
                print("Error: Cannot upload as the branch does not exist")
                return False
            else:
                resource_key = does_resource_exist(resource + "-" + branch, True)
    else:
        resource_key = does_resource_exist(resource)
    if resource_key:
        if branch:
            gitlab_resource_file = gitlab_download(resource)
            if gitlab_resource_file:
                resource = resource + "-" + branch
                gitlab_map = content_to_map(gitlab_resource_file, False, is_plurals)
                file_map = content_to_map(file_content, False, is_plurals) # This needs to be in the same parsed state as the gitlab map i.e: download content not the upload content
                diff_map = {key: str for key, str in file_map.items() if key not in gitlab_map or not strings_equal(gitlab_map[key], str, is_plurals)}
                file_content = map_to_content(diff_map, is_plurals)
            else:
                print("Error: Failed to download gitlab file")
                return False
        now = int(datetime.datetime.utcnow().strftime("%s")) - 30
        print("Uploading file")
        if resource_put_english(resource_key, process_as_upload(file_content, is_plurals)):
            print("Upload completed")
            time.sleep(5)
            run_lock(resource, now)
            return True
        else:
            print("Error: Failed to upload file for resource " + resource)
    else:
        print("Error: Invalid resource specified")

# Call this function to merge the resource and branch resource and put the result in the PROD_FOLDER
def run_merge(resource, branch_resource, language = False, lang_code = "Base"):
    if does_resource_exist(resource) and does_resource_exist(branch_resource):
        is_plurals = "Plurals" in resource
        print("Downloading and merging " + resource + " with " + branch_resource)
        if language:
            resource_content = resource_get_language(resource, language, is_plurals)
        else:
            resource_content = resource_get_english(resource, is_plurals)
        if resource_content:
            if language:
                branch_resource_content = resource_get_language(branch_resource, language, is_plurals)
            else:
                branch_resource_content = resource_get_english(branch_resource, is_plurals)
            if branch_resource_content:
                gitlab_resource_content = gitlab_download(resource, lang_code)
                if gitlab_resource_content or "LTHPasscodeViewController" in resource:
                    print("Downloads complete. Merging")
                    merge_content = merge_strings(resource_content, branch_resource_content, False, is_plurals)
                    if "LTHPasscodeViewController" not in resource:
                        merge_content = merge_strings(gitlab_resource_content, merge_content, False, is_plurals)
                    if merge_content:
                        store_file(resource[:resource.find("-") if "-" in resource else len(resource)], merge_content, lang_code)
                        return True
                    else:
                        print("Error: Failed to merge resource files")
                else:
                    print("Error: Failed to download gitlab resource file")
            else:
                print("Error: Failed to download branch resource file")
        else:
            print("Error: Failed to download main resource file")
    else:
        print("Error: Resources specified for merge don't exist")

# Call this function to lock an unlocked resource in Transifex to prevent translations from being saved
def run_lock(resource, update_time = 0, is_stores = False):
    is_change_logs = resource == 'Changelogs'
    if is_stores or does_resource_exist(resource):
        print("Preparing to lock resource")
        if not is_stores:
            resource = PROJECT_ID + ":r:" + resource.lower()
        response = do_request(BASE_URL + "/resource_strings?filter[resource]=" + resource)
        if "errors" in response:
            print_error(response["errors"])
            print("Error: Unable to retrieve strings to lock")
            return False
        to_lock = {}
        languages = get_languages()
        locked_tags = ["do_not_translate"]
        if is_change_logs:
            locked_tags.append('change_log')
        for language in languages:
            locked_tags.append("locked_" + languages[language]["code"])
        for string in response["data"]:
            mod_time = datetime.datetime.strptime(string["attributes"]["strings_datetime_modified"], "%Y-%m-%dT%H:%M:%SZ")
            if int(mod_time.strftime("%s")) >= update_time:
                string_tags = string["attributes"]["tags"]
                not_fully_locked = False
                for tag in locked_tags:
                    if tag not in string_tags:
                        not_fully_locked = True
                        string_tags.append(tag)
                if not_fully_locked:
                    to_lock[string["id"]] = string_tags
        if to_lock:
            print("Locking strings")
            update_tags(to_lock)
            print("Strings locked successfully")
        else:
            print("Error: Resource is already locked or there are no strings to lock")
    else:
        print("Error: Resource " + resource + " not found")

# Call this function to unlock a locked, non-reserved resource in Transifex to allow translations to be saved
def run_unlock(resource):
    if does_resource_exist(resource):
        print("Preparing to unlock strings")
        resource = PROJECT_ID + ":r:" + resource.lower()
        response = do_request(BASE_URL + "/resource_strings?filter[resource]=" + resource)
        if "errors" in response:
            print_error(response["errors"])
            print("Error: Unable to retrieve strings to lock")
            return False
        to_unlock = {}
        languages = get_languages()
        locked_tags = ["do_not_translate"]
        for language in languages:
            locked_tags.append("locked_" + languages[language]["code"])
        for string in response["data"]:
            tmp = []
            unlock = False
            has_no_translate = False
            for tag in string["attributes"]["tags"]:
                if tag == "notranslate":
                    has_no_translate = True
                    tmp.append(tag)
                    unlock = True
                elif tag in locked_tags:
                    unlock = True
                else:
                    tmp.append(tag)
            if unlock:
                if has_no_translate:
                    tmp.append("do_not_translate")
                to_unlock[string["id"]] = tmp
        if to_unlock:
            print("Unlocking strings")
            update_tags(to_unlock)
            print("Strings unlocked successfully")
        else:
            print("Error: Resource is already unlocked or there are no strings")
    else:
        print("Error: Resource " + resource + " not found")

# Call this function to merge the branch_resource into base_resource and then delete base_resource
def run_close(base_resource, branch_resource):
    resource_key = does_resource_exist(base_resource)
    if resource_key and does_resource_exist(branch_resource):
        print("Fetching resources to close")
        is_plurals = "Plurals" in base_resource # Assume both resources are stringsdicts or strings not one of each
        resource_file = resource_get_english(base_resource, is_plurals)
        branch_file = resource_get_english(branch_resource, is_plurals)
        if resource_file and branch_file:
            print("Merging " + branch_resource + " into " + base_resource)
            merge_content = merge_strings(resource_file, branch_file, True, is_plurals)
            if merge_content:
                print("Uploading merged content")
                if resource_put_english(resource_key, merge_content):
                    if get_strings_data(branch_resource, True):
                        time.sleep(2)
                        if get_strings_data(base_resource, False):
                            print("Confirming upload succeeded")
                            if verify_strings_exist():
                                print("Remapping data")
                                delete = branch_resource not in RESERVED_RESOURCES
                                base_resource = base_resource.lower()
                                branch_resource = branch_resource.lower()
                                screenshots = clone_screenshots(base_resource, branch_resource)
                                add_updater(base_resource, branch_resource)
                                comments = clone_comments(base_resource, branch_resource)
                                status = clone_status(base_resource, branch_resource)
                                tags = clone_tags(base_resource, branch_resource)
                                if screenshots and tags and comments and status:
                                    if delete:
                                        print("Deleting resource " + branch_resource)
                                        response = do_request(BASE_URL + "/resources/" + PROJECT_ID + ":r:" + branch_resource, None, "DELETE")
                                        if "errors" in response:
                                            print_error(response["errors"])
                                            print("Error: Unable to delete branch resource " + branch_resource)
                                        else:
                                            print("Successfully deleted branch resource" + branch_resource)
                                else:
                                    print("Error: Metadata merge is incomplete. Branch resource not deleted")
                            else:
                                print("Error: Not all strings are present in base resource")
                        else:
                            print("Error: Unable to retrieve base resource metadata")
                    else:
                        print("Error: Unable to retrieve branch resource metadata")
                else:
                    print("Error: Unable to upload merged content")
            else:
                print("Error: Unable to merge branch and resource content")
        else:
            print("Error: Unable to retrieve branch and resource files")
    else:
        print("Error: Unable to find the resources")

# Call this function to update the resource with new comments
def run_comment(resource):
    if "Plurals" in resource:
        print("Error: This is not supported for stringsdict resources")
        return False
    resource_key = does_resource_exist(resource)
    if resource_key:
        print("Downloading " + resource)
        resource_content = resource_get_english(resource)
        if resource_content:
            resource_map = content_to_map(resource_content, False)
            edit_string_nodes = []
            create_string_nodes = []
            more_input = True
            while more_input:
                key = input("Enter a string code to edit or press enter to continue: ")
                if key == "":
                    more_input = False
                elif key in resource_map:
                    if resource_map[key]["c"] == None:
                        create_string_nodes.append(key)
                    else:
                        edit_string_nodes.append(key)
                else:
                    print("Invalid string code entered. Try again")
            if len(create_string_nodes) + len(edit_string_nodes) == 0:
                print("No strings were found to edit")
            else:
                if len(create_string_nodes):
                    print("The following strings did not have a developer comment. Please add one now")
                    for key in create_string_nodes:
                        comment_value = ""
                        while comment_value == "":
                            comment_value = input("Comment for " + key + ": ")
                        resource_map[key]["c"] = comment_value
                if len(edit_string_nodes):
                    print("Please enter the updated developer comment for the following strings")
                    for key in edit_string_nodes:
                        comment_value = ""
                        while comment_value == "":
                            comment_value = input("Comment for " + key + ": ")
                        resource_map[key]["c"] = comment_value
                update_content = process_as_upload(map_to_content(resource_map)) # Prepare the upload version
                print("Updating Transifex")
                if resource_put_english(resource_key, update_content):
                    print("Comments updated in Transifex")
                else:
                    print("Error: Unable to upload updated comments to Transifex")
        else:
            print("Error: Failed to download resource file")
    else:
        print("Error: Unable to find the resource")

# Call this function to initiate pruning for the Localizable resource by the Transifex bot.
def run_pruning():
    global transifex_bot_token
    global transifex_bot_url
    localizable = PROJECT_ID + ':r:localizable'
    if transifex_bot_token and transifex_bot_url:
        header = {
            "Authorization": "Bearer " + transifex_bot_token
        }
        i = 30
        while i > 0:
            request = Request(transifex_bot_url + '?o=prune&pid=193', headers=header)
            try:
                response = urlopen(request)
            except HTTPError as ex:
                content = ex.read().decode('utf8')
                print('Error: ' + content)
                return False
            content = response.read().decode('utf8')
            if content == '':
                print('Empty response from the Transifex bot')
                return False
            else:
                try:
                    content = json.loads(content)
                    if 'ok' in content:
                        if content['ok']:
                            if 'status' in content and content['status'] == 'pending':
                                if i % 5 == 0:
                                    print('Processing.....')
                                time.sleep(10)
                            i = i - 1
                        elif 'error' in content:
                            print('Error: ' + content['error'])
                            return False
                        else:
                            print('Unknown error')
                            return False
                    elif localizable in content and 'ok' in content[localizable]:
                        if content[localizable]['ok']:
                            if content[localizable]['pruned'] > 0:
                                print('Removed' + str(content[localizable]['pruned']) + ' unused string')
                                print('Backup located in server directory ' + content[localizable]['backup'])
                            else:
                                print('Nothing to remove')
                            return True
                        elif 'error' in content[localizable]:
                            print('Error: ' + content[localizable]['error'])
                            return False
                        else:
                            print('Unknown error when pruning Localizable')
                            return False
                    else:
                        print('Error: Unexpected result')
                        return False
                except:
                    print('Error: ' + str(content))
                    return False
        print('Error: Pruning timed out')
    else:
        print('Invalid environment variables')

# Call this function to perform a request to Transifex
def do_request(url, json_payload = None, type = "GET"):
    is_git_request = "code.developers.mega.co.nz" in url
    if is_git_request:
        global gitlab_token
        headers = {
            "PRIVATE-TOKEN":  gitlab_token
        }
    else:
        headers = HEADER
    if json_payload == None:
        request = Request(url, headers=headers)
    else:
        request = Request(url, headers=headers, data=json.dumps(json_payload).encode('utf8'))
        if type == "GET":
            type = "POST"
    request.get_method = lambda: type
    try:
        response = urlopen(request)
    except HTTPError as e:
        if is_git_request:
            if e.code == 401:
                print("Error: Invalid Gitlab token")
                return False
            elif e.code == 404:
                print("Error: Unable to find file in Gitlab")
                return False
            else:
                print("Error: Unknown error from Gitlab")
                return False
        elif e.code == 303:
            raise e
        elif e.code == 204:
            return "No Content"
        else:
            errContent = json.loads(e.read().decode('utf-8'))
            errMsg = "Error: Requesting " + url + " failed"
            if json_payload != None:
                errMsg = errMsg + " with payload " + json.dumps(json_payload)
            print(errMsg)
            return errContent
    res = response.read()
    if res == "":
        return {"code": res.code}
    if is_git_request:
        return res
    return json.loads(res)

# Call this function to get all resources in Transifex
def get_resources():
    global resources
    if resources:
        return resources
    response = do_request(BASE_URL + "/resources?filter[project]=" + PROJECT_ID)
    if "errors" in response:
        print("Error: Failed to fetch resource data")
        print_error(response["errors"])
        return resources
    for data in response["data"]:
        resources[data["id"]] = {
            "name": data["attributes"]["name"],
            "strings": data["attributes"]["string_count"]
        }
    return resources

# Call this function to check if resource_name exists in Transifex
def does_resource_exist(resource_name, refresh = False):
    global resources
    if refresh:
        resources = {}
    if len(resources) == 0:
        resources = get_resources()
    for key in resources:
        if resources[key]["name"] == resource_name:
            return key
    return False

# Call this function to get the strings data from the resource
def get_strings_data(resource, is_branch):
    url = BASE_URL + "/resource_strings?filter[resource]=" + PROJECT_ID + ":r:" + resource.lower()
    while url != None:
        response = do_request(url)
        url = None
        if "errors" in response:
            print_error(response["errors"])
            return False
        for string in response["data"]:
            if is_branch:
                branch_strings[string["attributes"]["string_hash"]] = {
                    "tags": string["attributes"]["tags"],
                    "updater": string["relationships"]["committer"]["data"]["id"],
                    "pluralised": string["attributes"]["pluralized"],
                    "id": string["id"],
                }
            else:
                base_strings.append(string["attributes"]["string_hash"])
        if "next" in response["links"] and response["links"]["next"] != None:
            url = response["links"]["next"]
    return True

# Call this function to get the available languages for the project
def get_languages():
    global language_cache
    if language_cache:
        return language_cache
    response = do_request(BASE_URL + "/projects/" + PROJECT_ID + "/languages")
    if "errors" in response:
        print("Error: Failed to retrieve languages")
        print_error(response["errors"])
        return language_cache
    for data in response["data"]:
        language_cache[data["id"]] = {
            "code": data["attributes"]["code"],
            "name": data["attributes"]["name"]
        }
    return language_cache

# Call this function to return the username for the given id or the id if not found
def get_username_from_id(id):
    global user_cache
    if id in user_cache:
        return user_cache[id]
    response = do_request(BASE_URL + "/users/" + id)
    if "errors" in response:
        return id
    if response["data"] and response["data"]["attributes"]["username"]:
        user_cache[id] = response["data"]["attributes"]["username"]
        return user_cache[id]
    return id

# Call this function to get the English file for the given resource
def resource_get_english(resource, is_plurals = False):
    payload = {
        "data": {
            "attributes": {
                "content_encoding": "text",
                "file_type": "default"
            },
            "relationships": {
                "resource": {
                    "data": {
                        "id": PROJECT_ID + ":r:" + resource.lower(),
                        "type": "resources",
                    },
                }
            },
            "type": "resource_strings_async_downloads",
        },
    }
    if resource == STORES_IOS_ID:
        payload["data"]["relationships"]["resource"]["data"]["id"] = resource
    if is_plurals:
        content = file_download(payload)
    else:
        content = file_download(payload, "utf-16")
    if content == False:
        print("Error: Unable to download English resource file for " + resource)
        return False
    return content

# Call this function to get the specified languages file for the given resource
def resource_get_language(resource, lang, is_plurals = False):
    payload = {
        "data": {
            "attributes": {
                "content_encoding": "text",
                "file_type": "default",
                "mode": "sourceastranslation"
            },
             "relationships": {
                "language": {
                    "data": {
                        "id": lang,
                        "type": "languages"
                    }
                },
                "resource": {
                    "data": {
                        "id": PROJECT_ID + ":r:" + resource.lower(),
                        "type": "resources",
                    },
                }
            },
            "type": "resource_translations_async_downloads"
        }
    }
    if is_plurals:
        content = file_download(payload)
    else:
        content = file_download(payload, "utf-16")
    if content == False:
        print("Error: Unable to download English resource file for " + resource)
        return False
    return content

# Call this function to upload a base resource file to Transifex
def resource_put_english(resource, content):
    payload = {
        "data": {
            "attributes": {
                "content": content,
                "content_encoding": "text",
            },
            "relationships": {
                "resource": {
                    "data": {
                        "id": resource.lower(),
                        "type": "resources",
                    },
                },
            },
            "type": "resource_strings_async_uploads",
        },
    }
    return file_upload(payload)

# Call this function to download the gitlab strings file for the resource
def gitlab_download(resource, language = "Base"):
    if "LTHPasscodeViewController" in resource:
        return False
    url = GITLAB_URL.replace("$file", get_file_basename(resource))
    if language != "Base":
        if language in REMAPPED_CODE:
            language = REMAPPED_CODE[language]
        url = url.replace("Base.lproj", language + ".lproj")
    content = do_request(url)
    if content:
        return content.decode("utf-8")
    return False

# Call this function to download a file defined by the payload
def file_download(payload, encoding = "utf-8"):
    url = BASE_URL + "/" + payload["data"]["type"]
    response = do_request(url, payload)
    if "errors" in response:
        print_error(response["errors"])
        return False
    wait_url = response["data"]["links"]["self"]
    data = await_download(wait_url, encoding)
    if data == False:
        return False
    return data

# Call this function to upload a resource/translation file to Transifex
def file_upload(payload):
    url = BASE_URL + "/" + payload["data"]["type"]
    response = do_request(url, payload)
    if "errors" in response:
        print_error(response["errors"])
        return False
    wait_url = response["data"]["links"]["self"]
    return await_upload(wait_url)

# Call this function to await a file download request
def await_download(url, encoding = "utf-8"):
    class NoRedirect(HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, headers, newurl):
            return None
    opener = build_opener(NoRedirect)
    install_opener(opener)
    for i in range(50):
        try:
            response = do_request(url)
            if "errors" in response:
                print_error(response["errors"])
                return False
            if response["data"]["attributes"]["status"] == "failed":
                if response["data"]["attributes"]["errors"]:
                    print_error(response["data"]["attributes"]["errors"])
                return False
        except HTTPError as e:
            if e.code == 303:
                file = urlopen(e.headers["Location"])
                response = file.read().decode(encoding)
                return response
            elif e.code != 200:
                response = json.loads(e.read().decode("utf-8"))
                if "errors" in response:
                    print_error(response["errors"])
                return False
        time.sleep(2)
    return False

# Call this function to await a file upload request
def await_upload(url):
    for i in range(50):
        response = do_request(url)
        if "errors" in response:
            print_error(response["errors"])
            return False
        elif response["data"]["attributes"]["status"] == "failed":
            if response["data"]["attributes"]["errors"]:
                print_error(response["data"]["attributes"]["errors"])
            return False
        elif response["data"]["attributes"]["status"] != "pending":
            return True
        time.sleep(2)
    return False

# Call this function to convert the file into the upload formatted version for Transifex
def process_as_download(file_content, is_plurals):
    return map_to_content(content_to_map(file_content, False, is_plurals), is_plurals)

# Call this function to convert the file downloaded from Transifex into the correct formatted version
def process_as_upload(file_content, is_plurals):
    return map_to_content(content_to_map(file_content, True, is_plurals), is_plurals)

# Call this function to update the string tags for a resource.
def update_tags(to_lock):
    for key in to_lock:
        payload = {
            "data": {
                "attributes": {
                    "tags": to_lock[key]
                },
                "id": key,
                "type": "resource_strings"
            }
        }
        response = do_request(BASE_URL + "/resource_strings/" + key, payload, "PATCH")
        if "errors" in response:
            print_error(response["errors"])

# Call this function to remap screenshot mappings from branch_resource to base_resource
def clone_screenshots(base_resource, branch_resource):
    print("Checking screenshot remaps")
    url = BASE_URL + "/context_screenshot_maps?filter[project]=" + PROJECT_ID + "&filter[resource]=" + PROJECT_ID + ":r:" + branch_resource
    base_url = BASE_URL + "/context_screenshot_maps"
    base_payload  = {
        "data": {
            "attributes": {
                "width": -1,
                "height": -1,
                "coordinate_x": -1,
                "coordinate_y": -1
            },
            "relationships": {
                "context_screenshot": {
                    "data": {
                        "id": "",
                        "type": "context_screenshots"
                    }
                },
                "resource_string": {
                    "data": {
                        "id": "",
                        "type": "resource_strings"
                    }
                }
            },
            "type": "context_screenshot_maps"
        }
    }
    fails = 0
    while url != None:
        response = do_request(url)
        url = None
        if "errors" in response:
            print_error(response["errors"])
            fails += 1
        else:
            for screenshot in response["data"]:
                base_payload["data"]["relationships"]["resource_string"]["data"]["id"] = screenshot["relationships"]["resource_string"]["data"]["id"].replace(branch_resource, base_resource)
                base_payload["data"]["relationships"]["context_screenshot"]["data"]["id"] = screenshot["relationships"]["context_screenshot"]["data"]["id"]
                base_payload["data"]["attributes"]["width"] = screenshot["attributes"]["width"]
                base_payload["data"]["attributes"]["height"] = screenshot["attributes"]["height"]
                base_payload["data"]["attributes"]["coordinate_x"] = screenshot["attributes"]["coordinate_x"]
                base_payload["data"]["attributes"]["coordinate_y"] = screenshot["attributes"]["coordinate_y"]
                if base_payload["data"]["attributes"]["width"] == None:
                    base_payload["data"]["attributes"].pop("width")
                if base_payload["data"]["attributes"]["height"] == None:
                    base_payload["data"]["attributes"].pop("height")
                if base_payload["data"]["attributes"]["coordinate_x"] == None:
                    base_payload["data"]["attributes"].pop("coordinate_x")
                if base_payload["data"]["attributes"]["coordinate_y"] == None:
                    base_payload["data"]["attributes"].pop("coordinate_y")
                result = do_request(base_url, base_payload, "POST")
                if "errors" in result:
                    print_error(result["errors"])
                    return False
            if "next" in response["links"] and response["links"]["next"] != None:
                url = response["links"]["next"]
    if fails > 0:
        return False
    return True

# Call this function to add the latest updater/creator from branch_resource to base_resource
def add_updater(base_resource, branch_resource):
    print("Checking string creator/updater remaps")
    global branch_strings
    base_url = BASE_URL + "/resource_string_comments"
    base_payload = {
        "data": {
            "attributes": {
                "message": "",
                "type": "comment"
            },
            "relationships": {
                "language": {
                    "data": {
                        "id": "l:en",
                        "type": "languages"
                    }
                },
                "resource_string": {
                    "data": {
                        "id": "",
                        "type": "resource_strings"
                    }
                }
            },
            "type": "resource_string_comments"
        }
    }
    for string in branch_strings:
        user = get_username_from_id(branch_strings[string]["updater"])
        base_payload["data"]["attributes"]["message"] = "Creator/Updater: " + user
        base_payload["data"]["relationships"]["resource_string"]["data"]["id"] = branch_strings[string]["id"].replace(branch_resource, base_resource)
        result = do_request(base_url, base_payload)
        if "errors" in result:
            print_error(result["errors"])
            return False
    return True

# Call this function to clone the issues and comments from branch_resource to base_resource
def clone_comments(base_resource, branch_resource):
    print("Checking comment remaps")
    url = BASE_URL + "/resource_string_comments?filter[organization]=o:meganz-1&filter[resource]=" + PROJECT_ID + ":r:" + branch_resource
    base_url = BASE_URL + "/resource_string_comments"
    resolve_payload = {
        "data": {
            "attributes": {
                "status":"resolved"
            },
            "id": "",
            "type": "resource_string_comments"
        }
    }
    fails = 0
    payloads = []
    while url != None:
        response = do_request(url)
        url = None
        if "errors" in response:
            print_error(response["errors"])
            fails += 1
        else:
            for comment in response["data"]:
                base_payload = {
                    "data": {
                        "attributes": {
                            "category": "",
                            "message": "",
                            "type": "",
                            "priority": ""
                        },
                        "relationships": {
                            "language": {
                                "data": {
                                    "id": "",
                                    "type": "languages"
                                }
                            },
                            "resource_string": {
                                "data": {
                                    "id": "",
                                    "type": "resource_strings"
                                }
                            }
                        },
                        "type": "resource_string_comments"
                    },
                }
                string_id = comment["id"].replace(branch_resource, base_resource)
                state = comment["attributes"]["status"]
                message = comment["attributes"]["message"]
                message += "; Created by: " + get_username_from_id(comment["relationships"]["author"]["data"]["id"])
                if state == "resolved":
                    message += "; Resolved by: " + get_username_from_id(comment["relationships"]["resolver"]["data"]["id"])
                    message = message.replace("@", "")
                    base_payload["status"] = "resolved"
                elif "status" in base_payload:
                    base_payload.pop("status")
                base_payload["data"]["attributes"]["category"] = comment["attributes"]["category"]
                base_payload["data"]["attributes"]["message"] = message
                base_payload["data"]["attributes"]["type"] = comment["attributes"]["type"]
                base_payload["data"]["attributes"]["priority"] = comment["attributes"]["priority"]
                base_payload["data"]["relationships"]["language"]["data"]["id"] = comment["relationships"]["language"]["data"]["id"]
                base_payload["data"]["relationships"]["resource_string"]["data"]["id"] = string_id
                payloads.append(base_payload)
        if "next" in response["links"] and response["links"]["next"] != None:
            url = response["links"]["next"]
    for payload in reversed(payloads):
        resolved = "status" in payload and payload["status"] == "resolved"
        if "status" in payload:
            payload.pop("status")
        response = do_request(base_url, payload)
        if "errors" in response:
            print_error(response["errors"])
            return False
        if resolved:
            resolve_payload["data"]["id"] = response["data"]["id"]
            result = do_request(response["data"]["links"]["self"], resolve_payload, "PATCH")
            if "errors" in result:
                print_error(result["errors"])
                return False
    return True

# Call this function to attempt cloning translation reviewed status/plural translations from branch_resource to base_resource
def clone_status(base_resource, branch_resource):
    print("Checking translation status remaps")
    global branch_strings
    languages = get_languages()
    plurals = []
    for string in branch_strings:
        if branch_strings[string]["pluralised"]:
            plurals.append(string)
    translation_url = BASE_URL + "/resource_translations?filter[resource]=" + PROJECT_ID + ":r:" + branch_resource
    base_payload = {
        "data": {
            "attributes": {
                "reviewed": False,
                "strings": [],
            },
            "id": "",
            "type": "resource_translations"
        }
    }
    for language in languages:
        result = do_request(translation_url + "&filter[language]=" + language)
        if "errors" in result:
            print_error(result["errors"])
        else:
            for data in result["data"]:
                if data["attributes"]["reviewed"]:
                    base_payload["data"]["attributes"]["reviewed"] = True
                elif "reviewed" in base_payload["data"]["attributes"]:
                    base_payload["data"]["attributes"].pop("reviewed")
                if data["attributes"]["strings"] and data["relationships"]["resource_string"]["data"]["id"] in plurals:
                    base_payload["data"]["attributes"]["strings"] = data["attributes"]["strings"]
                elif "strings" in base_payload["data"]["attributes"]:
                    base_payload["data"]["attributes"].pop("strings")
                if len(base_payload["data"]["attributes"]):
                    id = data["id"].replace(branch_resource, base_resource)
                    base_payload["data"]["id"] = id
                    response = do_request(BASE_URL + "/resource_translations/" + id, base_payload, "PATCH")
                    if "errors" in response:
                        print_error(response["errors"])
    return True

# Call this function to clone the string tags from branch_resource to base_resource
def clone_tags(base_resource, branch_resource):
    print("Checking string tag remaps")
    global branch_strings
    base_url = BASE_URL + "/resource_strings/"
    base_payload = {
        "data": {
            "attributes": {
                "tags": [],
            },
            "id": "",
            "type": "resource_strings",
        },
    }
    for string in branch_strings:
        if branch_strings[string]["tags"]:
            new_key = branch_strings[string]["id"].replace(branch_resource, base_resource)
            base_payload["data"]["id"] = new_key
            base_payload["data"]["attributes"]["tags"] = branch_strings[string]["tags"]
            response = do_request(base_url + new_key, base_payload, "PATCH")
            if "errors" in response:
                print_error(response["errors"])
                return False
    return True


# Call this function to ensure all strings in branch_strings exist in base_strings
def verify_strings_exist():
    global base_strings
    global branch_strings
    if not base_strings or not branch_strings:
        return False
    for string in branch_strings:
        if string not in base_strings:
            return False
    return True

# Call this function to merge resource_content and branch_content into one file
def merge_strings(resource_content, branch_content, upload, is_plurals):
    full_map = content_to_map(resource_content, upload, is_plurals)
    part_map = content_to_map(branch_content, upload, is_plurals)
    for key in part_map:
        full_map[key] = part_map[key]
    return map_to_content(full_map, is_plurals)

# Call this function to check if a string mapping is equivalent to another
def strings_equal(string_a, string_b, is_plurals = False):
    if is_plurals:
        if string_a["ctx"] != string_b["ctx"]:
            return False
        if string_a["var"] != string_b["var"]:
            return False
        for key in string_a["str"]:
            if string_a["str"][key] != string_b["str"][key]:
                return False
    else:
        if string_a["c"] != string_b["c"]:
            return False
        if string_a["s"] != string_b["s"]:
            return False
    return True

# Call this function to return the children of the parent as pure XML
def subnodes_as_text(parent):
    node_value = ""
    for node in parent.childNodes:
        node_value = node_value + node.toxml()
    return node_value

# Call this function to convert a plist xml node to a plural string mapping
def get_plural_data(node, upload):
    map = {
        "var": subnodes_as_text(node.getElementsByTagName('string')[0]),
        "ctx": subnodes_as_text(node.getElementsByTagName('key')[1]),
        "str": {}
    }
    i = 0
    key = ""
    skip = 2
    data_dict = node.getElementsByTagName('dict')[0]
    while i < len(data_dict.childNodes):
        child = data_dict.childNodes[i]
        if child.nodeType == child.ELEMENT_NODE:
            if skip > 0:
                skip -= 1
            else:
                if child.tagName == "key":
                    key = subnodes_as_text(child)
                elif child.tagName == "string":
                    map["str"][key] = replace_characters(subnodes_as_text(child), upload)
        i += 1
    return map

# Call this function to convert a strings file to a strings mapping
def content_to_map(file_content, upload, is_plurals = False):
    map = {}
    if is_plurals:
        doc = parseString(file_content)
        root_dict = doc.getElementsByTagName('dict')[0]
        string_key = ""
        for node in root_dict.childNodes:
            if node.nodeType == node.ELEMENT_NODE:
                if node.tagName == "key":
                    string_key = subnodes_as_text(node)
                elif node.tagName == "dict":
                    map[string_key] = get_plural_data(node, upload)
    else:
        global unicode_regex
        file_content = re.sub(unicode_regex, '', file_content)
        lines = file_content.split("\n")
        i = 0
        context = ""
        while i < len(lines):
            lines[i] = lines[i].strip()
            if "/*" == lines[i][0:2] and "*/" == lines[i][-2:len(lines[i])]:
                context = lines[i][2:-2].strip()
            elif len(lines[i]) >= 6 and lines[i][0] == "\"" and lines[i][-1] == ";":
                parts = lines[i].split("=", 1)
                map[parts[0].strip()[1:-1]] = {
                    'c': context,
                    's': replace_characters(parts[1].strip()[1:-2], upload)
                }
            i += 1
    return map

# Call this function to convert a strings mapping to a strings file
def map_to_content(map, is_plurals = False):
    file = ""
    if is_plurals:
        file = []
        file.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        file.append("<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">")
        file.append("<plist version=\"1.0\">")
        file.append("<dict>")
        for key in map:
            file.append(tagify("key", key))
            file.append("<dict>")
            file.append(tagify("key", "NSStringLocalizedFormatKey"))
            file.append(tagify("string", map[key]["var"]))
            file.append(tagify("key", map[key]["ctx"]))
            file.append("<dict>")
            file.append(tagify("key", "NSStringFormatSpecTypeKey"))
            file.append(tagify("string", "NSStringPluralRuleType"))
            for sub_key in map[key]["str"]:
                file.append(tagify("key", sub_key))
                file.append(tagify("string", map[key]["str"][sub_key]))
            file.append("</dict>")
            file.append("</dict>")
        file.append("</dict>")
        file.append("</plist>")
        return indent_xml(file)
    else:
        for key in map:
            file += "/* " + map[key]["c"] + " */\n"
            file += "\"" + key + "\"=\"" + map[key]["s"] + "\";\n"
    return file.strip()

# Call this function to return a string of the given xml tag with the value
def tagify(tag, value):
    return "<" + tag + ">" + value + "</" + tag + ">"

# Call this function to check if the upload content is valid
def validate_file(file_content, is_plurals = False):
    valid = True
    if is_plurals:
        try:
            parseString(file_content)
        except ExpatError as ex:
            print("Error: Failed to parse stringsdict file: " + str(ex))
            valid = False
        return valid
    global unicode_regex
    file_content = re.sub(unicode_regex, '', file_content)
    lines = file_content.split("\n")
    i = 0
    while i < len(lines):
        lines[i] = lines[i].strip()
        if "/*" == lines[i][0:2] and "*/" == lines[i][-2:len(lines[i])]:
            i = i # No-op. Valid comment
        elif len(lines[i]) >= 6 and lines[i][0] == "\"" and lines[i][-1] == ";":
            parts = lines[i].split("=", 1)
            key = parts[0].strip()[1:-1]
            string = parts[1].strip()[1:-2]
            if len(key) > 0 and len(string) > 0:
                key_matches = re.search('(?<!\\\\)(?:\\\\{2})*"', key)
                string_matches = re.search('(?<!\\\\)(?:\\\\{2})*"', string)
                if key_matches != None or string_matches != None:
                    print("Error: Invalid quote escapes on line " + str(i + 1))
                    valid = False
            else:
                print("Error: Invalid string line for line " + str(i + 1))
                valid = False
        else:
            print("Error: Invalid comment or string entry on line " + str(i + 1))
            valid = False
        i += 1
    return valid

# Call this function to replace characters in a node/string with the correct version
def replace_characters(string, upload):
    replace = [
        r"'''",                                                # A. Triple prime
        r'(\W|^)"(\w)',                                        # B. Beginning double quote
        r'(“[^"]*)"([^"]*$|[^“"]*“)',                          # C. Ending double quote
        r'([^0-9])"',                                          # D. Remaining double quote at the end of word
        r"''",                                                 # E. Double prime as two single quotes
        r"(\W|^)'(\S)",                                        # F. Beginning single quote
        r"([A-z0-9])'([A-z])",                                 # G. Conjunction's possession
        r"(‘)([0-9]{2}[^’]*)(‘([^0-9]|$)|$|’[A-z])",           # H. Abbreviated years like '93
        r"((‘[^']*)|[A-z])'([^0-9]|$)",                        # I. Ending single quote
        r"(\B|^)‘(?=([^‘’]*’\b)*([^‘’]*\B\W[‘’]\b|[^‘’]*$))",  # J. Backwards apostrophe
        r'"',                                                  # K. Double prime
        r"'",                                                  # L. Prime
        r"\.\.\."                                              # M. Ellipsis
    ]
    replace_to = [
        r'‴',        # A
        r'\1“\2',    # B
        r'\1”\2',    # C
        r'\1”',      # D
        r'″',        # E
        r"\1‘\2",    # F
        r"\1’\2",    # G
        r"’\2\3",    # H
        r"\1’\3",    # I
        r"\1’",      # J
        r"″",        # K
        r"′",        # L
        r"…"         # M
    ]
    global xml_tag_regex
    tags = xml_tag_regex.findall(string)
    for i in range(len(tags)):
        string = string.replace(tags[i], " <t " + str(i) + "> ")
    if upload:
        string = string.replace("\r\n", "[Br]")
        string = string.replace("\r", "[Br]")
        string = string.replace("\n", "[Br]")
        string = string.replace(r"\r\n", "[Br]")
        string = string.replace(r"\r", "[Br]")
        string = string.replace(r"\n", "[Br]")
        string = string.replace("\\", "")
        for i in range(len(replace)):
            string = re.sub(replace[i], replace_to[i], string)
    else:
        string = re.sub(replace[12], replace_to[12], string)
        string = string.replace("[x]", "[X]")
        string = string.replace("[a]", "[A]")
        string = string.replace("[/a]", "[/A]")
        string = string.replace("[b]", "[B]")
        string = string.replace("[/b]", "[/B]")
        string = string.replace("[a1]", "[A1]")
        string = string.replace("[/a1]", "[/A2]")
        string = string.replace("[a2]", "[A2]")
        string = string.replace("[/a2]", "[/A2]")
        string = string.replace("[x1]", "[X1]")
        string = string.replace("[/x1]", "[/X1]")
        string = string.replace("[x2]", "[X2]")
        string = string.replace("[/x2]", "[/X2]")
        string = string.replace("\n", "")
        string = string.replace("\r", "")
        string = string.replace("[Br]", r"\n")

    for i in range(len(tags)):
        string = string.replace(" <t " + str(i) + "> ", tags[i])
    return string

# Call this function to correctly indent an XML string array with 2 spaces per indent
def indent_xml(lines):
    result = ""
    padding = 0
    for i in range(len(lines)):
        token = lines[i].lstrip()
        matches = re.search(r'.+<\/\w[^>]*>$', token)
        if matches == None:
            matches = re.search(r'^<\/\w', token)
            if matches == None:
                matches = re.search(r'^<\w[^>]*[^\/]>.*$', token)
                if matches == None:
                    indent = 0
                else:
                    indent = 2
            else:
                padding -= 2
                indent = 0
        else:
            indent = 0
        line = token.rjust(len(token) + padding, ' ')
        result = result + line + "\n"
        padding += indent
    return result.strip()

# Call this function to store a resource file in the correct directory
def store_file(resource, content, lang = "Base"):
    if lang in REMAPPED_CODE:
        lang = REMAPPED_CODE[lang]
    file_path = PROD_FOLDER
    if "LTHPasscodeViewController" in resource:
        if lang == "Base":
            file_path += "../Vendor/LTHPasscodeViewController/Localizations/LTHPasscodeViewController.bundle/" + lang + ".lproj/LTHPasscodeViewController.strings"
        else:
            file_path = DOWNLOAD_FOLDER + "LTHPasscodeViewController.strings-" + lang
    elif "Changelogs" in resource:
        file_path = DOWNLOAD_FOLDER + "Changelogs.strings-" + lang
    else:
        file_path += lang + ".lproj/" + get_file_basename(resource)
    print("Saving file " + file_path)
    file_put_contents(file_path, content)
    if lang == "Base" and ("Localizable" in resource or "InfoPlist" in resource or "Plurals" in resource):
        file_put_contents(file_path.replace("Base", "en"), content)

# Wrapper to write content to file
def file_put_contents(filepath, content):
    with open(filepath, "w") as file:
        return file.write(content) > 0

# Wrapper to read content from file
def file_get_contents(filepath):
    with open(filepath, "r") as file:
        content = file.read()
    return content

# Call this function to return a resource name based on the current git branch
def get_branch_name():
    global git_path
    cur_path = os.getcwd()
    os.chdir(git_path)
    branch_name = subprocess.check_output(['git', 'symbolic-ref', '--short', '-q', 'HEAD'], universal_newlines=True).strip()
    os.chdir(cur_path)
    if branch_name in ["master", "develop"]:
        return False
    return re.sub('[^A-Za-z0-9]+', '', branch_name)

# Call this function to return the general file name for the given resource
def get_file_basename(resource):
    if "Plurals" in resource:
        return resource.replace("Plurals", "Localizable") + ".stringsdict"
    else:
        return resource + ".strings"

# Call this function to log errors from the Transifex API
def print_error(errors):
    for error in errors:
        code = "(missing error code)"
        if "status" in error:
            code = error["status"]
        elif "code" in error:
            code = error["code"]
        print("Error: {}: {}.".format(code, error["detail"]))

# Call this function to download the content for the stores resource
def run_download_stores():
    print("Downloading stores resource")
    content = resource_get_english(STORES_IOS_ID, True) # Not a plurals resource but is not UTF-16 encoded
    if content:
        file_put_contents(DOWNLOAD_FOLDER + "/stores-ios.yaml", content)
    else:
        print("Error: Failed to retrieve stores strings")
    return False

# Call this function to upload the content for a stores resource
def run_upload_stores(content):
    if content:
        now = int(datetime.datetime.utcnow().strftime("%s")) - 30
        print("Uploading to stores resource")
        if resource_put_english(STORES_IOS_ID, content):
            return run_lock(STORES_IOS_ID, now, True)
        else:
            print("Error: Failed to update the android stores resource file")
        return False
    else:
        print("Error: No file content present")
        return False

# Parses arguments and runs relevant mode
def main():
    print("--- Transifex Language Management ---")
    parser = argparse.ArgumentParser()
    parser.add_argument("-m", "--mode", nargs=1, help="The mode of the script to run", type=str)
    parser.add_argument("-d", "--download", nargs="?", help="Downloads the given resource as a file", const=True, default=False)
    parser.add_argument("-u", "--upload", nargs="?", help="Uploads the given file", const=True, default=False)
    parser.add_argument("-r", "--resource", nargs=1, help="The Transifex resource to perform the action for")
    parser.add_argument("-b", "--branch", nargs="?", help="The Transifex branch resource to perform the action for", const=True, default=False)
    parser.add_argument("-f", "--file", nargs=1, help="The file to process or output to")
    args = parser.parse_args()
    if args.mode:
        mode = args.mode[0].lower()
        if mode == "download":
            resource = "Localizable"
            branch = get_branch_name()
            if args.resource and args.branch:
                resource = args.resource[0]
                branch = args.branch
                run_merge(resource, branch)
            elif args.resource:
                if args.resource[0] == "all":
                    run_fetch()
                elif args.resource[0] == "stores":
                    run_download_stores()
                else:
                    run_download(args.resource[0], PROD_FOLDER)
            else:
                if branch:
                    branch = "Localizable-" + branch
                    run_merge(resource, branch)
                else:
                    print("Error: Cannot merge resources for develop/master branch")
        elif mode == "upload":
            branch = get_branch_name()
            if not branch and not args.resource:
                print("Error: Cannot update unspecified resource for develop/master branch")
            elif args.resource:
                resource = args.resource[0]
                file_name = get_file_basename(resource)
                if "LTHPasscodeViewController" in resource:
                    file_path = PROD_FOLDER + "../Vendor/LTHPasscodeViewController/Localizations/LTHPasscodeViewController.bundle/Base.lproj/" + file_name
                    branch = False
                elif "Changelogs" in resource:
                    file_path = DOWNLOAD_FOLDER + "Changelogs.strings-Base"
                    branch = False
                else:
                    file_path = PROD_FOLDER + "Base.lproj/" + file_name
                if args.file:
                    file_path = args.file[0]
                if os.path.exists(file_path):
                    content = file_get_contents(file_path)
                    if resource == "stores":
                        run_upload_stores(content)
                    else:
                        run_upload(content, resource, branch)
                else:
                    print("Error: Can not locate file for the specified resource")
            else:
                print("Error: No resource specified for -r/--resource")
        elif mode == "branch":
            if args.resource:
                run_branch(args.resource[0])
            else:
                run_branch("Localizable")
        elif mode == "lock":
            if args.resource:
                if args.resource[0] in RESERVED_RESOURCES:
                    print("Error: Cannot lock a reserved resource")
                else:
                    run_lock(args.resource[0])
            else:
                print("Error: No resource specified")
        elif mode == "unlock":
            if args.resource:
                run_unlock(args.resource[0])
            else:
                print("Error: No resource specified")
        elif mode == "list":
            resources = get_resources()
            for resource in resources:
                data = ""
                if resources[resource]["name"] in RESERVED_RESOURCES:
                    data = "Reserved resource. "
                data = data + "Name: " + resources[resource]["name"] + ". ID: " + resource + ". String count: " + str(resources[resource]["strings"])
                print(data)
        elif mode == "close":
            if args.resource and args.branch:
                run_close(args.resource[0], args.branch)
            else:
                print("Error: No resources specified")
        elif mode == "fetch":
            run_fetch()
        elif mode == "export":
            run_export(args.branch)
        elif mode == "lang":
            resource = "Localizable"
            if args.resource:
                resource = args.resource[0]
            run_export(True, resource)
        elif mode == "comment":
            if args.resource:
                run_comment(args.resource[0])
            else:
                print("Error: No resource specified")
        elif mode == "clean":
            run_pruning()
    elif args.download:
        resource = "Localizable"
        branch = get_branch_name()
        if args.resource and args.branch:
            resource = args.resource[0]
            branch = args.branch
            run_merge(resource, branch)
        elif args.resource:
            if args.resource[0] == "all":
                run_fetch()
            elif args.resource[0] == "stores":
                run_download_stores()
            else:
                run_download(args.resource[0], PROD_FOLDER)
        else:
            if branch:
                branch = "Localizable-" + branch
                run_merge(resource, branch)
            else:
                print("Error: Cannot merge resources for develop/master branch")
    elif args.upload:
        branch = get_branch_name()
        if not branch and not args.resource:
            print("Error: Cannot update unspecified resource for develop/master branch")
        elif args.resource:
            resource = args.resource[0]
            file_name = get_file_basename(resource)
            if "LTHPasscodeViewController" in resource:
                file_path = PROD_FOLDER + "../Vendor/LTHPasscodeViewController/Localizations/LTHPasscodeViewController.bundle/Base.lproj/" + file_name
                branch = False
            elif "Changelogs" in resource:
                file_path = DOWNLOAD_FOLDER + "Changelogs.strings-Base"
                branch = False
            else:
                file_path = PROD_FOLDER + "Base.lproj/" + file_name
            if args.file:
                file_path = args.file[0]
            if os.path.exists(file_path):
                content = file_get_contents(file_path)
                if resource == "stores":
                    run_upload_stores(content)
                else:
                    run_upload(content, resource, branch)
            else:
                print("Error: Can not locate file for the specified resource")
        else:
            print("Error: No resource specified for -r/--resource")
    else:
        print("Error: Invalid script mode.")
    os._exit(0)

try:
    main()
except KeyboardInterrupt:
    os._exit(1)
