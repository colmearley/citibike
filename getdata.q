\l qml.q

curl_raw:{.j.k first system"curl -sS ",x}
curl:{curl_raw[x]`data}

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

getdistance:{[lat0;long0;lat1;long1] .j.k[raze system 0N!"curl -sS 'https://maps.googleapis.com/maps/api/directions/json?origin=",lat0,",",long0,"&destination=",lat1,",",long1,"&mode=walking&units=miles&key=",googleapikey,"'"][`routes][`legs][;`distance][;`value]}

hav:{[lat1;lon1;lat2;lon2]
  deg2rad:{x*(22%7)%180};
  R:6371000; dLat:deg2rad[lat2-lat1]; dLon:deg2rad[lon2-lon1];
  a:xexp[sin[dLat%2];2] + cos[deg2rad[lat1]] * cos[deg2rad[lat2]] * xexp[sin[dLon%2];2];
  c:2 * .qml.atan2[sqrt[a];sqrt[1-a]];
  d:R*c;
  d
 }

places:enlist[`]!enlist[2#0nf]
places[`work]:40.7526 -73.9902
places[`home]:40.7092 -74.0133

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

