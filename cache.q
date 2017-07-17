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
  row:.Q.en[`:.]enlist r:`timestamp`init`name`params`val`expiration!(.z.p;.z.p;name;box params;box record`val;record`expiration);
  idx:exec first i from select i from `..cache_db where name=r[`name],params~\:r[`params],i=max i,val~\:r[`val];
  $[not null idx; [ / upsert 
                   -1@"INFO ",string[.z.p]," :: upserting to cache_db :: name:'",string[name],"'";
                   @[`:cache_db/timestamp;(),idx;:;row`timestamp];
                   @[`:cache_db/expiration;(),idx;:;row`expiration]
                  ];
                  [ / append
                   -1@"INFO ",string[.z.p]," :: appending to cache_db :: name:'",string[name],"'"; 
                   / remove params and val from .d
                   `:cache_db/.d set get[`:cache_db/.d] except `params`val;
                   / append new data to regular columns
                   .[`:cache_db/;();,;delete params,val from row];
                   / append new data to params and val
                   .[`:cache_db/params;();,;row`params];
                   .[`:cache_db/val;();,;row`val];
                   / add params and val to .d
                   `:cache_db/.d set get[`:cache_db/.d],`params`val
                  ]
   ];
  system"l .";
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
system"l db"
