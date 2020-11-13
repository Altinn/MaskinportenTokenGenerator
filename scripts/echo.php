<?php

p($_SERVER['REQUEST_METHOD'] . " " . $_SERVER['SCRIPT_NAME'] . " " . $_SERVER['SERVER_PROTOCOL'] . "\n\n");

foreach (getallheaders() as $k => $v) {
    p("$k: $v\n");
}
p("\n");
p(file_get_contents("php://input"));

function p($str) {
    $stdout = fopen('php://stdout', 'w');
    fwrite($stdout, $str);
}