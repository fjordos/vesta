<?php

define('NO_AUTH_REQUIRED',true);
header('Content-Type: application/json');

// Main include
include($_SERVER['DOCUMENT_ROOT']."/inc/main.php");

$TAB = 'LOGIN';

// Logout
if (isset($_GET['logout'])) {
    session_destroy();
}

// Login as someone else
if (isset($_SESSION['user'])) {
    if ((!isset($_GET['token'])) || ($_SESSION['token'] != $_GET['token'])) {
        session_destroy();
        session_start();
        exit();
    }
    if ($_SESSION['user'] == 'admin' && !empty($_GET['loginas'])) {
        exec (VESTA_CMD . "v-list-user ".escapeshellarg($_GET['loginas'])." json", $output, $return_var);
        if ( $return_var == 0 ) {
            $users = json_decode(implode('', $output), true);
            reset($users);
            $_SESSION['look'] = key($users);
            $_SESSION['look_alert'] = 'yes';
        }
    } else {
    	$v_user = empty($_SESSION['look']) ? $_SESSION['user'] : $_SESSION['look'];
    	exec (VESTA_CMD . "v-list-user ".$v_user." json", $output, $return_var);
        $users = json_decode(implode('', $output), true);
    }
}

// Basic auth
if (isset($_POST['user']) && isset($_POST['password'])) {
    if(isset($_SESSION['token']) && isset($_POST['token']) && $_POST['token'] == $_SESSION['token']) {
        $v_user = escapeshellarg($_POST['user']);
        $v_password = escapeshellarg($_POST['password']);

        if($_POST['user'] == 'root'){
            unset($_POST['password']);
            unset($_POST['user']);
            $error = __('Login with root has been disabled');
        } else {
            // Check user password
            exec(VESTA_CMD ."v-check-user-password ".$v_user." ".$v_password,  $output, $return_var);
            unset($output);

            // Check API answer
            if ( $return_var > 0 ) {
                $error = __('Invalid username or password');
            } else {

                // Make root admin user
                // if ($_POST['user'] == 'root') $v_user = 'admin';

                // Get user speciefic parameters
                exec (VESTA_CMD . "v-list-user ".$v_user." json", $output, $return_var);
                $users = json_decode(implode('', $output), true);

                // Define session user
                $_SESSION['user'] = key($users);
                $v_user = $_SESSION['user'];
                $_SESSION['root_dir'] = $users[$v_user]['HOME'];

                // Get user favorites
                get_favourites();

                // Define language
                $output = '';
                exec (VESTA_CMD."v-list-sys-languages json", $output, $return_var);
                $languages = json_decode(implode('', $output), true);
                if (in_array($users[$v_user]['LANGUAGE'], $languages)){
                    $_SESSION['language'] = $users[$v_user]['LANGUAGE'];
                } else {
                    $_SESSION['language'] = 'en';
                }

                // Regenerate session id to prevent session fixation
                session_regenerate_id(true);
            }
        }
    } else {
        $error = __('Invalid or missing token');
    }
}

// Check system configuration
exec (VESTA_CMD . "v-list-sys-config json", $output, $return_var);
$data = json_decode(implode('', $output), true);
$sys_arr = $data['config'];
foreach ($sys_arr as $key => $value) {
    $_SESSION[$key] = $value;
}

// Detect language
if (empty($_SESSION['language'])) {
    $output = '';
    exec (VESTA_CMD."v-list-sys-config json", $output, $return_var);
    $config = json_decode(implode('', $output), true);
    $lang = $config['config']['LANGUAGE'];

    $output = '';
    exec (VESTA_CMD."v-list-sys-languages json", $output, $return_var);
    $languages = json_decode(implode('', $output), true);
    if(in_array($lang, $languages)){
        $_SESSION['language'] = $lang;
    }
    else {
        $_SESSION['language'] = 'en';
    }
}

if (empty($_SESSION['token'])) {
    // Generate CSRF token
    $token = bin2hex(file_get_contents('/dev/urandom', false, null, 0, 16));
    $_SESSION['token'] = $token;
}

require_once($_SERVER['DOCUMENT_ROOT'].'/inc/i18n/'.$_SESSION['language'].'.php');

$v_user = empty($_SESSION['look']) ? $_SESSION['user'] : $_SESSION['look'];
top_panel($v_user, $TAB);

$panel[$v_user]['U_BANDWIDTH_MEASURE'] = humanize_usage_measure($panel[$v_user]['U_BANDWIDTH']);
$panel[$v_user]['U_BANDWIDTH'] = humanize_usage_size($panel[$v_user]['U_BANDWIDTH']);

$panel[$v_user]['U_DISK_MEASURE'] = humanize_usage_measure($panel[$v_user]['U_DISK']);
$panel[$v_user]['U_DISK'] = humanize_usage_size($panel[$v_user]['U_DISK']);

$result = array(
    'token' => $_SESSION['token'],
    'panel' => $panel,
    'data' => $users[$v_user],
    'user' => $v_user,
    'session' => $_SESSION,
    'i18n' => $LANG[$_SESSION['language']],
    'error' => $error,
);

echo json_encode($result);