<?php
include __DIR__.'/packageLoader.php';
$config = file_get_contents('transifexConfig.json');
$configDecode = json_decode($config, true);
$token = getenv('TRANSIFEX_TOKEN') ?: $configDecode['apiToken'];
$gitlabToken = getenv('GITLAB_TOKEN') ?: $configDecode['gitLabToken'];
$loader = new PackageLoader\PackageLoader();
$loader->load(__DIR__."/custom_vendor/CFPropertyList");

define("TRANSIFEX_API_TOKEN", $token);
define("GITLAB_TOKEN", $gitlabToken);
define("ORGANIZATION", $configDecode['organization']);
define("PROJECT", $configDecode['project']);

const ALL_LANGUAGES_URL = "https://rest.api.transifex.com/projects/o:" . ORGANIZATION . ":p:" . PROJECT . "/languages";
const ALL_RESOURCES_URL = "https://rest.api.transifex.com/resources?filter[project]=o:" . ORGANIZATION . ":p:" . PROJECT;
const APPLICATION_JSON_HEADER = ["Content-Type: application/vnd.api+json", "Authorization: Bearer " . TRANSIFEX_API_TOKEN];
const MAIN_LOCALIZABLE_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/repository/files/iMEGA%2FLanguages%2FBase.lproj%2FLocalizable.strings/raw?ref=develop";
const MAIN_PLURALS_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/repository/files/iMEGA%2FLanguages%2FBase.lproj%2FLocalizable.stringsdict/raw?ref=develop";
const MAIN_INFOPLIST_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/repository/files/iMEGA%2FLanguages%2FBase.lproj%2FInfoPlist.strings/raw?ref=develop";

const CHANGELOGS_PATH = "";
const INFOPLIST_PATH = "../iMEGA/Languages/Base.lproj/InfoPlist.strings";
const LOCALIZABLE_PATH = "../iMEGA/Languages/Base.lproj/Localizable.strings";
const PLURALS_PATH = "../iMEGA/Languages/Base.lproj/Localizable.stringsdict";
const LTHPASSCODEVIEWCONTROLLER_PATH = "../iMEGA/Vendor/LTHPasscodeViewController/Localizations/LTHPasscodeViewController.bundle/Base.lproj/LTHPasscodeViewController.strings";

error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING);

function getGitLabResourceFile($url){
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_HTTPGET, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["PRIVATE-TOKEN: " . GITLAB_TOKEN]);
    $result = curl_exec($ch);
    if($responseJson = json_decode($result,true) != null){
        if($responseJson['Message'] == "401 Unauthorized"){
            die("Please enter a valid gitlab token in config.\n");
        }
        die($responseJson['message']);
    }
    curl_close($ch);
    return $result;
}

function stripQuotes($text)
{
    return preg_replace('/^(\'(.*)\'|"(.*)")$/', '$2$3', $text);
}

/**
 * Create a new resource on Transifex
 *
 * @param $resourceName
 * @param $force
 */
function createNewResource($resourceName,$isPlural)
{
    $resourceSlug = strtolower($resourceName);
    if($isPlural){
        $id = "STRINGSDICT";
    }else{
        $id = "STRINGS";
    }
    $postData = '{
        "data": {
            "attributes": {
                "accept_translations": true,
      "name": "' . $resourceName . '",
      "slug": "' . $resourceSlug . '"
    },
    "relationships": {
                "i18n_format": {
                    "data": {
                        "id": "' . $id . '",
          "type": "i18n_formats"
        }
      },
      "project": {
                    "data": {
                        "id": "o:' . ORGANIZATION . ":p:" . PROJECT . '",
          "type": "projects"
        }
      }
    },
    "type": "resources"
  }
}';

    $ch = curl_init("https://rest.api.transifex.com/resources");
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["Content-Type: application/vnd.api+json", "Authorization: Bearer " . TRANSIFEX_API_TOKEN]);
    $result = curl_exec($ch);
    $response = json_decode($result, true);
    if ($response['errors'][0]['status'] === '409') {
        do {
            $cmd = trim(strtolower(readline("\n \n>Resource already exists, do you want to force push?: (y/n)\n")));
            readline_add_history($cmd);
            if ($cmd == 'q' || $cmd == 'n') {
                die();
            }
            if($cmd == 'y') {
                return false;
            }
        }while ($cmd != 'q' && $cmd != 'y');
    }
    echo("Created new Resource: {$resourceName}.\n");
    curl_close($ch);
}


