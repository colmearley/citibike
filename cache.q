\l wrap.q
\d .cache
store:enlist[`]!enlist[(::)]
store.meta:enlist[`]!enlist[(::)]
store.data:enlist[`]!enlist[(::)]

create:{[name;function;expiry]
   if[name in key store.meta; '"cache alread exists for '",string[name],"'"];
   store.data[name]:flip[(value[function]1)!()]!();
   store.meta[name]:`expiry`miss!(expiry;function);
  }

lookup:{[name;params]
  if[not name in key store.meta; '"cache not created for '",string[name],"'"];
  c:store.data[name]; m:store.meta[name];
  if[params~(::); params:`];
  if[()~record:c[params]; record:miss[name;params]];
  if[.z.p>record[`expiration]; record:miss[name;params]];
  record`val
 }

box:{$[type[x]~0h;x;.z.s enlist x]}
persist:{[name;params;record]
  .[`:cache_db;();,;([]timestamp:.z.p;init:.z.p;name:name;params:box params;val:box record`val;expiration:record`expiration)];
  system"l cache_db";
  compress_db[];
 }

compress_db:{
  compressed:`timestamp`expiration xasc cols[`..cache_db]#() xkey select timestamp:last timestamp,init:first timestamp,last expiration,first val by name,params,chg:({sums differ x};val) fby ([]name;params) from `timestamp`expiration xasc select from `..cache_db;
  .[`:cache_db;();:;compressed];
  system"l cache_db";
 }

refresh_db:{
  if[not `cache_db in key `.;:()];
  exec {.[`$string[x],"C";y]}'[name;params] from select from `..cache_db where i=(max;i) fby ([]name;params),.z.p>expiration
 }

miss:{[name;params]
  m:store.meta[name];
  store.data[name;params]:record:`val`expiration!(.[m`miss;$[1~.wrap.getArity[m`miss];enlist;(::)]params];.z.p+m`expiry);
  persist[name;params;record];
  record
 }

.cache.absoluteName:{[name] $[1~count ` vs name;` sv `.,name;name]}
.cache.init:{[name;expiry]
  function:value .cache.absoluteName name;
  .cache.create[name;function;expiry];
  .wrap.wrap[.cache.lookup;name]
 }

\d .
.cron.add[".cache.refresh_db[]";0p;0D00:00:01];
