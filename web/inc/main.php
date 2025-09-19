<?php

session_start();

define('VESTA_CMD', '/usr/bin/sudo /usr/local/vesta/bin/');
define('JS_LATEST_UPDATE', '1758252713');
file_exists('/usr/local/vesta/conf/vesta.php') ? : require_once('../../conf/vesta.php');

defined('VESTA_DEBUG') ? : define('VESTA_DEBUG', false);

$i = 0;

require_once(dirname(__FILE__).'/i18n.php');


// Saving user IPs to the session for preventing session hijacking
$user_combined_ip = $_SERVER['REMOTE_ADDR'];

if(isset($_SERVER['HTTP_CLIENT_IP'])){
    $user_combined_ip .=  '|'. $_SERVER['HTTP_CLIENT_IP'];
}
if(isset($_SERVER['HTTP_X_FORWARDED_FOR'])){
    $user_combined_ip .=  '|'. $_SERVER['HTTP_X_FORWARDED_FOR'];
}
if(isset($_SERVER['HTTP_FORWARDED_FOR'])){
    $user_combined_ip .=  '|'. $_SERVER['HTTP_FORWARDED_FOR'];
}
if(isset($_SERVER['HTTP_X_FORWARDED'])){
    $user_combined_ip .=  '|'. $_SERVER['HTTP_X_FORWARDED'];
}
if(isset($_SERVER['HTTP_FORWARDED'])){
    $user_combined_ip .=  '|'. $_SERVER['HTTP_FORWARDED'];
}

if(!isset($_SESSION['user_combined_ip'])){
    $_SESSION['user_combined_ip'] = $user_combined_ip;
}

// Checking user to use session from the same IP he has been logged in
if($_SESSION['user_combined_ip'] != $user_combined_ip && $_SERVER['REMOTE_ADDR'] != '127.0.0.1'){
    session_destroy();
    session_start();
    $_SESSION['request_uri'] = $_SERVER['REQUEST_URI'];
    header("Location: /login/");
    exit;
}

// Check system settings
if ((!isset($_SESSION['VERSION'])) && (!defined('NO_AUTH_REQUIRED'))) {
    session_destroy();
    session_start();
    $_SESSION['request_uri'] = $_SERVER['REQUEST_URI'];
    header("Location: /login/");
    exit;
}

// Check user session
if ((!isset($_SESSION['user'])) && (!defined('NO_AUTH_REQUIRED'))) {
    $_SESSION['request_uri'] = $_SERVER['REQUEST_URI'];
    header("Location: /login/");
    exit;
}

// Generate CSRF Token
if (isset($_SESSION['user'])) {
        if (!isset($_SESSION['token'])){
        $token = bin2hex(file_get_contents('/dev/urandom', false, null, 0, 16));
        $_SESSION['token'] = $token;
    }
}

if (isset($_SESSION['language'])) {
    switch ($_SESSION['language']) {
        case 'ro':
            setlocale(LC_ALL, 'ro_RO.utf8');
            break;
        case 'ru':
            setlocale(LC_ALL, 'ru_RU.utf8');
            break;
        case 'ua':
            setlocale(LC_ALL, 'uk_UA.utf8');
            break;
        case 'es':
            setlocale(LC_ALL, 'es_ES.utf8');
            break;
        case 'ja':
            setlocale(LC_ALL, 'ja_JP.utf8');
            break;
        default:
            setlocale(LC_ALL, 'en_US.utf8');
    }
}

if (isset($_SESSION['user'])) {
    $user = $_SESSION['user'];
}

if (isset($_SESSION['look']) && ( $_SESSION['look'] != 'admin' )) {
    $user = $_SESSION['look'];
}

function get_favourites(): void
{
    exec (VESTA_CMD."v-list-user-favourites ".$_SESSION['user']." json", $output, $return_var);
//    $data = json_decode(implode('', $output).'}', true);
    $data = json_decode(implode('', $output), true);
    $data = array_reverse($data,true);
    $favourites = array();

    foreach($data['Favourites'] as $key => $favourite){
        $favourites[$key] = array();

        $items = explode(',', $favourite);
        foreach($items as $item){
            if($item)
                $favourites[$key][trim($item)] = 1;
        }
    }

    $_SESSION['favourites'] = $favourites;
}



