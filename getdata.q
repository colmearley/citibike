\l utils.q
\l cron.q
\l math.q
\l web.q
\l data.q
\l cache.q

generalUrl:"https://gbfs.citibikenyc.com/gbfs/gbfs.json"
angelUrls:([name:`bikeangelsleaderboard`bikeangelspoints] url:("https://bikeangels-api.citibikenyc.com/bikeangels/v1/leaderboard";"https://layer.bicyclesharing.net/map/v1/nyc/stations"))
getGeneralUrls:{select last url by `$name from .utils.getJsonUrl[generalUrl][`data][`en;`feeds]}
getGeneralUrlsC:.cache.init[`getGeneralUrls;24t;`name]
urls:{(getGeneralUrlsC[],angelUrls)[x;`url]}

getsysteminfo:{.utils.getJsonUrl[`system_information]`data}
norm:{((union/)cols each x)#/:x}
normt:{[x] ut:{$[98h~x;(`symbol$())!();x$""]}each {max[(x;y)]}/[()!();type each'x]; key[ut]#/:{[ut;x0] x0,cols[x0] _ ut}[ut]each x}
getsystemalerts:{update "I"$alert_id, `$Type, "I"$station_ids, .utils.posixqtime last_updated from `alert_id`Type xcol .utils.getJsonUrl[urls[`system_alerts]][`data;`alerts]}
getStationInfo:{update "I"$station_id,`$short_name,`$rental_methods from norm .utils.getJsonUrl[urls`station_information][`data;`stations]}
getStationInfoC:.cache.init[`getStationInfo;24t;`station_id]
getStationStatus:{update "I"$station_id,.utils.posixqtime last_reported from norm .utils.getJsonUrl[urls`station_status][`data;`stations]}
getStationStatusC:.cache.init[`getStationStatus;00:01t;`station_id]
getStationInfoStatusPoints:{select from (update points_en:points_map[points] from update 0^points from `station_id xasc (uj/)`station_id xkey/:(getStationInfoC[];getStationStatusC[];getBikeAngelsStationPointsC[])) where not null lat,not null lon}
getRegions:{update "I"$region_id from .utils.getJsonUrl[urls`system_regions][`data;`regions]}

getBikeAngelsLeaderboard:{update `$user from .utils.getJsonUrl[urls`bikeangelsleaderboard]`leaderboard}
getBikeAngelsStationPoints:{select "I"$station_id,name,num_bikes_available:0f^bikes_available,num_docks_available:0f^docks_available,points:{?[x=`take;neg y;y]}[`$bike_angels_action;0f^`float$bike_angels_points],0f^ebikes_available,ebikes from normt .utils.getJsonUrl[urls`bikeangelspoints][`features;;`properties]}
getBikeAngelsStationPointsC:.cache.init[`getBikeAngelsStationPoints;00:01t;`station_id]
points_map:0N -3 -2 -1 0 1 2 3f!`none`take3`take2`take1`none`return1`return2`return3

getgoogleurl:{[lat0;lon0;lat1;lon1] "https://maps.googleapis.com/maps/api/directions/json?origin=",string[lat0],",",string[lon0],"&destination=",string[lat1],",",string[lon1],"&mode=walking&units=miles&key=",getenv[`googleapikey]}
getgoogleuiurl:{[lat0;lon0;lat1;lon1] "https://www.google.com/maps/dir/?api=1&origin=",string[lat0],",",string[lon0],"&destination=",string[lat1],",",string[lon1],"&travelmode=walking"}
getgoogleuiurltotal:{[start;end;lat0;lon0;lat1;lon1] "https://www.google.com/maps/dir/?api=1&origin=",string[start 0],",",string[start 1],"&waypoints=",string[lat0],",",string[lon0],"|",string[lat1],",",string[lon1],"&destination=",string[end 0],",",string[end 1],"&travelmode=bicycling"}
getdistance:{[url] sum raze[.utils.getJsonUrl[url][`routes][`legs][;`distance]]`value}
if[not `gdcache in key `..;
 gdcache:enlist[4#0nf]!enlist 0nf];
googleDistance1:{[lat0;lon0;lat1;lon1] if[not (lat0;lon0;lat1;lon1) in key gdcache;gdcache[(lat0;lon0;lat1;lon1)]:getdistance getgoogleurl[lat0;lon0;lat1;lon1]]; gdcache[(lat0;lon0;lat1;lon1)]}
googleDistance1C:.cache.init[`googleDistance1;24t;()]
googledistance:{[lat0;lon0;lat1;lon1] googleDistance1C .' flip (lat0;lon0;lat1;lon1)}

googleAddress:{ .utils.getJsonUrl["https://maps.googleapis.com/maps/api/geocode/json?address=",ssr[string[first x];" ";"+"]] }
googleAddressC:.cache.init[`googleAddress;24t;()]
googleAddressLocation:{ `name`latitude`longitude!{enlist[x`formatted_address],x[;`geometry;`location]`lat`lng}[googleAddressC[`$x]`results] }

htmltable:{"<table>\n",({"<tr>\n",raze[{"<th>",.utils.safeString[x],"</th>\n"}each cols x],"</tr>\n"}[x],raze {"<tr>\n",raze[{"<td>",.utils.safeString[x],"</td>\n"}each x],"</tr>\n"}each x),"</table>\n"}

parseArg:@[{value .utils.safeString x};;`$]
get_routes:{[start_name;end_name]
  start_name:parseArg[start_name]; end_name:parseArg[end_name];
  $[type[start_name]=-11h;[start:.data.places[start_name]];[start:start_name;start_name:`]];
  $[type[end_name]=-11h;[end:.data.places[end_name]];[end:end_name;end_name:`]];
  station_info:getStationInfoStatusPoints[];
  map:`station_id xkey select station_id,name,lat,lon,num_bikes_available,num_docks_available,points from station_info;
  "add start and end as synthetic stations with no points";
  map,:flip `station_id`name`lat`lon`num_bikes_available`num_docks_available`points!(9998 9999i;("start";"end");start[0],end[0];start[1],end[1];1 0f;0 1f;1 -1f);
  map:update start_dist:.math.hav[start 0;start 1]. (lat;lon),end_dist:.math.hav[end 0;end 1] . (lat;lon) from map;
  stmap:`st0`st1 xkey select st0,st1,distance:.math.hav[lat0;lon0;lat1;lon1],points:?[points0>0;0;?[points1<0;0;abs[points0]+abs[points1]]] from exec ([]st0:station_id;lat0:lat;lon0:lon;points0:points) cross ([]st1:station_id;lat1:lat;lon1:lon;points1:points) from map;
  
  tbl1:select name,points,lat,lon,start_dis:?[name like .data.favorites[start_name];0;.math.hav[start 0;start 1] . (lat;lon)], end_dis:?[name like .data.favorites[end_name];0;.math.hav[end 0;end 1] . (lat;lon)] from station_info;
  tbls:select station1:name,lat1:lat,lon1:lon,points1:points,start_dis from tbl1 where start_dis=(min;start_dis) fby points;
  tble:select station2:name,lat2:lat,lon2:lon,points2:points,end_dis from tbl1 where end_dis=(min;end_dis) fby points;
  tbl2:select from (update points:?[(points1>0) or (points2<0);0;abs[points1]+points2] from tbls cross tble) where (start_dis+end_dis)=(min;start_dis+end_dis) fby points;
  tbl2:select points,
              start_route:getgoogleuiurl[start 0;start 1]'[lat1;lon1],
              start_name:{[name;points] name," (",string[points],")"}'[station1;points1],
              station1,
              end_route:getgoogleuiurl[;;end 0;end 1]'[lat2;lon2],
              end_name:{[name;points] name," (",string[points],")"}'[station2;points2],
              station2,
              / start_distance:googledistance[start 0;start 1;lat1;lon1],
              start_distance:start_dis,
              / end_distance:googledistance[lat2;lon2;end 0;end 1],
              end_distance:end_dis,
              route:getgoogleuiurltotal[start;end]'[lat1;lon1;lat2;lon2] from tbl2;
  `points xdesc update total_distance:start_distance+end_distance from tbl2
 }
get_html_routes:{[start;end]
  select points,
         start:html_link'[start_route;start_name],
         station1,
         end:html_link'[end_route;end_name],
         station2,
         start_distance,
         end_distance,
         route:html_link[;"route"]'[route],
         total_distance from get_routes[start;end]
 }

html_link:{[url;text] "<a href=\"",url,"\">",text,"</a>"}
html_map:{"<iframe src=\"",x,"\" width=\"400\" height=\"300\" frameborder=\"0\" style=\"border:0\" allowfullscreen></iframe>"}

genmail:{[start;end]
  r:get_html_routes[start;end];
  x:htmltable select points,total_distance,start,end,start_distance,end_distance,route from r;
  header:"\"Citibike Angel Routes\nContent-Type: text/html\nMIME-Version: 1.0\nContent-Disposition: inline\n\"";
  html:"<html>\n<head><title>Citibike Angel Routes :: ",(-3!start)," to ",(-3!end),"</title></head>\n<body>\n<p>Citibike Angel Routes :: ",(-3!start)," to ",(-3!end),"</p>\n",x,"</body>\n</html>\n";
  html
 } 

get_json_routes:{[start;end] .j.j get_routes[start;end]}
get_json_places:{[] .j.j ([]name:key .data.places)}
get_json_addresses:{.j.j `name`addresses!(x;flip googleAddressLocation[x])}
\d .log
info:{-1@"INFO ",string[.z.i]," ",string[.z.Z]," :::: ",x;}
\d .

if[`web in key `;
   if[not `initialized in key .web; .web.init[]]]