/**
 * Check if resource exists
 *
 * @param $resourceSlug
 * @return bool
 */
function getResourceDetails($resourceSlug)
{
    $ch = curl_init("https://rest.api.transifex.com/resources/o:" . ORGANIZATION . ":p:" . PROJECT . ":r:" . $resourceSlug);

    //Check upload
    curl_setopt($ch, CURLOPT_HTTPGET, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["Authorization: Bearer " . TRANSIFEX_API_TOKEN]);

    $result = curl_exec($ch);
    $responseJson = json_decode($result, true);


    if (isset($responseJson['errors'])) {
        foreach ($responseJson['errors'] as $error) {
            echo "Error {$error['status']}: {$error['detail']}.\n";
        }
        die("File name should be the name of the resource (Case Sensitive).\n");
    }
    return true;
}

function trimUnicode($str)
{
    return preg_replace('/^[\pZ\pC]+|[\pZ\pC]+$/u', '', $str);
}

/**
 * Parses apple strings format and returns an associative array of:
 *  * [
 *    stringKey => [
 *          'stringText' => stringText,
 *          'stringDescription' => stringDescription,
 *      ],
 * ]
 *
 * @param $resourceString
 * @return array
 */
function parseAppleStrings($resourceString): array
{
    $genericMapping = [];
    $context = "";

    foreach (explode("\n", $resourceString) as $line) {
        if (strpos($line, "*/")) {
            $context = trim($line);
            $context = ltrim($context, "/*");
            $context = substr($context, 0, strlen($context) - 2);
            $context = ltrim($context, "*");
            continue;
        }
        if (strncmp(trim($line), "//", 2) == 0) {
            $context = ltrim($line, "/ ") . "\n";
            continue;
        }

        if ($line[0] != '"') {
            continue;
        }

        list($stringKey, $stringText) = explode("=", $line, 2);

        for ($i = strlen($stringText) - 1; $i >= 0 && $stringText[$i] != ';'; --$i) {
            continue;
        }

        $stringText = substr($stringText, 0, $i);
        if (substr($stringText, -1) != '"') {
            echo "Failed to parse: `\n\n$line`. Please fix and re-export.\n";
            continue;
        }

        $stringText = trim(trim($stringText), ";*");
        $stringText = stripQuotes($stringText);
        $stringKey = trim(trim($stringKey), ";\"\'");

        if (preg_match('/(?<!\\\\)(?:\\\\{2})*\K"/', $stringText) || preg_match('/(?<!\\\\)(?:\\\\{2})*\K"/', $stringKey)) {
            die("Invalid String Syntax, make sure you are using escape characters for strings.\n");
        }

        $sanitisedStringText = sanitiseSingleResourceString($stringText);
        $genericMapping[$stringKey] = [
            "stringText" => $sanitisedStringText,
            "stringDescription" => $context
        ];
    }
    return $genericMapping;
}

/**
 * Sanitise string text (html tags and quotes, elipses)
 *
 * @param $str
 * @return array|string|string[]
 */
