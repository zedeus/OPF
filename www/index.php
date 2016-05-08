<!DOCTYPE html>
<?php
   define('BASE_DIR', dirname(__FILE__));
   require_once(BASE_DIR.'/config.php');
   $config = array();
   $debugString = "";
   
   $options_fl = array('None' => '0', 'Horizontal' => '1', 'Vertical' => '2', 'Both' => '3');

   function parseSchedule($scheduleFile) {
      $parsedSchedule = array();
      if (file_exists($scheduleFile)) {
         $lines = array();
         $data = file_get_contents($scheduleFile);
         $lines = explode("\n", $data);
         for ($linenum=0; $linenum < count($lines); $linenum++) { 
            $line = $lines[$linenum];
            $parsedSchedule[(1 + $linenum) . "Hour"  ] = substr($line, 0, 2);
            $parsedSchedule[(1 + $linenum) . "Minute"] = substr($line, 3, 2);
            $parsedSchedule[(1 + $linenum) . "AMPM"  ] = substr($line, -2);
         }
      }
      return $parsedSchedule;
   }

   function makeRangedDropDown($name, $start, $index, $end, $range) {
      $schedule = parseSchedule("/var/www/html/data/schedule");
      echo "$name: <select class=$name>";
      for ($count = $start; $count <= $end; $count += $range) {
         $prefix = $count < 10 ? 0 : '';
         $selected = '';

         if ($count == $schedule[$index . $name]) {
            $selected = ' selected';
         }

         echo "<option value='$prefix$count' $selected>$prefix$count</option>";
      }
      echo "</select> ";
   }

   function makeAMPMDropDown($feed) {
      $schedule = parseSchedule("/var/www/html/data/schedule");
      $am = $schedule[$feed . "AMPM"] == "AM" ? "'AM' selected" : "'AM'";  
      $pm = $schedule[$feed . "AMPM"] == "PM" ? "'PM' selected" : "'PM'";  
      $amorpm = $schedule[$feed . "AMPM"];
      echo "AM/PM: <select class='AMPM'>";
         echo "<option value=$am>AM</option>";
         echo "<option value=$pm>PM</option>";
      echo "</select>";
   }

   function getExtraStyles() {
      $files = scandir('css');
      foreach($files as $file) {
         if(substr($file,0,3) == 'es_') {
            echo "<option value='$file'>" . substr($file,3, -4) . '</option>';
         }
      }
   }

   function makeOptions($options, $selKey) {
      global $config;
      switch ($selKey) {
         case 'flip':
            $cvalue = (($config['vflip'] == 'true') || ($config['vflip'] == 1) ? 2:0);
            $cvalue += (($config['hflip'] == 'true') || ($config['hflip'] == 1) ? 1:0);
            break;
         default: $cvalue = $config[$selKey]; break;
      }
      if ($cvalue == 'false') $cvalue = 0;
      else if ($cvalue == 'true') $cvalue = 1;
      foreach($options as $name => $value) {
         if ($cvalue != $value) {
            $selected = '';
         } else {
            $selected = ' selected';
         }
         echo "<option value='$value'$selected>$name</option>";
      }
   }

   function makeInput($id, $size, $selKey='') {
      global $config, $debugString;
      if ($selKey == '') $selKey = $id;
      switch ($selKey) {
         default: $value = $config[$selKey]; break;
      }
      echo "<input type='text' size=$size id='$id' value='$value'>";
   }

   function getImgWidth() {
      global $config;
      if($config['vector_preview'])
         return 'style="width:' . $config['width'] . 'px;"';
      else
         return '';
   }

   function getLoadClass() {
      global $config;
      if(array_key_exists('fullscreen', $config) && $config['fullscreen'] == 1)
         return 'class="fullscreen" ';
      else
         return '';
   }

   if (isset($_POST['extrastyle'])) {
      if (file_exists('css/' . $_POST['extrastyle'])) {
         $fp = fopen(BASE_DIR . '/css/extrastyle.txt', "w");
         fwrite($fp, $_POST['extrastyle']);
         fclose($fp);
      }
   }

   $toggleButton = "Simple";
   $displayStyle = 'style="display:block;"';
   if(isset($_COOKIE["display_mode"])) {
      if($_COOKIE["display_mode"] == "Simple") {
         $toggleButton = "Full";
         $displayStyle = 'style="display:none;"';
      }
   }
   
   $config = readConfig($config, CONFIG_FILE1);
   $config = readConfig($config, CONFIG_FILE2);
   $divider = $config['divider'];
   $video_fps = $config['video_fps'];
   $title = "Pet Feeder";
