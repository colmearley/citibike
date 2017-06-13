curl_raw:{.j.k first system"curl -sS ",x}
curl:{curl_raw[x]`data}
atan2:{[y;x] u:atan[y%x]; ?[x<0.0;?[u>=0.0;u-22%7;u+22%7];u]}

posixqtime:{`datetime$1970.01.01D+1000000000*`long$x}
genurl:"https://gbfs.citibikenyc.com/gbfs/gbfs.json"

getgenurl:{exec name!url from update `$name from curl[genurl][`en;`feeds]}
urls:getgenurl[],`bikeangelsleaderboard`bikeangelspoints!("https://bikeangels-api.citibikenyc.com/bikeangels/v1/leaderboard";"https://bikeangels-api.citibikenyc.com/bikeangels/v1/scores")
getsysteminfo:{curl[urls[`system_information]]}
getsystemalerts:{update "I"$alert_id, `$Type, "I"$station_ids, posixqtime last_updated from `alert_id`Type xcol curl[urls[`system_alerts]]`alerts}
getstationinfo:{update "I"$station_id,`$short_name,`$rental_methods from curl[urls`station_information]`stations}
getstationstatus:{update "I"$station_id,posixqtime last_reported from curl[urls`station_status]`stations}
getstationinfostatuspoints:{update points_en:points_map[points] from `station_id xasc (uj/)`station_id xkey/:(getstationinfo[];getstationstatus[];getbikeangelsstationpoints[])}
getregions:{update "I"$region_id from curl[urls`system_regions]`regions}

getbikeangelsleaderboard:{update `$user from curl_raw[urls`bikeangelsleaderboard]`leaderboard}
getbikeangelsstationpoints:{update "I"$string station_id,`int$points from flip `station_id`points!(key;value)@\:curl_raw[urls`bikeangelspoints][`stations]}
points_map:0N -2 -1 0 1 2i!`none`take2`take1`none`return1`return2
googleapikey:"AIzaSyA83JE_NNqTl1WXB2tKI3tzNbR0UlTx7Mc"

getgoogleurl:{[lat0;lon0;lat1;lon1] "https://maps.googleapis.com/maps/api/directions/json?origin=",string[lat0],",",string[lon0],"&destination=",string[lat1],",",string[lon1],"&mode=walking&units=miles&key=",googleapikey}
getgoogleuiurl:{[lat0;lon0;lat1;lon1] "https://www.google.com/maps/dir/?api=1&origin=",string[lat0],",",string[lon0],"&destination=",string[lat1],",",string[lon1],"&travelmode=walking"}
getgoogleuiurltotal:{[start;end;lat0;lon0;lat1;lon1] "https://www.google.com/maps/dir/?api=1&origin=",string[start 0],",",string[start 1],"&waypoints=",string[lat0],",",string[lon0],"|",string[lat1],",",string[lon1],"&destination=",string[end 0],",",string[end 1],"&travelmode=bicycling"}
getdistance:{[url] sum raze[.j.k[raze system"curl -sS '",url,"'"][`routes][`legs][;`distance]]`value}

safeString:{$[type[x] in 0 98 99h;.z.s each x;type[x]=10h;x;string x]}
htmltable:{"<table>\n",({"<tr>\n",raze[{"<th>",safeString[x],"</th>\n"}each cols x],"</tr>\n"}[x],raze {"<tr>\n",raze[{"<td>",safeString[x],"</td>\n"}each x],"</tr>\n"}each x),"</table>\n"}

hav:{[lat1;lon1;lat2;lon2]
  deg2rad:{x*(22%7)%180};
  R:6371000; dLat:deg2rad[lat2-lat1]; dLon:deg2rad[lon2-lon1];
  a:xexp[sin[dLat%2];2] + cos[deg2rad[lat1]] * cos[deg2rad[lat2]] * xexp[sin[dLon%2];2];
  c:2 * atan2[sqrt[a];sqrt[1-a]];
  d:R*c;
  d
 }

places:enlist[`]!enlist[2#0nf]
places[`work]:40.7526 -73.9902
places[`home]:40.7092 -74.0133

get_routes:{[start;end]
  station_info:getstationinfostatuspoints[];
  tbl:update loc1:station_info[([]station_id:station1)][;`lat`lon],loc2:station_info[([]station_id:station2)][;`lat`lon] from flip `station1`station2!flip exec station_id cross station_id from station_info;
  tbl:update startdis:hav[start 0;start 1] . flip loc1,bikedis:hav . flip (loc1,'loc2),enddis:hav[end 0;end 1] . flip loc2 from tbl;
  if[start~places`home;tbl:update startdis:0f from tbl where station1 in (exec station_id from station_info where name like "South End Ave & Liberty St")];
  tbl:`points xdesc `walkdis xasc update points:abs[min[(0;0^.Q.fu[station_info;([]station_id:station1)][;`points])]]+max[(0;0^.Q.fu[station_info;([]station_id:station2)][;`points])],walkdis:startdis+enddis from tbl;
  tbl:update name1:station_info[([]station_id:station1)][;`name],name2:station_info[([]station_id:station2)][;`name] from select from tbl where walkdis=(min;walkdis) fby points;
  tbl:update apirt0:getgoogleurl[start 0;start 1] .' loc1,apirt1:getgoogleurl[;;end 0;end 1] .' loc2,uirt0:getgoogleuiurl[start 0;start 1] .' loc1,uirt1:getgoogleuiurl[;;end 0;end 1] .' loc2,uitrt:getgoogleuiurltotal[start;end] .' (loc1,'loc2) from tbl;  
  tbl:update startgdis:(getdistance each apirt0),endgdis:getdistance each apirt1 from tbl;
  / select points,start:name1,end:name2,total_distance:startgdis+endgdis,start_distance:startgdis,end_distance:endgdis,start_route:html_link each uirt0,end_route:html_link each uirt1,start_map:html_map each uirt0,end_map:html_map each uirt1 from tbl
  select points,start:html_link'[uirt0;name1],end:html_link'[uirt1;name2],total_distance:startgdis+endgdis,start_distance:startgdis,end_distance:endgdis,html_link[;"route"]each uitrt from tbl
 }

html_link:{[url;text] "<a href=\"",url,"\">",text,"</a>"}
html_map:{"<iframe src=\"",x,"\" width=\"400\" height=\"300\" frameborder=\"0\" style=\"border:0\" allowfullscreen></iframe>"}

genmail:{[start;end]
  x:htmltable get_routes[start;end];
  header:"\"Citibike Angel Routes\nContent-Type: text/html\nMIME-Version: 1.0\nContent-Disposition: inline\n\"";
  system"echo '<html>\n<body>\n",x,"</body>\n</html>\n'|mail -s ",header," colmearley@gmail.com"
 } 

/ 
example walking from south end av @ liberty st to 8th av @ 33rd st is 3.226167 miles
getdistance . string value exec first lat,first lon, last lat, last lon from r'[3002 490]

/ matrix of distance between each station
r:getstationinfostatuspoints[]
r1:update loc1:r[([]station_id:station1)][;`lat`lon],loc2:r[([]station_id:station2)][;`lat`lon] from flip `station1`station2!flip exec station_id cross station_id from r
r1:update distance:hav . flip (loc1,'loc2) from r1
dismap:exec distance[;0] by station1,station2 from r1


r2:`station_id xasc ([]station_id:-1 -2i;lat:places[`home`work][;0]; lon:places[`home`work][;1]),select station_id,lat,lon from r
r3:update loc1:(`station_id xkey r2)[([]station_id:station1)][;`lat`lon],loc2:(`station_id xkey r2)[([]station_id:station2)][;`lat`lon] from flip `station1`station2!flip exec station_id cross station_id from r2
r3:update distance:hav . flip (loc1,'loc2) from r3
r3:update loc1:(`station_id xkey r2)[([]station_id:station1)][;`lat`lon],loc2:(`station_id xkey r2)[([]station_id:station2)][;`lat`lon] from flip `station1`station2!flip exec station_id cross station_id from r2

`walkdistance xasc raze { raze {[x;y] enlist `start`station1`station2`end`walkdistance`bikedistance!(x`station1;x`station2;y`station2;x`station1;x[`distance]+exec first distance from r3 where station1=y[`station2],station2=x[`station1];y[`distance])}[x]'[select from r3 where station1=x[`station2],station2 in exec station_id from r where points_en=`return2]}'[select from r3 where station1=-1,station2 in (exec station_id from r where points_en=`take2)]

