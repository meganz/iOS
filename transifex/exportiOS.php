<?php
include __DIR__.'/packageLoader.php';

$loader = new PackageLoader\PackageLoader();
$loader->load(__DIR__."/custom_vendor/CFPropertyList");
$config = file_get_contents('transifexConfig.json');
$configDecode = json_decode($config,true);
$token = getenv('TRANSIFEX_TOKEN') ?: $configDecode['apiToken'];


define("TRANSIFEX_API_TOKEN", $token);
define("ORGANIZATION", $configDecode['organization']);
define("PROJECT", $configDecode['project']);

define("TIME", time());

const ALL_LANGUAGES_URL = "https://rest.api.transifex.com/projects/o:" . ORGANIZATION . ":p:" . PROJECT . "/languages";
const ALL_RESOURCES_URL = "https://rest.api.transifex.com/resources?filter[project]=o:" . ORGANIZATION . ":p:" . PROJECT;

const POST_ASYNC_TRANSLATIONS_URL = "https://rest.api.transifex.com/resource_translations_async_downloads";
const POST_ASYNC_SOURCE_URL = "https://rest.api.transifex.com/resource_strings_async_downloads";
const APPLICATION_JSON_HEADER = ["Content-Type: application/vnd.api+json", "Authorization: Bearer " . TRANSIFEX_API_TOKEN];

const REMAPPED_LANG_CODES = [
    'zh_CN' => 'zh-Hans',
    'pt' => 'pt-br',
    'zh_TW' => 'zh-Hant'
];

const REMAPPED_RESOURCE_NAMES = [
    'infoplist' => 'InfoPlist',
    'localizable' => 'Localizable',
    'changelogs' => 'Changelogs',
    'lthpasscodeviewcontroller' => 'LTHPasscodeViewController',
    'plurals' => 'Plurals'
];

const REVERSE_REMAPPED_LANG_CODES = [
    'zh-Hans' => 'zh_CN',
    'pt-br' => 'pt',
    'zh-Hant' => 'zh_TW'
];

error_reporting( ~E_NOTICE & ~E_WARNING);
/*
 * Function to help with conversion of UTF-16 to UTF-8 -> removing unnecessary unicode characters for json parsing
 */
function trimUnicode($str): string
{
    return preg_replace('/^[\pZ\pC]+|[\pZ\pC]+$/u', '', $str);
}

/**
 * Sanitise only ellipses and not quotes, due to different quoting standards across different languages.
 *
 * @param $str
 * @return string
 */
function sanitiseSingleResourceString($str): string
{
    preg_match_all('/<[^sd][^>]*>/', $str, $tags);

    $replace = [
        "#\.\.\.#"                                              // M. Ellipsis
    ];

    $replaceTo = [
        "…"         // M
    ];

    $text = $str;
    if ($tags[0]) {
        foreach ($tags[0] as $key => $value) {
            $text = str_replace($value, " <t " . $key . "> ", $text);
        }
    }
    $text = preg_replace($replace, $replaceTo, $text);
    $text = str_replace("[x]", "[X]", $text);
    $text = str_replace("[a]", "[A]", $text);
    $text = str_replace("[/a]", "[/A]", $text);
    $text = str_replace("[b]", "[B]", $text);
    $text = str_replace("[/b]", "[/B]", $text);
    $text = str_replace("[a1]", "[A1]", $text);
    $text = str_replace("[/a1]", "[/A2]", $text);
    $text = str_replace("[a2]", "[A2]", $text);
    $text = str_replace("[/a2]", "[/A2]", $text);
    $text = str_replace("[x1]", "[X1]", $text);
    $text = str_replace("[/x1]", "[/X1]", $text);
    $text = str_replace("[x2]", "[X2]", $text);
    $text = str_replace("[/x2]", "[/X2]", $text);
    $text = str_replace("\r", "", str_replace("\n", "", $text));
    $text = str_replace("[Br]", '\n', $text);

    if ($tags[0]) {
        foreach ($tags[0] as $key => $value) {
            $text = str_replace(" <t " . $key . "> ", $value, $text);
        }
    }

    return $text;
}

