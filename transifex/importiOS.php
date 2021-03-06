<?php
$config = file_get_contents('transifexConfig.json');
$configDecode = json_decode($config, true);
$token = getenv('TRANSIFEX_TOKEN') ?: $configDecode['apiToken'];
$gitlabToken = getenv('GITLAB_TOKEN') ?: $configDecode['gitLabToken'];

define("TRANSIFEX_API_TOKEN", $token);
define("GITLAB_TOKEN", $gitlabToken);
define("ORGANIZATION", $configDecode['organization']);
define("PROJECT", $configDecode['project']);

const ALL_LANGUAGES_URL = "https://rest.api.transifex.com/projects/o:" . ORGANIZATION . ":p:" . PROJECT . "/languages";
const ALL_RESOURCES_URL = "https://rest.api.transifex.com/resources?filter[project]=o:" . ORGANIZATION . ":p:" . PROJECT;

const MAIN_LOCALIZABLE_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/repository/files/iMEGA%2FLanguages%2FBase.lproj%2FLocalizable.strings/raw?ref=develop";
const MAIN_INFOPLIST_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/repository/files/iMEGA%2FLanguages%2FBase.lproj%2FInfoPlist.strings/raw?ref=develop";

error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING);

function getGitLabResourceFile($url){
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_HTTPGET, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["PRIVATE-TOKEN: " . GITLAB_TOKEN]);
    $result = curl_exec($ch);
    if($responseJson = json_decode($result,true) != null){
        if($responseJson['Message'] == "401 Unauthorized"){
            die("Please enter a valid gitlab token in config\n");
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

/*
 * Command line argument parsing
 */
function arg($x = "", $default = null)
{

    static $arginfo = [];

    /* helper */
    $contains = function ($h, $n) {
        return (false !== strpos($h, $n));
    };
    /* helper */
    $valuesOf = function ($s) {
        return explode(",", $s);
    };

    //  called with a multiline string --> parse arguments
    if ($contains($x, "\n")) {

        //  parse multiline text input
        $args = $GLOBALS["argv"] ?: [];
        $rows = preg_split('/\s*\n\s*/', trim($x));
        $data = $valuesOf("char,word,type,help");
        foreach ($rows as $row) {
            list($char, $word, $type, $help) = preg_split('/\s\s+/', $row);
            $char = trim($char, "-");
            $word = trim($word, "-");
            $key = $word ?: $char ?: "";
            if ($key === "") continue;
            $arginfo[$key] = compact($data);
            $arginfo[$key]["value"] = null;
        }

        $nr = 0;
        while ($args) {

            $x = array_shift($args);
            if ($x[0] <> "-") {
                $arginfo[$nr++]["value"] = $x;
                continue;
            }
            $x = ltrim($x, "-");
            $v = null;
            if ($contains($x, "=")) list($x, $v) = explode("=", $x, 2);
            $k = "";
            foreach ($arginfo as $k => $arg) if (($arg["char"] == $x) || ($arg["word"] == $x)) break;
            $t = $arginfo[$k]["type"];
            switch ($t) {
                case "bool" :
                    $v = true;
                    break;
                case "str"  :
                    if (is_null($v)) $v = array_shift($args);
                    break;
                case "int"  :
                    if (is_null($v)) $v = array_shift($args);
                    $v = intval($v);
                    break;
            }
            $arginfo[$k]["value"] = $v;

        }

        return $arginfo;

    }

    if ($x === "") return $arginfo;
    if (isset($arginfo[$x]["value"])) return $arginfo[$x]["value"];
    return $default;
}

arg("
        -b  --base           str    Path to base file (Either Base or en file)
        -f  --force          bool   flag to force push if resource already exists
    ");
$arguments = arg();
$force = arg()['force'];
$sourceArgument = arg()['base'];

if ($sourceArgument['value'] == null || arg(1)) {
    echo("-b  --base           str    Path to base file (Either Base or en file)
-f  --force          bool   Optional flag to force push if resource already exists
    ");
    die();
}

/**
 * Create a new resource on Transifex
 *
 * @param $resourceName
 * @param $force
 */
function createNewResource($resourceName, $force,$isPlural)
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
    if ($response['errors'][0]['status'] === '409' && $force['value'] == null) {
        echo $response['errors'][0]['detail'];
        die();
    }
    echo("Created new Resource: {$resourceName}\n");
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
        die("File name should be the name of the resource (Case Sensitive)\n");
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
            die("Invalid String Syntax, make sure you are using escape characters for strings\n");
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
    echo "Uploaded source file for resource {$resourceName}\n";
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
// check for file existing
if (!file_exists($sourceArgument['value'])) {
    echo "Incorrect source file path\n";
    die();
}

$fileParts = pathinfo($sourceArgument['value']);

// check for correct extension
if ($fileParts['extension'] !== "strings" && $fileParts['extension'] !== "stringsdict") {
    echo "Please use .strings or .stringsdict extension for source file\n";
    die();
}

 // Push to main resource file directly
 if($fileParts['filename'] == "Changelogs" || $fileParts['filename'] == "LTHPasscodeViewController" ){
     echo "Updating Main Resource as file is Changelogs/LTHPassCodeViewController and not updated often\n";
    addNewSourceFile(file_get_contents($sourceArgument['value']), $fileParts['filename'],false);
    die();
}

$branchName = `git branch --show-current`;
if ($branchName == "" || $branchName == null) {
    die("You are currently not on a branch, please switch to the branch you are working on\n");
}

echo "Note: You are currently on branch {$branchName}.\n";
if (in_array(str_replace(PHP_EOL, "", $branchName), ["master", "develop"])) {
    echo PHP_EOL . "Error: Updating string is not allowed in this branch." . PHP_EOL;
    return false;
}
$branchResourceName = $fileParts['filename'] . "-" .  preg_replace("/[^A-Za-z0-9]/", '', $branchName);


// get the gitlab strings for comparisons

$stringsToPush = "";
$ourStrings =  file_get_contents($sourceArgument['value']);
$gitlabResourceStrings = "";
if($fileParts['filename'] == "InfoPlist"){
    $gitlabResourceStrings = getGitLabResourceFile(MAIN_INFOPLIST_URL);
}else if ($fileParts['filename'] == "Localizable"){
    $gitlabResourceStrings = getGitLabResourceFile(MAIN_LOCALIZABLE_URL);
}


// parse
if($fileParts['extension'] == "strings"){
    $gitlabResArr =  parseAppleStrings(trimUnicode($gitlabResourceStrings));
    $ourStringsArr = parseAppleStrings(trimUnicode($ourStrings));
    $stringsToPush = getDiffOfResource($gitlabResArr,$ourStringsArr);
}else if ($fileParts['extension'] == "stringsdict"){
// TODO stringsdict format
    die("Stringsdict not supported yet");
}

// TODO stringsdict file when they upload to gitlab
if (getResourceDetails(strtolower($fileParts['filename']))) {
    if ($fileParts['extension'] == "strings") {
        createNewResource($branchResourceName, $force,false);
        addNewSourceFile($stringsToPush, $branchResourceName,false);
    } else if ($fileParts['extension'] == "stringsdict") {
        createNewResource($branchResourceName, $force,true);
        addNewSourceFile($sourceArgument['value'], $branchResourceName,true);
    }
} else {
    echo "File name should be the name of the resource (Case Sensitive)\n";
    die();
}
?>