function sanitiseSingleResourceString($str)
{
    $replace = [
        "#'''#",                                                // A. Triple prime
        '#(\W|^)"(\w)#',                                        // B. Beginning double quote
        '#(“[^"]*)"([^"]*$|[^“"]*“)#',                          // C. Ending double quote
        '#([^0-9])"#',                                          // D. Remaining double quote at the end of word
        "#''#",                                                 // E. Double prime as two single quotes
        "#(\W|^)'(\S)#",                                        // F. Beginning single quote
        "#([A-z0-9])'([A-z])#",                                 // G. Conjunction's possession
        "#(‘)([0-9]{2}[^’]*)(‘([^0-9]|$)|$|’[A-z])#",           // H. Abbreviated years like '93
        "#((‘[^']*)|[A-z])'([^0-9]|$)#",                        // I. Ending single quote
        "#(\B|^)‘(?=([^‘’]*’\b)*([^‘’]*\B\W[‘’]\b|[^‘’]*$))#",  // J. Backwards apostrophe
        '#"#',                                                  // K. Double prime
        "#'#",                                                  // L. Prime
        "#\.\.\.#"                                              // M. Ellipsis
    ];

    $replaceTo = [
        '‴',        // A
        '$1“$2',    // B
        '$1”$2',    // C
        '$1”',      // D
        '″',        // E
        "$1‘$2",    // F
        "$1’$2",    // G
        "’$2$3",    // H
        "$1’$3",    // I
        "$1’",      // J
        "″",        // K
        "′",        // L
        "…"         // M
    ];

    preg_match_all('/<[^sd][^>]*>/', $str, $tags);

    $text = $str;
    if ($tags[0]) {
        foreach ($tags[0] as $key => $value) {
            $text = str_replace($value, " <t " . $key . "> ", $text);
        }
    }
    $text = preg_replace($replace, $replaceTo, $text);
    $text = str_replace('\r', '[Br]', str_replace('\n', '[Br]', str_replace('\r\n', '[Br]', $text)));
    $text = stripslashes($text);
    if ($tags[0]) {
        foreach ($tags[0] as $key => $value) {
            $text = str_replace(" <t " . $key . "> ", $value, $text);
        }
    }

    return $text;
}

/**
 * Builds the .strings file from the merged resource array mapping.
 *
 * @param $resourceMapping
 * @return String
 */
function buildResourceFileFromArray($resourceMapping): string
{
    $finalContent = "";
    foreach ($resourceMapping as $key => $value) {
        $finalContent .= "/*{$value['stringDescription']}*/\n";
        $finalContent .= "\"{$key}\"=\"{$value['stringText']}\";\n";
    }
    return $finalContent;
}

function addNewSourceFile($stringsToPush, $resourceName,$isPlural)
{
    // Todo build the new source here (we create our own content from the diff).
    $resourceSlug = strtolower($resourceName);

    if (!mb_detect_encoding($stringsToPush, 'UTF-8', true)) {
        $stringsToPush = mb_convert_encoding($stringsToPush, "UTF-8", "UTF-16LE");
    }
    if(!$isPlural) {
        $resourceMapping = parseAppleStrings(trimUnicode($stringsToPush));
        $stringsToPush = buildResourceFileFromArray($resourceMapping);
    }

    $stringsToPush = json_encode($stringsToPush, JSON_UNESCAPED_UNICODE);

    $postData = '{
  "data": {
    "attributes": {
      "content": ' . $stringsToPush . ',
      "content_encoding": "text"
    },
    "relationships": {
      "resource": {
        "data": {
          "id": "o:' . ORGANIZATION . ":p:" . PROJECT . ":r:" . $resourceSlug . '",
          "type": "resources"
        }
      }
    },
    "type": "resource_strings_async_uploads"
  }
}';

    // Upload source file for that project -> language
    $ch = curl_init("https://rest.api.transifex.com/resource_strings_async_uploads");
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["Content-Type: application/vnd.api+json", "Authorization: Bearer " . TRANSIFEX_API_TOKEN]);
    $result = curl_exec($ch);

    $response = json_decode($result, true);

    $link = $response['data']['links']['self'];

    curl_close($ch);

    if (isset($response['errors'])) {
        foreach ($response['errors'] as $error) {
            echo "Error {$error['status']}: {$error['detail']}.\n";
        }
        die();
    }
    $ch = curl_init($link);

    //Check upload
    curl_setopt($ch, CURLOPT_HTTPGET, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["Authorization: Bearer " . TRANSIFEX_API_TOKEN]);

    while (true) {
        $result = curl_exec($ch);
        $resultDecode = json_decode($result, true);
        if ($resultDecode['data']['attributes']['status'] != "pending" || $resultDecode['data']['attributes']['status'] != "processing" || $resultDecode['data']['attributes']['status'] != "failed") {
            foreach ($resultDecode['data']['attributes']['errors'] as $error) {
                echo "Error {$error['code']}: {$error['detail']}.\n";
            }
            break;
        }
        sleep(1);
    }
    curl_close($ch);
    echo "Uploaded source file for resource {$resourceName}.\n";
}