/**
 * Parses apple strings format
 *
 * @param $resourceString
 * @return array
 */
function parseAppleStrings($resource): array
{
    $genericMapping = [];
    foreach ($resource as $key => $res) {
        $resourceString = $res['text'];
        $language = $res['language'];
        $context = "";
        $resourceName = substr($res['resource'], strrpos($res['resource'], ':r:') + 3);

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
            $stringText = preg_replace('/^(\'(.*)\'|"(.*)")$/', '$2$3', $stringText);
            $stringKey = trim(trim($stringKey), ";\"\'");
            $context = trim($context);
            $sanitisedStringText = sanitiseSingleResourceString($stringText);


            $genericMapping[$resourceName][$language][$stringKey] = [
                "stringText" => $sanitisedStringText,
                "stringDescription" => $context
            ];
        }
    }
    return $genericMapping;
}

/**
 * Merges the original resource file, with the branched resource file
 *
 * @param $originalResource
 * @param $branchResource
 * @return Array
 */
function buildMergedResourceMapping($originalTranslations, $translations): array
{
    $branchResourceMapping = parseAppleStrings($translations);
    $originalResourceMapping = parseAppleStrings($originalTranslations);
    $finalMap = [];
    foreach ($branchResourceMapping as $resource => $res) {
        foreach ($res as $language => $lan) {
            foreach ($lan as $key => $value) {
                $origResourceName = strtolower(explode("-", $resource)[0]);
                $originalResourceMapping[$origResourceName][$language][$key] = [
                    "stringText" => $value["stringText"],
                    "stringDescription" => $value["stringDescription"]
                ];
            }
        }
        $finalMap[$resource] = $originalResourceMapping[strtolower(explode("-", $resource)[0])];;
    }
    // return the new array -> when then need to build the new file
    return $finalMap;
}

/**
 * Builds the .strings file from the merged resource array mapping.
 *
 * @param $resourceMapping
 * @return Array
 */
function buildResourceFileFromArray($resourceMapping): array
{
    $finalContent = [];
    foreach ($resourceMapping as $branchResource => $branchRes) {
        foreach ($branchRes as $languages => $lan) {
            foreach ($lan as $key => $value) {
                {
                        $finalContent[$branchResource][$languages] .= "/* {$value['stringDescription']} */\n";
                        $finalContent[$branchResource][$languages] .= "\"{$key}\"=\"{$value['stringText']}\";\n";
                }
            }
        }
    }
    return $finalContent;
}

/**
 * Unused function to check i18n_type.
 *
 * @param $resourceSlug
 * @return mixed
 */