function check_error($return_var): void
{
    if ( $return_var > 0 ) {
        header("Location: /error/");
        exit;
    }
}

function check_return_code($return_var,$output): void
{
    if ($return_var != 0) {
        $error = implode('<br>', $output);
        if (empty($error)) $error = __('Error code:',$return_var);
        $_SESSION['error_msg'] = $error;
    }
}

function top_panel($user, $TAB): void
{
    global $panel;
    $command = VESTA_CMD."v-list-user '".$user."' 'json'";
    exec ($command, $output, $return_var);
    if ( $return_var > 0 ) {
        header("Location: /error/");
        exit;
    }
    $panel = json_decode(implode('', $output), true);
    unset($output);


    // getting notifications
    $command = VESTA_CMD."v-list-user-notifications '".$user."' 'json'";
    exec ($command, $output, $return_var);
    $notifications = json_decode(implode('', $output), true);
    foreach($notifications as $message){
        if($message['ACK'] == 'no'){
            $panel[$user]['NOTIFICATIONS'] = 'yes';
            break;
        }
    }
    unset($output);
}

function translate_date($date){
  $date = strtotime($date);
  return strftime("%d &nbsp;", $date).__(strftime("%b", $date)).strftime(" &nbsp;%Y", $date);
}

function humanize_time($usage=0): string
{
    if ( $usage > 60 ) {
        $usage = $usage / 60;
        if ( $usage > 24 ) {
             $usage = $usage / 24;

            $usage = number_format($usage);
            if ( $usage == 1 ) {
                $usage = $usage." ".__('day');
            } else {
                $usage = $usage." ".__('days');
            }
        } else {
            $usage = number_format($usage);
            if ( $usage == 1 ) {
                $usage = $usage." ".__('hour');
            } else {
                $usage = $usage." ".__('hours');
            }
        }
    } else {
        if ( $usage == 1 ) {
            $usage = $usage." ".__('minute');
        } else {
            $usage = $usage." ".__('minutes');
        }
    }
    return $usage;
}

function humanize_usage_size($usage=0) {
    if ( $usage > 1024 ) {
        $usage = $usage / 1024;
        if ( $usage > 1024 ) {
                $usage = $usage / 1024 ;
                if ( $usage > 1024 ) {
                    $usage = $usage / 1024 ;
                    $usage = number_format($usage, 2);
                } else {
                    $usage = number_format($usage, 2);
                }
        } else {
            $usage = number_format($usage, 2);
        }
    }

    return $usage;
}

function humanize_usage_measure($usage=0): string
{
    $measure = 'kb';

    if ( $usage > 1024 ) {
        $usage = $usage / 1024;
        if ( $usage > 1024 ) {
                $usage = $usage / 1024 ;
                if ( $usage > 1024 ) {
                    $measure = 'pb';
                } else {
                    $measure = 'tb';
                }
        } else {
            $measure = 'gb';
        }
    } else {
        $measure = 'mb';
    }

    return __($measure);
}


function get_percentage($used=0,$total=0): int|string
{
    // Convert parameters to numeric values to handle string inputs
    $used = is_numeric($used) ? (float)$used : 0;
    $total = is_numeric($total) ? (float)$total : 0;

    if ( $total == 0 ) {
        $percent = 0;
    } else {
        $percent = 100 * $used / $total;
        $percent = number_format($percent, 0, '', '');
        if ( $percent > 100 ) {
            $percent = 100;
        }
        if ( $percent < 0 ) {
            $percent = 0;
        }
    }
    return $percent;
}

function send_email($to,$subject,$mailtext,$from): void
{
    $charset = "utf-8";
    $to = '<'.$to.'>';
    $boundary = '--' . md5( uniqid("myboundary") );
    $priorities = array( '1 (Highest)', '2 (High)', '3 (Normal)', '4 (Low)', '5 (Lowest)' );
    $priority = $priorities[2];
    $ctencoding = "8bit";
    $sep = chr(13) . chr(10);
    $disposition = "inline";
    $subject = "=?$charset?B?".base64_encode($subject)."?=";
    $header = "From: $from \nX-Priority: $priority\nCC:\n";
    $header .= "Mime-Version: 1.0\nContent-Type: text/plain; charset=$charset \n";
    $header .= "Content-Transfer-Encoding: $ctencoding\nX-Mailer: Php/libMailv1.3\n";
    $message = $mailtext;
    mail($to, $subject, $message, $header);
}

