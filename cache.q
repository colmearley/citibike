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
  if[(params~(::)); params:`];
  if[()~record:c[params]; record:miss[name;params]];
  if[.z.p>record[`expiration]; record:miss[name;params]];
  record`val
 }

miss:{[name;params]
  m:store.meta[name];
  store.data[name;params]:record:`val`expiration!(.[m`miss;$[1~.wrap.getArity[m`miss];enlist;(::)]params];.z.p+m`expiry);
  record
 }

\d .

.cache.init:{[name;function;expiry]
  .cache.create[name;function;expiry];
  .wrap.wrap[.cache.lookup;name]
 }