function getDiffOfResource($gitlabArr,$ourStringsArr){
    $stringsToPush = "";

    foreach($ourStringsArr as $ourStringsKey => $ourStringsValue){
        if(!isset($gitlabArr[$ourStringsKey])){
            $stringsToPush .= "/*{$ourStringsValue['stringDescription']}*/\n";
            $stringsToPush .= "\"{$ourStringsKey}\"=\"{$ourStringsValue['stringText']}\";\n";
        }else{
            if($gitlabArr[$ourStringsKey]['stringDescription'] != $ourStringsValue['stringDescription'] ||
                $gitlabArr[$ourStringsKey]['stringText'] != $ourStringsValue['stringText'] ){
                $stringsToPush .= "/*{$ourStringsValue['stringDescription']}*/\n";
                $stringsToPush .= "\"{$ourStringsKey}\"=\"{$ourStringsValue['stringText']}\";\n";
            }
        }
    }
    return $stringsToPush;
}

/**
 * Generic multi curl request to batch curl requests for performance
 *
 * @param $method
 * @param $requests
 * @param $headers
 * @param $url
 * @return array
 */
function makeGenericMultiCurlRequest($method, $requests = null, $headers, $urls): array
{
    // array of all curls
    $multiCurl = array();
    // data to be returned
    $result = array();
    // multi handle
    $mh = curl_multi_init();
    $i = 0;
    foreach ($urls as $key => $url) {
        $options = array(
            CURLOPT_IPRESOLVE => CURL_IPRESOLVE_V4,
            CURLOPT_POSTFIELDS => $requests[$key],
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_ENCODING => '',
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_URL => $url
        );
        $multiCurl[$i] = curl_init();
        curl_setopt_array($multiCurl[$i], $options);
        curl_multi_add_handle($mh, $multiCurl[$i]);
        $i++;
    }

    $index = null;
    do {
        curl_multi_exec($mh, $index);
    } while ($index > 0);
    // get content and remove handles
    foreach ($multiCurl as $k => $ch) {
        $responseJson = json_decode(curl_multi_getcontent($ch), true);
        if (isset($responseJson['errors'])) {
            foreach ($responseJson['errors'] as $error) {
                echo "Error {$error['status']}: {$error['detail']}.\n";
            }
            die();
        }
        $result[$k] = $responseJson;
        curl_multi_remove_handle($mh, $ch);
    }
    // close
    curl_multi_close($mh);
    return $result;
}

function getLockedLangCodes(){
    $arrOfLangCodes = [];
    $ch = curl_init("https://rest.api.transifex.com/projects/o:" . ORGANIZATION . ":p:" . PROJECT . "/languages");
    curl_setopt($ch, CURLOPT_HTTPGET, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["Content-Type: application/vnd.api+json", "Authorization: Bearer " . TRANSIFEX_API_TOKEN]);
    $result = curl_exec($ch);
    $responseJson = json_decode($result, true);
    if (isset($responseJson['errors'])) {
        foreach ($responseJson['errors'] as $error) {
            echo "Error {$error['status']}: {$error['detail']}.\n";
        }
        die();
    }
    curl_close($ch);
    foreach($responseJson as $data) {
        foreach ($data as $val) {
            $arrOfLangCodes[] = "locked_" . $val['attributes']['code'];
        }
    }
    return $arrOfLangCodes;
}

// get array of string hashes from transifex by providing an array of string keys.
function getStringHash($stringKeys, $branchResourceName){
    $urls = [];
    $hashes = [];
    foreach($stringKeys as $key) {
        $urls[] = "https://rest.api.transifex.com/resource_strings?filter[resource]=o:" . ORGANIZATION . ":p:" . PROJECT . ":r:" . strtolower($branchResourceName) . "&filter[key]=" . urlencode($key);
    }
    $result =  makeGenericMultiCurlRequest("GET",null,APPLICATION_JSON_HEADER,$urls);
    foreach($result as $res) {
        if(count($res['data'][0]['attributes']['tags']) == 0 && strtotime($res['data'][0]['attributes']['strings_datetime_modified']) >= time() - 120)
        $hashes[] = $res['data'][0]['id'];
    }
    return $hashes;
}

function updateStringLock($hashes, $arrLangCodes){
    $urls = [];
    $reqs = [];
    $arrLangCodes[] = "do_not_translate";
    foreach($hashes as $hash){
        $urls[] = "https://rest.api.transifex.com/resource_strings/" . $hash;
        $reqs[] = '{
  "data": {
    "attributes": {
      "tags": ' . json_encode($arrLangCodes) . '
    },
    "id": "'. $hash .'",
    "type": "resource_strings"
  }
}';
    }
    $res = makeGenericMultiCurlRequest("PATCH",$reqs,APPLICATION_JSON_HEADER,$urls);
}

