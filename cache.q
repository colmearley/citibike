\l wrap.q
\d .cache
store:enlist[`]!enlist[(::)]
store.meta:enlist[`]!enlist[(::)]
store.data:enlist[`]!enlist[(::)]

create:{[name;function;expiry;cacheKeys]
   if[name in key store.meta; '"cache alread exists for '",string[name],"'"];
   store.data[name]:flip[(value[function]1)!()]!();
   store.meta[name]:`expiry`miss`cacheKeys`funcTime`persistTime`persist0Time!(expiry;function;(),cacheKeys;0Nn;0Nn;0Nn);
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
  d:`date$ts:.z.p;
  row:enlist r:`timestamp`init`name`params`val`expiration!(ts;ts;name;box params;box record`val;record`expiration);
  idx:$[`cache_db in key `.;exec first i from select i from get[`..cache_db] where date=d,name=r[`name],params~\:r[`params],i=max i,val~\:r[`val];0N];
  $[not null idx; [ / upsert
                   -1@"INFO ",string[.z.p]," :: upserting to cache_db :: name:'",string[name],"'";
                   {[tpath;idx;colName;data] @[` sv tpath,colName;(),idx;:;data]}[.Q.par[`:.;d;`cache_db];idx]'[`timestamp`expiration;row`timestamp`expiration]
                  ];
                  [ / append
                   -1@"INFO ",string[.z.p]," :: appending to cache_db :: name:'",string[name],"'";
                   saveTable[`:.;d;`cache_db;,;row];
                  ]
   ];
  reloadDB[];
 }

persist0:{[name;params;record]
  d:`date$ts:.z.p;
  m:store.meta[name];
  dbName:`$string[name],"_db";
  if[()~ck:m`cacheKeys;:()];
  val:() xkey record`val;
  rows:enlist[`timestamp`init`params`expiration!(ts;ts;box params;record`expiration)] cross (ck#val),'([]val:box each val);
  if[not dbName in key `.; saveTable[`:.;d;dbName;:;rows]; reloadDB[]; :()];
  unchanged:?[get (` sv `.,dbName);parse each ("date=",string[d];"params in rows`params";ckt," in ck#rows";"i=(max;i) fby ",ckt:"([]",sv[";";string  ck],")";"val in rows`val");0b;{x!x}`i,ck];
  if[count unchanged;
    -1@"INFO ",string[.z.p]," :: upserting to '",string[name],"' count:'",string[count unchanged],"'";
    {[tpath;i;colName;data] @[` sv tpath,colName;i;:;data]}[.Q.par[`:.;d;dbName];unchanged`i]'[`timestamp`expiration;rows[unchanged`i]`timestamp`expiration]];
  new:?[rows;enlist parse "not ",ckt,"in ck#unchanged";0b;()];
  if[count new;
    -1@"INFO ",string[.z.p]," :: appending to '",string[name],"' count:'",string[count new],"'";
    saveTable[`:.;d;dbName;,;new]];
  reloadDB[];
 }

saveTable:{[db;dte;tableName;method;table]
  tpath:` sv .Q.par[db;dte;tableName],`; table:.Q.en[db]table;
  $[count genCols:where 0h=type each flip table;
           [tdpath:` sv tpath,`.d;
            if[0h<type key tpath; tdpath set get[tdpath] except genCols]; / remove params and val from .d if tpath exists
            .[tpath;();method;![table;();0b;genCols]]; / append new data to regular columns
            {[tpath;method;colName;data] .[` sv tpath,colName;();method;data]}[tpath;method]'[genCols;table[genCols]]; / append new data for list columns
            tdpath set get[tdpath] union genCols;
           ];
           .[tpath;();method;table]
   ];
 }

refresh_db:{
  if[not `cache_db in key `.;:()];
  exec {.[`$string[x],"C";y]}'[name;params] from (select last expiration by name,params from get[`..cache_db] where date>=.z.d-1) where .z.p>expiration
 }

miss:{[name;params]
  m:store.meta[name];
  st:.z.p; store.data[name;params]:record:`val`expiration!(.[m`miss;$[1~.wrap.getArity[m`miss];enlist;(::)]params];.z.p+m`expiry); funcTime:.z.p-st;
  st:.z.p; persist[name;params;record]; persistTime:.z.p-st;
  st:.z.p; persist0[name;params;record]; persist0Time:.z.p-st;
  store.meta[name;`funcTime`persistTime`persist0Time]:(funcTime;persistTime;persist0Time);
  record
 }

.cache.absoluteName:{[name] $[1~count ` vs name;` sv `.,name;name]}
.cache.init:{[name;expiry;cacheKeys]
  function:value .cache.absoluteName name;
  .cache.create[name;function;expiry;cacheKeys];
  .wrap.wrap[.cache.lookup;name]
 }

.cache.reloadDB:{
  system"l .";
  .Q.chk[`:.];
 }

\d .
.cron.add[".cache.refresh_db[]";0p;0D00:00:01];
system"l db"
