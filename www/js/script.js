function feed() {
  $.ajax({
       type: "POST",
       url: 'processing.php',
       data:{action:'feed'}
  });
}

function update_schedule() {
    var hours = document.getElementsByClassName("Hour");
    var minutes = document.getElementsByClassName("Minute");
    var ampm = document.getElementsByClassName("AMPM");
    var feeds = hours.length;
    var output = "";

    for (var i = 0; i < feeds; i++) {
        output += hours[i].value;
        output += ":" + minutes[i].value;
        output += " " + ampm[i].value;
        output += "\n";
    }

    $.ajax({
        type: "POST",
        url: 'processing.php',
        data: ({action: output}),
        success: function(data){
            console.log(data);
        }
    });
}

//
// Interface
//
function toggle_fullscreen(e) {

  var background = document.getElementById("background");

  if(!background) {
    background = document.createElement("div");
    background.id = "background";
    document.body.appendChild(background);
  }
  
  if(e.className == "fullscreen") {
    e.className = "normal";
    background.style.display = "none";
  }
  else {
    e.className = "fullscreen";
    background.style.display = "block";
  }

}

function set_preset(value) {
  var values = value.split(" ");
  document.getElementById("video_width").value = values[0];
  document.getElementById("video_height").value = values[1];
  document.getElementById("video_fps").value = values[2];
  
  set_res();
}

function set_res() {
  send_cmd("px " + document.getElementById("video_width").value + " " + document.getElementById("video_height").value + " " + document.getElementById("video_fps").value + " " + document.getElementById("video_fps").value + " " + document.getElementById("video_width").value + " " + document.getElementById("video_height").value);
  update_preview_delay();
  updatePreview(true);
}

//
// MJPEG
//
var mjpeg_img;
var halted = 0;
var previous_halted = 99;
var mjpeg_mode = 0;
var preview_delay = 0;

function reload_img () {
  if(!halted) mjpeg_img.src = "cam_pic.php?time=" + new Date().getTime() + "&pDelay=" + preview_delay;
  else setTimeout("reload_img()", 500);
}

function error_img () {
  setTimeout("mjpeg_img.src = 'cam_pic.php?time=' + new Date().getTime();", 100);
}

function updatePreview(cycle)
{
   if (mjpegmode)
   {
      if (cycle !== undefined && cycle == true)
      {
         mjpeg_img.src = "/updating.jpg";
         setTimeout("mjpeg_img.src = \"cam_pic_new.php?time=\" + new Date().getTime()  + \"&pDelay=\" + preview_delay;", 1000);
         return;
      }
      
      if (previous_halted != halted)
      {
         if(!halted)
         {
            mjpeg_img.src = "cam_pic_new.php?time=" + new Date().getTime() + "&pDelay=" + preview_delay;            
         }
         else
         {
            mjpeg_img.src = "/unavailable.jpg";
         }
      }
    previous_halted = halted;
   }
}

//
// Ajax Status
//
var ajax_status;

if(window.XMLHttpRequest) {
  ajax_status = new XMLHttpRequest();
}
else {
  ajax_status = new ActiveXObject("Microsoft.XMLHTTP");
}


ajax_status.onreadystatechange = function() {
  if(ajax_status.readyState == 4 && ajax_status.status == 200) {

    if(ajax_status.responseText == "ready") {
      halted = 0;
        updatePreview();
    }
    else if(ajax_status.responseText == "md_ready") {
      halted = 0;
        updatePreview();
    }
    else if(ajax_status.responseText == "tl_md_ready") {
      halted = 0;
        updatePreview();
    }
    else if(ajax_status.responseText == "halted") {
      halted = 1;
        updatePreview();
    }
    else if(ajax_status.responseText.substr(0,5) == "Error") {
        alert("Error in RaspiMJPEG: " + ajax_status.responseText.substr(7) + "\nRestart RaspiMJPEG (./RPi_Cam_Web_Interface_Installer.sh start) or the whole RPi.");
    }
    
    reload_ajax(ajax_status.responseText);

  }
}

function reload_ajax (last) {
  ajax_status.open("GET","status_mjpeg.php?last=" + last,true);
  ajax_status.send();
}

//
// Ajax Commands
//
var ajax_cmd;

if(window.XMLHttpRequest) {
  ajax_cmd = new XMLHttpRequest();
}
else {
  ajax_cmd = new ActiveXObject("Microsoft.XMLHTTP");
}

function send_cmd (cmd) {
  ajax_cmd.open("GET","cmd_pipe.php?cmd=" + cmd,true);
  ajax_cmd.send();
}

function update_preview_delay() {
   var video_fps = parseInt(document.getElementById("video_fps").value);
   var divider = parseInt(document.getElementById("divider").value);
   preview_delay = Math.floor(divider / Math.max(video_fps,1) * 1000000);
}

//
// Init
//
function init(mjpeg, video_fps, divider) {

  mjpeg_img = document.getElementById("mjpeg_dest");
  preview_delay = Math.floor(divider / Math.max(video_fps,1) * 1000000);
  if (mjpeg) {
    mjpegmode = 1;
  } else {
     mjpegmode = 0;
     mjpeg_img.onload = reload_img;
     mjpeg_img.onerror = error_img;
     reload_img();
  }
  reload_ajax("");
}
