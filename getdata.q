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

getdistance:{[lat0;long0;lat1;long1] .j.k[raze system 0N!"curl -sS 'https://maps.googleapis.com/maps/api/directions/json?origin=",lat0,",",long0,"&destination=",lat1,",",long1,"&mode=walking&units=miles&key=",googleapikey,"'"][`routes][`legs][;`distance][;`value]%1609.34}

/ 
example walking from south end av @ liberty st to 8th av @ 33rd st is 3.226167 miles
getdistance . string value exec first lat,first lon, last lat, last lon from r'[3002 490]