function list_timezones(): array
{
    // Map timezone abbreviations to proper IANA timezone identifiers
    $timezone_mappings = [
        'HAST' => 'Pacific/Honolulu',        // Hawaii-Aleutian Standard Time
        'HADT' => 'Pacific/Honolulu',        // Hawaii-Aleutian Daylight Time
        'AKST' => 'America/Anchorage',       // Alaska Standard Time
        'AKDT' => 'America/Anchorage',       // Alaska Daylight Time
        'PST'  => 'America/Los_Angeles',     // Pacific Standard Time
        'PDT'  => 'America/Los_Angeles',     // Pacific Daylight Time
        'MST'  => 'America/Denver',          // Mountain Standard Time
        'MDT'  => 'America/Denver',          // Mountain Daylight Time
        'CST'  => 'America/Chicago',         // Central Standard Time
        'CDT'  => 'America/Chicago',         // Central Daylight Time
        'EST'  => 'America/New_York',        // Eastern Standard Time
        'EDT'  => 'America/New_York',        // Eastern Daylight Time
        'AST'  => 'America/Halifax',         // Atlantic Standard Time
        'ADT'  => 'America/Halifax',         // Atlantic Daylight Time
    ];

    $timezone_offsets = [];

    // Process the mapped timezones
    foreach ($timezone_mappings as $abbr => $iana_timezone) {
        try {
            $tz = new DateTimeZone($iana_timezone);
            $timezone_offsets[$abbr] = $tz->getOffset(new DateTime);
        } catch (Exception $e) {
            // Skip invalid timezones
            continue;
        }
    }

    // Add all IANA timezone identifiers
    foreach(DateTimeZone::listIdentifiers() as $timezone){
        try {
            $tz = new DateTimeZone($timezone);
            $timezone_offsets[$timezone] = $tz->getOffset(new DateTime);
        } catch (Exception $e) {
            // Skip invalid timezones
            continue;
        }
    }

    $timezone_list = [];
    foreach($timezone_offsets as $timezone => $offset){
        $offset_prefix = $offset < 0 ? '-' : '+';
        $offset_formatted = gmdate( 'H:i', abs($offset) );
        $pretty_offset = "UTC{$offset_prefix}{$offset_formatted}";
        
        try {
            // Use the mapped timezone if it's an abbreviation, otherwise use the timezone as-is
            $tz_identifier = $timezone_mappings[$timezone] ?? $timezone;
            $t = new DateTimeZone($tz_identifier);
            $c = new DateTime(null, $t);
            $current_time = $c->format('H:i:s');
            $timezone_list[$timezone] = "$timezone [ $current_time ] {$pretty_offset}";
        } catch (Exception $e) {
            // Skip if we can't create the timezone
            continue;
        }
    }
    
    return $timezone_list;
}

/**
 * A function that tells is it MySQL installed on the system, or it is MariaDB.
 *
 * Explaination:
 * $_SESSION['DB_SYSTEM'] has 'mysql' value even if MariaDB is installed, so you can't figure out is it really MySQL or it's MariaDB.
 * So, this function will make it clear.
 * 
 * If MySQL is installed, function will return 'mysql' as a string.
 * If MariaDB is installed, function will return 'mariadb' as a string.
 * 
 * Hint: if you want to check if PostgreSQL is installed - check value of $_SESSION['DB_SYSTEM']
 *
 * @return string
 */
function is_it_mysql_or_mariadb(): string
{
    exec (VESTA_CMD."v-list-sys-services json", $output, $return_var);
    $data = json_decode(implode('', $output), true);
    unset($output);
    $mysqltype='mysql';
    if (isset($data['mariadb'])) $mysqltype='mariadb';
    return $mysqltype;
}

