\d .utils

safeString:{$[type[x] in 0 98 99h;.z.s each x;type[x]=10h;x;string x]}
getUrl:{[url] .Q.hg[hsym `$.utils.safeString url]}
getJsonUrl:{[url] .j.k raze getUrl[url]}
posixqtime:{`datetime$1970.01.01D+1000000000*`long$x}
