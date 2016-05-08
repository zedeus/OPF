<?php  
    if($_POST['action'] == 'feed') {
        system("python /var/www/html/scripts/feed.py");
    }
    else {
        $schedule = $_POST['action']; 
        echo $schedule;
        file_put_contents("/var/www/html/data/schedule", $schedule); 
    }
?>