/**
 * Converts string to file stream for reading into CFPropertyList
 *
 * @param string $string
 * @return false|resource
 */
function strToStream(string $string)
{
    $stream = fopen('php://memory','r+');
    fwrite($stream, $string);
    rewind($stream);
    return $stream;
}

function resourceChooser(): string
{
    do{
        echo "\n1. Changelogs \n2. Localizable \n3. InfoPlist \n4. LTHPasscodeViewController \n5. Plurals \n6. (q) to quit";
        $cmd = trim(strtolower(readline("\n \n> Which resource would you want to import (Enter the digit):\n")));
        readline_add_history($cmd);
        if ($cmd == 'q' || $cmd == '6') {
            exit;
        }
        switch(strtolower($cmd)){
            case '1' :
                return CHANGELOGS_PATH;
            case '2':
                return LOCALIZABLE_PATH;
            case '3':
                return INFOPLIST_PATH;
            case '4':
                return LTHPASSCODEVIEWCONTROLLER_PATH;
            case '5':
                return PLURALS_PATH;
            case '6':
                exit;
        }
    }while ($cmd != 'q');
}

$filePath = resourceChooser();

// changelogs case
if($filePath == "") {
    $cmd = readline("\n \n> Please enter Changelogs path: \n");
    readline_add_history($cmd);
    $filePath = $cmd;
}

// check for file existing
if (!file_exists($filePath)) {
    echo "Incorrect source file path: $filePath does not exist.\n";
    die();
}

$fileParts = pathinfo($filePath);

// check for correct extension
if ($fileParts['extension'] !== "strings" && $fileParts['extension'] !== "stringsdict") {
    echo "Please use .strings or .stringsdict extension for source file.\n";
    die();
}

// Push to main resource file directly
if($fileParts['filename'] == "Changelogs" || $fileParts['filename'] == "LTHPasscodeViewController" ){
    echo "Updating Main Resource as file is Changelogs/LTHPassCodeViewController and not updated often.\n";
    addNewSourceFile(file_get_contents($filePath), $fileParts['filename'],false);
    die();
}

$branchName = trim(`git branch --show-current`);

if ($branchName == "" || $branchName == null) {
    die("You are currently not on a branch, please switch to the branch you are working on.\n");
}

echo "Note: You are currently on branch {$branchName}.\n";
if (in_array(str_replace(PHP_EOL, "", $branchName), ["master", "develop"])) {
    echo PHP_EOL . "Error: Updating string is not allowed in this branch." . PHP_EOL;
    return false;
}

// get the gitlab strings for comparisons
$stringsToPush = "";
// TODO change for testing
$ourStrings =  file_get_contents($filePath);

