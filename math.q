\d .math

atan2:{[y;x] u:atan[y%x]; ?[x<0.0;?[u>=0.0;u-22%7;u+22%7];u]}

/ haversine formula for spherical distance
hav:{[lat1;lon1;lat2;lon2]
  deg2rad:{x*(22%7)%180};
  R:6371000; dLat:deg2rad[lat2-lat1]; dLon:deg2rad[lon2-lon1];
  a:xexp[sin[dLat%2];2] + cos[deg2rad[lat1]] * cos[deg2rad[lat2]] * xexp[sin[dLon%2];2];
  c:2 * atan2[sqrt[a];sqrt[1-a]];
  d:R*c;
  d
 }

/ Manhattan Distance
/ Todo: Adjust for Manhattan street tilt angle of 29 degrees
manhattan_distance:{[lat1;lon1;lat2;lon2]  .math.hav[lat1;lon1;lat2;lon1]+.math.hav[lat1;lon1;lat1;lon2]}

/ Returns box boundary co-ordinates of a point in metres
/ Todo: Adjust for Manhattan street tilt angle of 29 degrees
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
