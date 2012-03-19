<?php
    error_reporting(-1);  
    mysql_connect('localhost','bldev','bldev7');
    mysql_select_db('bldev') or die("Unable to select database");

    if (isset($_GET['action'])) {
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
        var url = "/kv.php?interval=24%20HOUR&imageonly=1&width=640&height=480&keys[]=us/co/montrose/1001s2nd/warmdirt/1/data/temperatureboxexterior&keys[]=us/co/montrose/1001s2nd/warmdirt/1/data/temperatureboxinterior&keys[]=us/co/montrose/1001s2nd/warmdirt/1/data/temperatureheateddirt&keys[]=us/co/montrose/1001s2nd/warmdirt/1/data/temperaturepotteddirt&keys[]=us/co/montrose/1001s2nd/warmdirt/1/data/temperatureoutside&multigraph=1&action=multi";
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
            $("#temperatureoutside").html(data.temperatureoutside);
            $("#extral").html(data.temperaturesetpoint);

            if (data.load1on == '1') {
                $("#lightlabel").html("<a href='http://192.168.0.117:7764/light=off'>Light</a>");
            } else {
                $("#lightlabel").html("<a href='http://192.168.0.117:7764/light=on'>Light</a>");
            }
            $("#light").html(data.lightstate);
            $("#extrar").html(data.pidoutput);
            $("#lid").html(data.lidstate);
            $("#lidlabel").html("Lid sw="+data.lidclosed);
        });
    }

    $(document).ready(function(){
        statusload();
        graphload();
        setInterval(statusload,15000);
        setInterval(graphload,240000);
        $("#lightlabel").click(function() {
            setTimeout(statusload,5000);
        });
    });
</script>

</head>
<body>
<center>
<table id='datatable'>
<div id='header'>Warm Dirt Status</div>
<tr>
    <td class='label'>Last Update</td><td class='data' id="timestamp"></td>
    <td class='label'>Outside Air</td> <td class='data' id="temperatureoutside"> </td>
</tr>
<tr>
    <td class='label' id='lightlabel'>Light</td> <td class='data' id="light"> </td>
    <td class='label'>Greenhouse Air</td><td class='data' id="temperatureboxexterior"> </td>
</tr>
<tr>
    <td class='label' id='lidlabel'>Lid</td><td class='data' id="lid"></td>
    <td class='label'>Box Air</td><td class='data' id="temperatureboxinterior"> </td>
</tr>
<tr>
    <td class='label'>Heated Set</td><td class='data' id="extral"> </td>
    <td class='label'>Potted Dirt</td> <td class='data' id="temperaturepotteddirt"> </td>
</tr>
<tr>
    <td class='label'>PID Out </td> <td class='data' id="extrar"> </td>
    <td class='label'>Heated Dirt</td> <td class='data' id="temperatureheateddirt"> </td>
</tr>
</table>
<div id='graphdiv'>
</div>

</body>
</html>