/**
 * Execute Vesta command with debug functionality and error handling
 *
 * @param string $command The Vesta command to execute (without the v- prefix)
 * @param array $args Array of arguments for the command
 * @param bool $json Whether to expect JSON output (default: false)
 * @param bool $debug Whether to enable debug output (default: false)
 * @return array Returns array with 'success', 'data', 'output', 'return_code', 'command', 'execution_time'
 */
function vesta_exec($command, $args = [], $json = false, $debug = VESTA_DEBUG): array
{
    // Start timing
    $start_time = microtime(true);

    // Sanitize command name
    $command = preg_replace('/[^a-zA-Z0-9\-_]/', '', $command);

    // Add v- prefix if not present
    if (!str_starts_with($command, 'v-')) {
        $command = 'v-' . $command;
    }

    // Escape arguments
    $escaped_args = [];
    foreach ($args as $arg) {
        $escaped_args[] = escapeshellarg($arg);
    }

    // Build full command
    $full_command = VESTA_CMD . $command;
    if (!empty($escaped_args)) {
        $full_command .= ' ' . implode(' ', $escaped_args);
    }
    if ($json) {
        $full_command .= ' json';
    }

    // Debug output
    if ($debug) {
        error_log("[VESTA_DEBUG] Executing: " . $full_command);
    }

    // Execute command
    $output = [];
    $return_code = 0;
    exec($full_command, $output, $return_code);

    // Calculate execution time
    $execution_time = microtime(true) - $start_time;

    // Process output
    $data = null;
    if ($json && !empty($output)) {
        $json_string = implode('', $output);
        $data = json_decode($json_string, true);

        if (json_last_error() !== JSON_ERROR_NONE) {
            if ($debug) {
                error_log("[VESTA_DEBUG] JSON decode error: " . json_last_error_msg());
                error_log("[VESTA_DEBUG] Raw output: " . $json_string);
            }
        }
    }

    // Debug output
    if ($debug) {
        error_log("[VESTA_DEBUG] Return code: " . $return_code);
        error_log("[VESTA_DEBUG] Execution time: " . number_format($execution_time * 1000, 2) . "ms");
        error_log("[VESTA_DEBUG] Output lines: " . count($output));
        if ($return_code !== 0) {
            error_log("[VESTA_DEBUG] Error output: " . implode("\n", $output));
        }
    }

    return [
        'success' => $return_code === 0,
        'data' => $data,
        'output' => $output,
        'return_code' => $return_code,
        'command' => $full_command,
        'execution_time' => $execution_time
    ];
}

/**
 * Simplified wrapper for common Vesta commands that expect JSON output
 *
 * @param string $command The Vesta command to execute
 * @param array $args Array of arguments for the command
 * @param bool $debug Whether to enable debug output
 * @return array|null Returns parsed JSON data or null on error
 */
function vesta_exec_json($command, $args = [], $debug = VESTA_DEBUG): ?array
{
    $result = vesta_exec($command, $args, true, $debug);

    if (!$result['success']) {
        if ($debug) {
            error_log("[VESTA_ERROR] Command failed: " . $result['command']);
        }
        return null;
    }

    return $result['data'];
}

/**
 * Execute Vesta command and handle errors automatically
 *
 * @param string $command The Vesta command to execute
 * @param array $args Array of arguments for the command
 * @param bool $json Whether to expect JSON output
 * @param bool $redirect_on_error Whether to redirect to error page on failure
 * @param bool $debug Whether to enable debug output
 * @return array|bool Returns data on success, false on error
 */
function vesta_exec_safe($command, $args = [], $json = false, $redirect_on_error = true, $debug = VESTA_DEBUG): bool|array
{
    $result = vesta_exec($command, $args, $json, $debug);

    if (!$result['success']) {
        if ($redirect_on_error && $result['return_code'] > 0) {
            header("Location: /error/");
            exit;
        }

        // Set error message in session
        $error = implode('<br>', $result['output']);
        if (empty($error)) {
            $error = __('Error code:', $result['return_code']);
        }
        $_SESSION['error_msg'] = $error;

        return false;
    }

    return $json ? $result['data'] : $result['output'];
}
