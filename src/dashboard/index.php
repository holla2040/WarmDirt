<?php
    error_reporting(-1);  
    mysql_connect('localhost','bldev','bldev7');
    mysql_select_db('bldev') or die("Unable to select database");

    if ($_GET['action'] == "status") {
        $query="select timestamp,k,v from kv where k LIKE 'us/co/montrose/1001s2nd/warmdirt/1/data/%'";
        $result = mysql_query($query) or die("query failed");
        $r = "{";
        while($row = mysql_fetch_array($result)) {
            $k = substr($row['k'],40);
            if ((time() - strtotime($row['timestamp'])) < 300) { 
                $r .= '"'.$k.'":"'.$row['v'].'",'."\n";
            } else {
                $r .= '"'.$k.'":"",'."\n";
            }
            $ts = $row['timestamp'];
        }
        $r .= '"'."timestamp".'":"'.$ts.'"'."\n";
        $r .="}";
        echo $r;
        return;
    }
?>
<html>
<head>
<title>Warm Dirt Status</title>
<meta http-equiv="refresh" content="300000">
<link REL=stylesheet HREF="warmdirt.css" TYPE="text/css">
<script src="jquery.js"></script>
<script type="text/javascript">
    function graphload() {
        var url = "/kv.php?imageonly=1&width=640&height=480&keys[]=us/co/montrose/1001s2nd/warmdirt/1/data/temperatureboxexterior&keys[]=us/co/montrose/1001s2nd/warmdirt/1/data/temperatureboxinterior&keys[]=us/co/montrose/1001s2nd/warmdirt/1/data/temperatureheateddirt&keys[]=us/co/montrose/1001s2nd/warmdirt/1/data/temperaturepotteddirt&multigraph=1&action=multi";
        var image1 = $('<img />').attr("src",url)
            .load(function(){
                //$("#graph").attr("src", url); <img src="/images/graph.gif" id="graph" width="800" height="600"/>
                $('body').css('background',"url("+url+") no-repeat fixed center top");
            });
    }

    function statusload() {
        $.getJSON('index.php?action=status', function(data) {
            $("#timestamp").html(data.timestamp.substr(5,100));
            $("#temperatureheateddirt").html(data.temperatureheateddirt);
            $("#temperaturepotteddirt").html(data.temperaturepotteddirt);
            $("#temperatureboxexterior").html(data.temperatureboxexterior);
            $("#temperatureboxinterior").html(data.temperatureboxinterior);
            if (data.load0on == '1') {
                $("#load0on").html("On");
            } else {
                $("#load0on").html("Off");
            }
            $("#extra").html(data.pidoutput);
        });
    }

    $(document).ready(function(){
        statusload();
        graphload();
        setInterval(statusload,60000);
        setInterval(graphload,240000);
    });
</script>

</head>
<body>
<center>
<table id='datatable'>
<div id='header'>Warm Dirt Status</div>
<tr><td class='label'>Last Update</td><td class='data' id="timestamp"></td></tr>
<tr>
    <td class='label'>Greenhouse Air</td><td class='data' id="temperatureboxexterior"> </td>
    <td class='label'>Potted Dirt</td> <td class='data' id="temperaturepotteddirt"> </td>
</tr>
<tr>
    <td class='label'>Box Air</td><td class='data' id="temperatureboxinterior"> </td>
    <td class='label'>Heated Dirt</td> <td class='data' id="temperatureheateddirt"> </td>
</tr>
<tr>
    <td class='label'>Heater</td><td class='data' id="load0on"> </td>
    <td class='label'>PID Out </td> <td class='data' id="extra"> </td>
</tr>
</table>
<div id='graphdiv'>
</div>

</body>
</html>
