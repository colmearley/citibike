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
getstationinfostatuspoints:{update points_en:points_map[points] from update 0^points from `station_id xasc (uj/)`station_id xkey/:(getstationinfo[];getstationstatus[];getbikeangelsstationpoints[])}
getregions:{update "I"$region_id from curl[urls`system_regions]`regions}

getbikeangelsleaderboard:{update `$user from curl_raw[urls`bikeangelsleaderboard]`leaderboard}
getbikeangelsstationpoints:{update "I"$string station_id,`int$points from flip `station_id`points!(key;value)@\:curl_raw[urls`bikeangelspoints][`stations]}
points_map:0N -2 -1 0 1 2i!`none`take2`take1`none`return1`return2
googleapikey:"AIzaSyA83JE_NNqTl1WXB2tKI3tzNbR0UlTx7Mc"

getgoogleurl:{[lat0;lon0;lat1;lon1] "https://maps.googleapis.com/maps/api/directions/json?origin=",string[lat0],",",string[lon0],"&destination=",string[lat1],",",string[lon1],"&mode=walking&units=miles&key=",googleapikey}
getgoogleuiurl:{[lat0;lon0;lat1;lon1] "https://www.google.com/maps/dir/?api=1&origin=",string[lat0],",",string[lon0],"&destination=",string[lat1],",",string[lon1],"&travelmode=walking"}
getgoogleuiurltotal:{[start;end;lat0;lon0;lat1;lon1] "https://www.google.com/maps/dir/?api=1&origin=",string[start 0],",",string[start 1],"&waypoints=",string[lat0],",",string[lon0],"|",string[lat1],",",string[lon1],"&destination=",string[end 0],",",string[end 1],"&travelmode=bicycling"}
getdistance:{[url] sum raze[.j.k[raze system"curl -sS '",url,"'"][`routes][`legs][;`distance]]`value}
googledistance:{[lat0;lon0;lat1;lon1] getdistance each getgoogleurl .' flip (),/:(lat0;lon0;lat1;lon1)}

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

box_loc:{[lat;lon;dis]
  R:6371000;
  deg2rad:{((22%7)*x)%180};
  rad2deg:{(180*x)%(22%7)};
  lon1:lon - rad2deg[dis%R%cos[deg2rad[lat]]];
  lon2:lon + rad2deg[dis%R%cos[deg2rad[lat]]];
  lat1:lat + rad2deg[dis%R];
  lat2:lat - rad2deg[dis%R];
  ((lat1;lon1);(lat1;lon2);(lat2;lon1);(lat2;lon2))
 }
manhattan_distance:{[lat1;lon1;lat2;lon2]  hav[lat1;lon1;lat2;lon1]+hav[lat1;lon1;lat1;lon2]}

places:enlist[`]!enlist[2#0nf]
places[`work]:40.7526 -73.9902
places[`home]:40.7092 -74.0133
places[`1010]:40.75366 -73.97241
favorites:enlist[`]!enlist ""
favorites[`home]:"South End Ave & Liberty St"
favorites[`work]:"8 Ave & W 33 St"

get_routes:{[start_name;end_name]
  start:places[start_name]; end:places[end_name];
  station_info:getstationinfostatuspoints[];
  tbl1:select name,points,lat,lon,start_dis:?[name like favorites[start_name];0;hav[start 0;start 1] . (lat;lon)], end_dis:?[name like favorites[end_name];0;hav[end 0;end 1] . (lat;lon)] from station_info;
  tbls:select station1:name,lat1:lat,lon1:lon,points1:points,start_dis from tbl1 where start_dis=(min;start_dis) fby points;
  tble:select station2:name,lat2:lat,lon2:lon,points2:points,end_dis from tbl1 where end_dis=(min;end_dis) fby points;
  tbl2:select from (update points:?[(points1>0) or (points2<0);0;abs[points1]+points2] from tbls cross tble) where (start_dis+end_dis)=(min;start_dis+end_dis) fby points;
  tbl2:select points,start:{[start;name;points;lat;lon] html_link[getgoogleuiurl[start 0;start 1;lat;lon];name," (",string[points],")"]}[start]'[station1;points1;lat1;lon1],station1,end:{[end;name;points;lat;lon] html_link[getgoogleuiurl[end 0;end 1;lat;lon];name," (",string[points],")"]}[start]'[station2;points2;lat2;lon2],station2,start_distance:getdistance each getgoogleurl[start 0;start 1]'[lat1;lon1],end_distance:getdistance each getgoogleurl[;;end 0;end 1]'[lat2;lon2],route:html_link[;"route"] each getgoogleuiurltotal[start;end]'[lat1;lon1;lat2;lon2] from tbl2;
  `points xdesc `total_distance xasc `points`start`station1`end`station2`total_distance`start_distance`end_distance`route xcols update total_distance:start_distance+end_distance from tbl2
 }

html_link:{[url;text] "<a href=\"",url,"\">",text,"</a>"}
html_map:{"<iframe src=\"",x,"\" width=\"400\" height=\"300\" frameborder=\"0\" style=\"border:0\" allowfullscreen></iframe>"}

genmail:{[start;end]
  r:get_routes[start;end];
  x:htmltable select points,start,end,total_distance,start_distance,end_distance,route from r;
  header:"\"Citibike Angel Routes\nContent-Type: text/html\nMIME-Version: 1.0\nContent-Disposition: inline\n\"";
  system"echo '<html>\n<body>\n",x,"</body>\n</html>\n'|mail -s ",header," colmearley@gmail.com";
  select points,start:station1,end:station2,total_distance,start_distance,end_distance from r
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