?>

<html>
   <head>
      <meta name="viewport" content="width=50, initial-scale=1">
      <title><?php echo $title; ?></title>
      <link rel="stylesheet" href="css/style_minified.css"/>
      <script src="js/style_minified.js"></script>
      <script src="js/script.js"></script>
   </head>
   <body onload="setTimeout('init(<?php echo "0, $video_fps, $divider" ?>);', 100);">
      <div class="navbar navbar-inverse navbar-fixed-top" role="navigation" <?php echo $displayStyle; ?>>
         <div class="container">
            <div class="navbar-header">
               <a class="navbar-brand" href="#"><?php echo "<h4>$title</h4>"; ?></a>
            </div>
         </div>
      </div>
      <div class="container-fluid text-center liveimage">
         <div>
            <img id="mjpeg_dest" <?php echo getLoadClass().getImgWidth();?> onclick="toggle_fullscreen(this);" src="./loading.jpg" class="normal"><br>
            <input type="button" value="Feed" onclick="feed()" class="btn btn-primary"> 
         </div>
      </div>
   </div>
   <div class="container-fluid text-center">
      <div class="panel-group" id="accordion" <?php echo $displayStyle; ?>>
         <div class="panel panel-default">
            <div class="panel-heading">
               <h2 class="panel-title">
                  <a data-toggle="collapse" data-parent="#accordion" href="#collapseOne">Feeding Schedule</a>
               </h2>
            </div>
            <div id="collapseOne" class="panel-collapse collapse">
               <?php 
                  echo '<table class="settingsTable id="scheduleTable">';
                  for ($feed = 1; $feed <= 3; $feed++) {
                     echo "<th><br>Scheduled Feed $feed </th>";
                        echo "<tr>";
                           echo "<td>";
                              makeRangedDropDown("Hour", 1, $feed, 12, 1);
                              makeRangedDropDown("Minute", 0, $feed, 50, 10); 
                              makeAMPMDropDown($feed);
                           echo "</td>";
                        echo "</tr>";
                  }
                  echo '</table>';
               ?><br>
               <input type="button" value="Update Schedule" onclick="update_schedule();"><br><br>
            </div>
         </div>
      </div>
   </div>
   <div class="container-fluid text-center">
      <div class="panel-group" id="accordion2" <?php echo $displayStyle; ?>>
         <div class="panel panel-default">
            <div class="panel-heading">
               <h2 class="panel-title">
                  <a data-toggle="collapse" data-parent="#accordion2" href="#collapseTwo">Camera Settings</a>
               </h2>
            </div>
            <div id="collapseTwo" class="panel-collapse collapse">
               <table class="settingsTable">
                  <th><br>Video</th>
                  <tr>
                     <td>Preset: 
                        <select onchange="set_preset(this.value)">
                           <option value="1920 1080 25">Full HD 1080p 16:9</option>
                           <option value="1280 0720 25">HD-ready 720p 16:9</option>
                           <option value="1296 0972 25">Max View 972p 4:3</option>
                        </select><br>
                        Resolution: <?php makeInput('video_width', 1); ?> x <?php makeInput('video_height', 1); ?><br>
                        FPS: <?php makeInput('video_fps', 1); ?><br>
                        <input type="button" value="Update" onclick="set_res();">
                     </td>
                  </tr>
                  <th><br>Annotation (max 127 characters)</th>
                  <tr>
                     <td>
                        Text: <?php makeInput('annotation', 20); ?><input type="button" value="Update" onclick="send_cmd('an ' + encodeURI(document.getElementById('annotation').value))"><input type="button" value="Default" onclick="document.getElementById('annotation').value = 'RPi Cam %Y.%M.%D_%h:%m:%s'; send_cmd('an ' + encodeURI(document.getElementById('annotation').value))"><br>
                     </td>
                  </tr>
                  <tr>
                  <th><br>Flip</th>
                  <tr>
                     <td>Default 'None': <select onchange="send_cmd('fl ' + this.value)"><?php makeOptions($options_fl, 'flip'); ?></select></td>
                  </tr>
               </table><br>
            </div>
         </div>
      </div>
   </div>
   <?php if ($debugString != "") echo "$debugString<br>"; ?>
   </body>
</html>