$gitlabResourceStrings = "";
if($fileParts['filename'] == "InfoPlist"){
    $gitlabResourceStrings = getGitLabResourceFile(MAIN_INFOPLIST_URL);
}else if ($fileParts['filename'] == "Localizable" && $fileParts['extension'] == 'strings'){
    $gitlabResourceStrings = getGitLabResourceFile(MAIN_LOCALIZABLE_URL);
}else if ($fileParts['filename'] == "Localizable" && $fileParts['extension'] == 'stringsdict'){
    // TODO, change when pushed, for testing
    $gitlabResourceStrings = getGitLabResourceFile(MAIN_PLURALS_URL);
}
// parse
if($fileParts['extension'] == "strings"){
    $gitlabResArr =  parseAppleStrings(trimUnicode($gitlabResourceStrings));
    $ourStringsArr = parseAppleStrings(trimUnicode($ourStrings));
    $stringsToPush = getDiffOfResource($gitlabResArr,$ourStringsArr);
}else if ($fileParts['extension'] == "stringsdict"){
// TODO stringsdict format
    $gitlabStrings = new CFPropertyList\CFPropertyList(strToStream($gitlabResourceStrings), CFPropertyList\CFPropertyList::FORMAT_XML );
    $localStrings = new CFPropertyList\CFPropertyList(strToStream($ourStrings), CFPropertyList\CFPropertyList::FORMAT_XML );
    $stringsToPush = new CFPropertyList\CFPropertyList(null, CFPropertyList\CFPropertyList::FORMAT_XML );
    // Add or replace, depending if upper key exists.
    $localStringsDict = $localStrings->getValue();
    $gitlabStringsDict = $gitlabStrings->getValue();
    $stringsToPushDict = new \CFPropertyList\CFDictionary([]);
    foreach( $localStrings->getValue(true) as $newKeys => $newValues )
    {
        // if outer key exists in gitlabString, we have to check if it is an edit, if there are edited fields, we add it, otherwise, if identical, we omit.
        if($existDict = $gitlabStringsDict->get($newKeys)) {
            // check equality of fields via array equality
            $addDict = $localStringsDict->get($newKeys);
            $addArray = $addDict->toArray();
            $existArray = $existDict->toArray();
            $areEqual = $addArray === $existArray;
            if($areEqual) {
                // skip if equal (do not add)
                continue;
            }
            else {
                // sanitising code
                foreach($newValues->getValue(true) as $key => $value) {
                    if($value->getValue(true) && is_array($value->getValue(true)) ) {
                        foreach($value->getValue(true) as $innerKey => $innerValue) {
                            $innerValue->setValue(sanitiseSingleResourceString(trimUnicode($innerValue->getValue(true))));
                        }
                    } else {
                        $value->setValue(sanitiseSingleResourceString(trimUnicode($value->getValue(true))));
                    }
                }
                // adding code
                $stringsToPushDict->add($newKeys,$newValues);
                $stringsToPush->purge();
                $stringsToPush->add($stringsToPushDict);
            }
        }
        else {   // completely new key, we can just sanitise and add
            // sanitising code
            foreach($newValues->getValue(true) as $key => $value) {
                if($value->getValue(true) && is_array($value->getValue(true)) ) {
                    foreach($value->getValue(true) as $innerKey => $innerValue) {
                        $innerValue->setValue(sanitiseSingleResourceString(trimUnicode($innerValue->getValue(true))));
                    }
                } else {
                    $value->setValue(sanitiseSingleResourceString(trimUnicode($value->getValue(true))));
                }
            }
            // adding code
            $stringsToPushDict->add($newKeys,$newValues);
            $stringsToPush->purge();
            $stringsToPush->add($stringsToPushDict);
        }
    }
    $stringsToPush = $stringsToPush->toXML(true);
}
$branchResourceName = "";
if($fileParts['filename'] == "Localizable" && $fileParts['extension'] == 'stringsdict') {
    $branchResourceName = "Plurals". "-" . preg_replace("/[^A-Za-z0-9]/", '', $branchName);
} else {
    $branchResourceName = $fileParts['filename'] . "-" . preg_replace("/[^A-Za-z0-9]/", '', $branchName);
}

$shouldLock = true;
if($argv[1] && $argv[1] === 'nolock'){
    $shouldLock = false;
}
// TODO stringsdict file when they upload to gitlab
if (getResourceDetails(strtolower($fileParts['filename']))) {
    if ($fileParts['extension'] == "strings") {
        createNewResource($branchResourceName,false);
        addNewSourceFile($stringsToPush, $branchResourceName,false);
    } else if ($fileParts['extension'] == "stringsdict") {
        createNewResource($branchResourceName,true);
        addNewSourceFile($stringsToPush, $branchResourceName,true);
    }
    if ($shouldLock) {
        $stringsToPushKeys = [];
        sleep(5);
        if ($fileParts['extension'] == "strings") {
            $stringsToPushKeys = array_keys(parseAppleStrings($stringsToPush));
        }
        else if($fileParts['extension'] == "stringsdict") {
            $stringsToPushXML =  new CFPropertyList\CFPropertyList(strToStream($stringsToPush), CFPropertyList\CFPropertyList::FORMAT_XML );
            $stringsToPushArr = $stringsToPushXML->toArray();
            $stringsToPushKeys = array_keys($stringsToPushArr);
        }
        $hashes = getStringHash($stringsToPushKeys, $branchResourceName);
        $arrLangCodes = getLockedLangCodes();
        updateStringLock($hashes, $arrLangCodes);
    }
} else {
    echo "File name should be the name of the resource (Case Sensitive).\n";
    die();
}
?>
