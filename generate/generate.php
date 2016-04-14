#!/usr/bin/php
<?php

$scriptname = basename(__FILE__);

function println($str) {
	return print("$str\n");
}

function usage() {
	global $scriptname;

	println('Generate source from template');
	println('Requires MobileDetect as a sibling directory to mobile-detect.lua.');
	println('https://github.com/serbanghita/Mobile-Detect');
	println('');
	println("Usage:    php $scriptname [option]");
	println('Options:');
	println('          -h,     --help      Displays help');
	println('');

	exit(1);
}

if ($argc > 1 && in_array($argv[1], array('--help', '-h'))) {
	usage();
}

require_once dirname(__FILE__).'/../../Mobile-Detect/Mobile_Detect.php';

class Mobile_Detect_Exporter extends Mobile_Detect {

    public function export()
    {
        $detect_data = array(
            'phone_devices' => parent::$phoneDevices,
            'tablet_devices' => parent::$tabletDevices,
            'operating_systems' => parent::$operatingSystems,
            'browsers' => parent::$browsers,
            'properties' => parent::$properties,
            'utilities' => parent::$utilities
        );
        return $detect_data;
    }
}

// Export data
$exporter = new Mobile_Detect_Exporter();
$raw_data = $exporter->export();
$json_data = json_encode($raw_data, JSON_PRETTY_PRINT);

// Generate file
$in_file = dirname(__FILE__).'/mobile-detect.template.lua';
$out_file = dirname(__FILE__).'/../mobile-detect.lua';
$in_content = file_get_contents($in_file);
$token = '{{token.rules}}';
$out_content = "-- THIS FILE IS GENERATED - DO NOT EDIT!\n\n";

// Data
$out_content .= str_replace($token, $json_data, $in_content);

// Comments
$keys = array_keys($raw_data);
foreach ($keys as $key) {
    $inner_keys = array_keys($raw_data[$key]);
    $list = implode(", ", $inner_keys);
    //$list = '-- ' . $list;
    $list = wordwrap($list, 80, "\n-- ");
    $out_content = str_replace("{{token.$key}}", $list, $out_content);
}

file_put_contents($out_file, $out_content);

?>