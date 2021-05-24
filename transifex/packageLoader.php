<?php
namespace PackageLoader;

class PackageLoader
{
    public $dir;

    public function getComposerFile()
    {
        return json_decode(file_get_contents($this->dir . "/composer.json"), 1);
    }

    public function load($dir)
    {
        $this->dir = $dir;
        $composer = $this->getComposerFile();
        if (isset($composer["autoload"]["psr-4"])) {
            $this->loadPSR4($composer['autoload']['psr-4']);
        }
        if (isset($composer["autoload"]["psr-0"])) {
            $this->loadPSR0($composer['autoload']['psr-0']);
        }
        if (isset($composer["autoload"]["files"])) {
            $this->loadFiles($composer["autoload"]["files"]);
        }
    }

    public function loadFiles($files)
    {
        foreach ($files as $file) {
            $fullpath = $this->dir . "/" . $file;
            if (file_exists($fullpath)) {
                include_once($fullpath);
            }
        }
    }

    public function loadPSR4($namespaces)
    {
        $this->loadPSR($namespaces, true);
    }

    public function loadPSR0($namespaces)
    {
        $this->loadPSR($namespaces, false);
    }

    public function loadPSR($namespaces, $psr4)
    {
        $dir = $this->dir;
        // Foreach namespace specified in the composer, load the given classes
        foreach ($namespaces as $namespace => $classpaths) {
            if (!is_array($classpaths)) {
                $classpaths = array($classpaths);
            }
            spl_autoload_register(function ($classname) use ($namespace, $classpaths, $dir, $psr4) {
                // Check if the namespace matches the class we are looking for
                if (preg_match("#^" . preg_quote($namespace) . "#", $classname)) {
                    // Remove the namespace from the file path since it's psr4
                    if ($psr4) {
                        $classname = str_replace($namespace, "", $classname);
                    }
                    $filename = preg_replace("#\\\\#", "/", $classname) . ".php";
                    foreach ($classpaths as $classpath) {
                        $fullpath = $this->dir . "/" . $classpath . "/$filename";
                        if (file_exists($fullpath)) {
                            include_once $fullpath;
                        }
                    }
                }
            });
        }
    }
}