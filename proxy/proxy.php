<?php

/***
 * This is a short proxy service to allow my ESP8266-based WiFi boards to connect to
 * https sites.
 *
 * (c) Roland Leurs 2022
 *
 * License: do whatever you want with this software but use it at your own risc!
 */

$headers = apache_request_headers();
$url = $_SERVER['QUERY_STRING'];

$allowedHosts = [
    'github.com',
    'stardot.org.uk',
    'noslite.nl',
    'api.openai.com'
];

/* Determine the range */
if (isset($headers['Range'])) {
    list($dummy,$range) = preg_split('/=/', $headers['Range']);
    list($begin,$end) = preg_split('/-/', $range);
} else {
    $begin = $end = 0;
}

/* Test for valid URL */
if (strtolower(substr($url, 0, 7)) == 'http://' || strtolower(substr($url, 0, 8)) == 'https://') {

    // Check if the hostname is correct, valid and allowed
    // Step 1: extract the hostname
    $host = str_ireplace('http://', '', $url);
    $host = str_ireplace('https://', '', $host);
    $hostSize = strpos($host, '/');

    if ($hostSize) {
        $host = substr($host, 0, $hostSize);
    }
    $host = strtolower($host);

    // Step 2: check for valid characters (a-z, 0-9 and _ - are allowed)
    if (!preg_match("/^[a-z0-9\.\-_]+$/", $host)) {
        header('HTTP/1.1 418 I am a teapot');
        exit;
    }

    // Step 3: check if the hostname is in the array of allowed hosts
    if (! in_array($host, $allowedHosts)) {
        header('HTTP/1.1 403 Forbidden');
        exit;
    }
    if ($_SERVER['REQUEST_METHOD'] == 'GET') {
        $cacheName = sha1($url) . '.cache';
        if (file_exists($cacheName)) {
            $f=fopen($cacheName, 'rb');
            $data = fread($f, filesize($cacheName));
        } else {
            $f = fopen($url, 'rb');
            if ($f) {
                $data = stream_get_contents($f);
                $cachefile = fopen($cacheName, 'wb');
                if ($cachefile) {
                    fwrite($cachefile, $data);
                    fclose($cachefile);
                }
            } else {
                header('HTTP/1.1 404 Not found');
                exit;
            }
        }

        fclose($f);
        if ($begin == 0 && $end == 0) {
            $output = $data;
        } else {
            $output = '';
            for($i=$begin; $i<=$end; $i++) {
                $output .= $data[$i];
            }
        }
    } elseif ($_SERVER['REQUEST_METHOD'] == 'POST') {
        $logfile = $_SERVER['DOCUMENT_ROOT'] . '/proxy.log';
        $log = fopen($logfile, 'w');
        fwrite($log, date('Y-m-d H:i:s') . PHP_EOL);
        fwrite($log, print_r($headers, true) . PHP_EOL);

        // Read POST data
        $fp = fopen('php://input','r');
        $data = fgets($fp);
        fclose($fp);
        fwrite($log, $data . PHP_EOL);
        // Set up cURL headers
        $curlHeaders = [];
        unset($headers['Content-Length']);
        unset($headers['Host']);
        foreach($headers as $key => $value) {
            $curlHeaders[] = $key . ': ' . $value;
        }
        // Do cURL request to get POST data
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL,$url);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $curlHeaders);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        $output = curl_exec($ch);
        curl_close($ch);
        fwrite($log, $output);
    } else {
        header('HTTP/1.1 400 Bad request');
        exit;
    }
    header("Content-Length: " . strlen($output) . "\r\n");
    echo $output;
} else {
    header('HTTP/1.1 400 Bad request');
}