function getResourceType($resourceSlug){
    $ch = curl_init("https://rest.api.transifex.com/resources/{$resourceSlug}");
    curl_setopt($ch, CURLOPT_HTTPGET, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["Authorization: Bearer " . TRANSIFEX_API_TOKEN]);
    $response = curl_exec($ch);

    if ($response === FALSE) {
        echo "cURL Error: " . curl_error($ch);
        die();
    }

    $responseJson = json_decode($response, true);
    if (isset($responseJson['errors'])) {
        foreach ($responseJson['errors'] as $error) {
            echo "Error {$error['status']}: {$error['detail']}.\n";
        }
        die();
    }
    curl_close($ch);

    return $responseJson['data']['attributes']['i18n_type'];
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
function makeGenericMultiCurlRequest($method, $requests, $headers, $url): array
{
    // array of all curls
    $multiCurl = array();
    // data to be returned
    $result = array();
    // multi handle
    $mh = curl_multi_init();
    $i = 0;
    foreach ($requests as $request) {
        $options = array(
            CURLOPT_IPRESOLVE => CURL_IPRESOLVE_V4,
            CURLOPT_POSTFIELDS => $request,
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

/**
 * Multi curl request that polls to check for correct download response from transifex
 *
 * @param $method
 * @param $urls
 * @param $headers
 * @return array
 */
function pollCurlRequest($method, $urls, $headers): array
{
    $multiCurl = array();
    // data to be returned
    $output = [];
    // multi handle
    $mh = curl_multi_init();
    $i = 0;
    foreach ($urls as $url) {

        $options = array(
            CURLOPT_IPRESOLVE => CURL_IPRESOLVE_V4,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_ENCODING => '',
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_URL => $url['link']
        );
        $multiCurl[$i] = curl_init();
        curl_setopt_array($multiCurl[$i], $options);
        curl_multi_add_handle($mh, $multiCurl[$i]);
        $i++;
    }

    // loop til we receive the correct data from multi_curl
    while (!empty($multiCurl)) {
        $index = null;
        do {
            curl_multi_exec($mh, $index);
        } while ($index > 0);

        // get content and remove handles
        foreach ($multiCurl as $k => $ch) {
            $response = curl_multi_getcontent($ch);
            $responseJson = json_decode($response, true);
            // if json is null, means we got correct response
            if ($responseJson == null) {
                // convert to UTF-8
                if (!mb_detect_encoding($response, 'UTF-8', true)) {
                    $response = mb_convert_encoding($response, "UTF-8", "UTF-16LE");
                }
                $response = trimUnicode($response);
                // remove from array of curl handles -> since we have the correct response already
                unset($multiCurl[$k]);
                curl_multi_remove_handle($mh, $ch);
                // set response
                $output[] = [
                    "text" => $response,
                    "resource" => $urls[$k]['resource'],
                    "language" => $urls[$k]['language']
                ];
                echo "Gather data for Resource: {$urls[$k]['resource']} for Language: {$urls[$k]['language']}.\n";
                continue;
            }
            if (isset($responseJson['errors'])) {
                foreach ($responseJson['errors'] as $error) {
                    echo "Error {$error['status']}: {$error['detail']}.\n";
                }
                die();
            }
            // remove and readd handle to reinitialise.
            curl_multi_remove_handle($mh, $ch);
            curl_multi_add_handle($mh, $ch);
        }
        // sleep as to not overload api calls
        sleep(1);
    }
    // close
    curl_multi_close($mh);
    return $output;
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

/**
 * Separate merge function for merging plurals (stringsdict format).
 *
 * @param $originalPluralLanguages
 * @param $pluralLanguages
 * @param $isLan
 * @throws \CFPropertyList\IOException
 *
 */
function mergePlurals($originalPluralLanguages,$pluralLanguages,$isLan){
    foreach($originalPluralLanguages as $key => $originalPluralLanguage){

        $existingStrings = new CFPropertyList\CFPropertyList(strToStream($originalPluralLanguage['text']), CFPropertyList\CFPropertyList::FORMAT_XML );
        $stringsToAdd = new CFPropertyList\CFPropertyList(strToStream($pluralLanguages[$key]['text']), CFPropertyList\CFPropertyList::FORMAT_XML );
        $stringsToExport = new CFPropertyList\CFPropertyList(null, CFPropertyList\CFPropertyList::FORMAT_XML );
        $stringsToExportDict = new \CFPropertyList\CFDictionary([]);

        // Add or replace, depending if upper key exists.
        foreach( $stringsToAdd->getValue(true) as $newKeys => $newValues )
        {
            $existingStringsDict = $existingStrings->getValue();
            if($existingStringsDict->get($newKeys)) {
                $existingStringsDict->del($newKeys);
            }
            $existingStringsDict->add($newKeys,$newValues);
        }

        // Create files
            $branchName = substr($pluralLanguages[$key]['resource'], strrpos($pluralLanguages[$key]['resource'], ':r:') + 3);

        $path = "Translations-" . TIME . "/localizable";
        if(!file_exists($path)){
            mkdir($path, 0777, true);
        }
            //language files
            if($isLan){
                $languageName = str_replace(array_keys(REMAPPED_LANG_CODES), array_values(REMAPPED_LANG_CODES), explode(":", $pluralLanguages[$key]['language'])[1]);
                $resourceName = str_replace(array_keys(REMAPPED_RESOURCE_NAMES), array_values(REMAPPED_RESOURCE_NAMES), explode("-", $branchName)[0]);
                mkdir("{$path}/{$languageName}.lproj");
                $existingStrings->save("{$path}/{$languageName}.lproj/Localizable.stringsdict", CFPropertyList\CFPropertyList::FORMAT_AUTO);
                echo "Created File: {$path}/{$languageName}.lproj/Localizable.stringsdict\n";
            }else{
                //base files
                mkdir("{$path}/Base.lproj");
                mkdir("{$path}/en.lproj");
                $resourceName = str_replace(array_keys(REMAPPED_RESOURCE_NAMES), array_values(REMAPPED_RESOURCE_NAMES), explode("-", $branchName)[0]);
                $existingStrings->save("{$path}/en.lproj/Localizable.stringsdict", CFPropertyList\CFPropertyList::FORMAT_AUTO);
                $existingStrings->save("{$path}/Base.lproj/Localizable.stringsdict", CFPropertyList\CFPropertyList::FORMAT_AUTO);
                echo "Created File: {$path}/en.lproj/Localizable.stringsdict\n";
                echo "Created File: {$path}/Base.lproj/Localizable.stringsdict\n";
            }
    }
}

/**
 * Gets the original source file for a given resource
 *
 * @param $originalResourceSlug
 * @return Array
 */
function sourceLanguageHelper($resource): array
{
    $requests = [];
    $stringsDictRequests = [];
    foreach ($resource as $res) {
        $requestData = '{
  "data": {
    "attributes": {
      "content_encoding": "text",
      "file_type": "default"
    },
    "relationships": {
      "resource": {
        "data": {
          "id": "' . $res['resourceSlug'] . '",
          "type": "resources"
        }
      }
    },
    "type": "resource_strings_async_downloads"
  }
}';
        $resourceName = substr($res['resourceSlug'], strrpos($res['resourceSlug'], ':r:') + 3);
        $resourceName = str_replace(array_keys(REMAPPED_RESOURCE_NAMES), array_values(REMAPPED_RESOURCE_NAMES), explode("-", $resourceName)[0]);

        //TODO Edit this functionality when live, for proper stringsdict format check

        if ($resourceName == 'Plurals') {
            $stringsDictRequests[] = $requestData;
        }else{
            $requests[] = $requestData;
        }
    }

    $result = makeGenericMultiCurlRequest("POST", $requests, APPLICATION_JSON_HEADER, POST_ASYNC_SOURCE_URL);
    $pluralResults =  makeGenericMultiCurlRequest("POST", $stringsDictRequests, APPLICATION_JSON_HEADER, POST_ASYNC_SOURCE_URL);
    $links = [];
    foreach ($result as $res) {
        $links[] = [
            "link" => $res['data']['links']['self'],
            "resource" => $res['data']['relationships']['resource']['data']['id'],
            "language" => "Base"
        ];
    }
    $pluralLinks = [];
    foreach ($pluralResults as $res) {
        $pluralLinks[] = [
            "link" => $res['data']['links']['self'],
            "resource" => $res['data']['relationships']['resource']['data']['id'],
            "language" => "Base"
        ];
    }
    echo "Obtained Links For Source Files.\n";

    $sourceLanguages =  pollCurlRequest("GET", $links, APPLICATION_JSON_HEADER);
    $pluralSourceLanguages =  pollCurlRequest("GET", $pluralLinks, APPLICATION_JSON_HEADER);
    return[
        'source' => $sourceLanguages,
        'pluralSource'=>$pluralSourceLanguages
    ];
}

/*
 * Downloads the source -> base/en files for all string resources
 */
function getSourceLanguageFile($resources)
{
    echo "--------------------------STARTING DATA EXPORT FOR SOURCE TRANSLATION FILES...--------------------------\n";
    $sourceLanguages = sourceLanguageHelper($resources);
    echo "Obtained Source Language Files For Branch Resources.\n";
    $originalRequestParams = [];
    $originalSourceLanguages = [];
    $originalPluralRequestParams = [];
    $originalPluralSourceLanguages = [];

    // Setup request params for download original "main" resource
    foreach ($sourceLanguages['source'] as $sourceLanguage) {
        $resourceName = substr($sourceLanguage['resource'], strrpos($sourceLanguage['resource'], ':r:') + 3);
        $originalResourceName = strtolower(explode("-", $resourceName)[0]);
        $originalResourceSlug = "o:" . ORGANIZATION . ":p:" . PROJECT . ":r:" . $originalResourceName;

        if ($resourceName == $originalResourceName) {
            $originalSourceLanguages[] = $sourceLanguage;
        } else {
            $originalRequestParams[] = [
                'resourceSlug' => $originalResourceSlug,
                'language' => "Base"
            ];
        }
    }

    // Setup request params for download original "main" resource for plurals
    foreach ($sourceLanguages['pluralSource'] as $sourceLanguage) {
        $resourceName = substr($sourceLanguage['resource'], strrpos($sourceLanguage['resource'], ':r:') + 3);
        $originalResourceName = strtolower(explode("-", $resourceName)[0]);
        $originalResourceSlug = "o:" . ORGANIZATION . ":p:" . PROJECT . ":r:" . $originalResourceName;

        if ($resourceName == $originalResourceName) {
            $originalPluralSourceLanguages[] = $sourceLanguage;
        } else {
            $originalPluralRequestParams[] = [
                'resourceSlug' => $originalResourceSlug,
                'language' => "Base"
            ];
        }
    }

    // Append to originalSourceLanguages for merging
    $tempOriginalSourceLanguages = sourceLanguageHelper($originalRequestParams)['source'];
    echo "Obtained Original Source Language Files For Original Resource.\n";
    foreach ($tempOriginalSourceLanguages as $tr) {
        $originalSourceLanguages[] = $tr;
    }

    $tempOriginalPluralSourceLanguages = sourceLanguageHelper($originalPluralRequestParams)['pluralSource'];
    echo "Obtained Original Plural Source Language Files For Original Resource.\n";
    foreach ($tempOriginalPluralSourceLanguages as $tr) {
        $originalPluralSourceLanguages[] = $tr;
    }

    echo "Merging Original Source Language Files with Branch Source Language Files...\n";
    $mergedResourceMapping = buildMergedResourceMapping($originalSourceLanguages, $sourceLanguages['source']);
    $finalContent = buildResourceFileFromArray($mergedResourceMapping);

    mergePlurals($originalPluralSourceLanguages,$sourceLanguages['pluralSource'],false);

    $pathOverride = false;
    if(count($finalContent) > 1 && $finalContent['localizable'] !== null) {
        $pathOverride = true;
    }

    //strings format
    foreach ($finalContent as $branchResource => $res) {
        foreach ($res as $language => $content) {
            $resourceName = str_replace(array_keys(REMAPPED_RESOURCE_NAMES), array_values(REMAPPED_RESOURCE_NAMES), explode("-", $branchResource)[0]);
            $path = "Translations-" . TIME . "/{$branchResource}";
            if ($pathOverride && $branchResource == 'infoplist') {
                $path = "Translations-" . TIME . "/localizable";
            }
            if(!file_exists($path)){
                mkdir($path, 0777, true);
            }
            mkdir("{$path}/Base.lproj");
            mkdir("{$path}/en.lproj");
            file_put_contents("{$path}/Base.lproj/{$resourceName}.strings", ($content));
            file_put_contents("{$path}/en.lproj/{$resourceName}.strings", ($content));
            echo "Created File: {$path}/Base.lproj/{$resourceName}.strings\n";
            echo "Created File: {$path}/en.lproj/{$resourceName}.strings\n";
        }
    }
}

/**
 * Gets the original language file for a given resource.
 *
 * @param $resourceSlug
 * @param $language
 * @return Array
 */
function translationsHelper($requestParam): array
{
    // build array for multi curl request to optimise curl performance
    $requests = [];
    $stringsDictRequests = [];
    foreach ($requestParam as $req) {
        $requestData = '{
    "data": {
        "attributes": {
            "content_encoding": "text",
      "file_type": "default",
      "mode": "sourceastranslation"
    },
    "relationships": {
            "language": {
                "data": {
                    "id": "' . $req['language'] . '",
          "type": "languages"
        }
      },
      "resource": {
                "data": {
                    "id": "' . $req['resourceSlug'] . '",
          "type": "resources"
        }
      }
    },
    "type": "resource_translations_async_downloads"
  }
}';
        $resourceName = substr($req['resourceSlug'], strrpos($req['resourceSlug'], ':r:') + 3);
        $resourceName = str_replace(array_keys(REMAPPED_RESOURCE_NAMES), array_values(REMAPPED_RESOURCE_NAMES), explode("-", $resourceName)[0]);

        //TODO Edit this functionality when live, for proper stringsdict format check
        if ($resourceName == 'Plurals') {
            $stringsDictRequests[] = $requestData;
        }else{
        $requests[] = $requestData;
        }
    }

    // Get links
    $result = makeGenericMultiCurlRequest("POST", $requests, APPLICATION_JSON_HEADER, POST_ASYNC_TRANSLATIONS_URL);
    $pluralResults = makeGenericMultiCurlRequest("POST", $stringsDictRequests, APPLICATION_JSON_HEADER, POST_ASYNC_TRANSLATIONS_URL);
    $links = [];
    foreach ($result as $res) {
        $links[] = [
            "link" => $res['data']['links']['self'],
            "resource" => $res['data']['relationships']['resource']['data']['id'],
            "language" => $res['data']['relationships']['language']['data']['id']
        ];
    }
    $pluralLinks = [];
    foreach ($pluralResults as $res) {
        $pluralLinks[] = [
            "link" => $res['data']['links']['self'],
            "resource" => $res['data']['relationships']['resource']['data']['id'],
            "language" => $res['data']['relationships']['language']['data']['id']
        ];
    }

    echo "Obtained Links For Translations.\n";

    // get actual strings from download link
    $languages =  pollCurlRequest("GET", $links, APPLICATION_JSON_HEADER);
    $pluralLanguages =  pollCurlRequest("GET", $pluralLinks, APPLICATION_JSON_HEADER);
    return[
        'translation' => $languages,
        'pluralTranslation'=>$pluralLanguages
    ];
}

/**
 * Entry function to get all translations for specified resources and languages
 *
 * @param $resources
 * @param $languages
 * @throws \CFPropertyList\IOException
 */
function getTranslations($resources, $languages)
{
    // Build array of resource slugs for every language for multi curl function
    $requestParams = [];
    foreach ($resources as $res) {
        foreach ($languages as $lan) {
            $requestParams[] = [
                'resourceSlug' => $res['resourceSlug'],
                'language' => $lan['code'],
            ];
        }
    }
    echo "--------------------------STARTING DATA EXPORT FOR TRANSLATION FILES...--------------------------\n";

    // Get translations for branched resources
    $translations = translationsHelper($requestParams);
    echo "Obtained Translations For Branch Resources.\n";
    $origRequestParams = [];
    $originalTranslations = [];
    $originalPluralRequestParams = [];
    $originalPluralTranslations = [];

    foreach ($translations['translation'] as $translation) {
        $resourceName = substr($translation['resource'], strrpos($translation['resource'], ':r:') + 3);
        $originalResourceName = strtolower(explode("-", $resourceName)[0]);
        $originalResourceSlug = "o:" . ORGANIZATION . ":p:" . PROJECT . ":r:" . $originalResourceName;

        // If the resource slug was the same as the original "main resource" we don't need to requery for the main resource, as we don't need to merge, if they are both the same.
        if ($resourceName == $originalResourceName) {
            $originalTranslations[] = $translation;
        } else {
            $origRequestParams[] = [
                'resourceSlug' => $originalResourceSlug,
                'language' => $translation['language'],
            ];
        }
    }

    // do same for plurals
    foreach ($translations['pluralTranslation'] as $translation) {
        $resourceName = substr($translation['resource'], strrpos($translation['resource'], ':r:') + 3);
        $originalResourceName = strtolower(explode("-", $resourceName)[0]);
        $originalResourceSlug = "o:" . ORGANIZATION . ":p:" . PROJECT . ":r:" . $originalResourceName;

        if ($resourceName == $originalResourceName) {
            $originalPluralTranslations[] = $translation;
        } else {
            $originalPluralRequestParams[] = [
                'resourceSlug' => $originalResourceSlug,
                'language' => $translation['language'],
            ];
        }
    }

    // Get original "main" translations for merging with branched version.
    $originalLanguageTranslations = translationsHelper($origRequestParams)['translation'];
    echo "Obtained Original Translations For Original Resource.\n";
    foreach ($originalLanguageTranslations as $tr) {
        $originalTranslations[] = $tr;
    }
    $originalPluralLanguageTranslations = translationsHelper($originalPluralRequestParams)['pluralTranslation'];
    echo "Obtained Original Plural Translations For Original Resource.\n";
    foreach ($originalPluralLanguageTranslations as $tr) {
        $originalPluralTranslations[] = $tr;
    }

    echo "Merging Original Translations with Branch Translations...\n";

    $mergedResourceMapping = buildMergedResourceMapping($originalTranslations, $translations['translation']);
    $finalContent = buildResourceFileFromArray($mergedResourceMapping);
    // Merge plurals
    mergePlurals($originalPluralTranslations,$translations['pluralTranslation'],true);

    // move infoplist and plurals into same folder as localizable
    $pathOverride = false;
    if(count($finalContent) > 1 && $finalContent['localizable'] !== null) {
        $pathOverride = true;
    }
    // strings format creation
    foreach ($finalContent as $branchResource => $res) {
        foreach ($res as $language => $content) {
            $languageName = str_replace(array_keys(REMAPPED_LANG_CODES), array_values(REMAPPED_LANG_CODES), explode(":", $language)[1]);
            $resourceName = str_replace(array_keys(REMAPPED_RESOURCE_NAMES), array_values(REMAPPED_RESOURCE_NAMES), explode("-", $branchResource)[0]);
            $path = "Translations-" . TIME . "/{$branchResource}";
            if ($pathOverride && ($branchResource == 'infoplist' || $branchResource == 'plurals')) {
                $path = "Translations-" . TIME . "/localizable";
            }
            if(!file_exists($path)){
                mkdir($path, 0777, true);
            }
            mkdir("{$path}/{$languageName}.lproj");
            file_put_contents("{$path}/{$languageName}.lproj/{$resourceName}.strings", ($content));
            echo "Created File: {$path}/{$languageName}.lproj/{$resourceName}.strings\n";
        }
    }
}

/*
 * Get all resources for a project.
 */
function getAllResourcesForProject(): array
{
    $ch = curl_init(ALL_RESOURCES_URL);
    curl_setopt($ch, CURLOPT_HTTPGET, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["Authorization: Bearer " . TRANSIFEX_API_TOKEN]);
    $response = curl_exec($ch);

    if ($response === FALSE) {
        echo "cURL Error: " . curl_error($ch);
        die();
    }

    $responseJson = json_decode($response, true);
    if (isset($responseJson['errors'])) {
        foreach ($responseJson['errors'] as $error) {
            echo "Error {$error['status']}: {$error['detail']}.\n";
        }
        die();
    }
    curl_close($ch);

    return $responseJson['data'];
}

/*
 * Get all Languages for a project
 */
function getAllLanguagesForProject(): array
{
    $ch = curl_init(ALL_LANGUAGES_URL);
    curl_setopt($ch, CURLOPT_HTTPGET, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["Authorization: Bearer " . TRANSIFEX_API_TOKEN]);
    $response = curl_exec($ch);

    if ($response === FALSE) {
        echo "cURL Error: " . curl_error($ch);
        exit();
    }

    $responseJson = json_decode($response, true);
    if (isset($responseJson['errors'])) {
        foreach ($responseJson['errors'] as $error) {
            echo "Error {$error['status']}: {$error['detail']}.\n";
        }
        die();
    }
    curl_close($ch);

    return $responseJson['data'];
}

/**
 * Get resource slugs mapped to resource names.
 * both the branch, and "main" resource slugs are mapped to their associated resource names.
 *
 * @param $branchName
 * @return array
 *
 */
function getResourceMapping($branchName): array
{
    $resources = getAllResourcesForProject();
    $resourceMapping = [];

    //init with source values
    foreach ($resources as $resource) {
        $resourceName = $resource['attributes']['name'];
        $originalResourceName = explode("-", $resourceName)[0];
        if (count(explode("-", $resourceName)) == 1) {
            $resourceMapping[$branchName][$originalResourceName] = [
                'resourceSlug' => $resource['id']
            ];
            $resourceMapping['source'][$originalResourceName] = [
                'resourceSlug' => $resource['id']
            ];
        }
    }

    foreach ($resources as $resource) {
        $resourceName = $resource['attributes']['name'];
        $originalResourceName = explode("-", $resourceName)[0];
        if (count(explode("-", $resourceName)) > 1) {
            if (explode("-", $resourceName)[1] == $branchName) {
                $resourceMapping[$branchName][$originalResourceName] = [
                    'resourceSlug' => $resource['id']
                ];
            }
        }
    }
    return $resourceMapping;
}

/**
 * Returns mapping of all languages in a project (remapping incl)
 * Mapping is an array of
 * [name : "ar"
 * code: "l:ar"]
 *
 * @return array
 */
function getLanguageMapping(): array
{
    $languages = getAllLanguagesForProject();
    $languageMapping = [];
    $i = 0;
    // do remapping of language codes
    foreach ($languages as $language) {
        $language = str_replace(array_keys(REMAPPED_LANG_CODES), array_values(REMAPPED_LANG_CODES), $language['attributes']['code']);
        $languageMapping[$i] = array('name' => $language, 'code' => "l:" . str_replace(array_keys(REVERSE_REMAPPED_LANG_CODES), array_values(REVERSE_REMAPPED_LANG_CODES), $language));
        $i++;
    }
    return $languageMapping;
}

// get branch name
$branchName = trim(`git branch --show-current`);

// remove any dashes and spaces from the branch name
$trimmedBranchName =  preg_replace("/[^A-Za-z0-9]/", '', $branchName);

$resourceMapping = getResourceMapping($trimmedBranchName);
$languageMapping = getLanguageMapping();

$sourceFolderNames =[];
$branchFolderNames = [];

foreach($resourceMapping[$trimmedBranchName] as $resource){
    $resourceName = substr($resource['resourceSlug'], strrpos($resource['resourceSlug'], ':r:') + 3);
    $branchFolderNames[] = [ $resourceName => __DIR__ . "/" . $resourceName];
}

foreach($resourceMapping['source'] as $resource){
    $resourceName = substr($resource['resourceSlug'], strrpos($resource['resourceSlug'], ':r:') + 3);
    $sourceFolderNames[] = [ $resourceName => __DIR__ . "/" . $resourceName];
}

function resourceChooser($resourceMapping){
    do{
        echo "\n1. Changelogs \n2. Localizable \n3. InfoPlist \n4. LTHPasscodeViewController \n5. Plurals \n6. All \n7. (q) to quit \n";
        $cmd = trim(strtolower(readline("\n > Which resource would you want to export (Enter the digit):\n")));
        readline_add_history($cmd);
        if ($cmd == 'q' || $cmd == '7') {
            exit;
        }
        switch(strtolower($cmd)){
            case '1' :
                return array($resourceMapping['Changelogs']);
            case '2':
                return array($resourceMapping['Localizable']);
            case '3':
                return array($resourceMapping['InfoPlist']);
            case '4':
                return array($resourceMapping['LTHPasscodeViewController']);
            case '5':
                return array($resourceMapping['Plurals']);
            case '6':
                return $resourceMapping;
        }
    }while ($cmd != 'q');
}

echo "\nWelcome to iOS Transifex Export \n";
$res = resourceChooser($resourceMapping[$trimmedBranchName]);
getTranslations($res, $languageMapping);
getSourceLanguageFile($res);