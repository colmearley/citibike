\d .web

init:{
  initialized:1b;
  zph::.z.ph;
  .web.log:([]timestamp:();ip:();hostname:();user:();args:();result:());
  .z.ph:.web.logHandler;
  .h.HOME:"../html";
 }

header:{[contentType;content] "HTTP/1.1 200 OK\r\nContent-Type: ",contentType,"\r\nConnection: Keep-Alive\r\nContent-Length: ",string[count content],"\r\n\r\n",content}
customHandler:{$[any first[x]~/:(enlist["?"];"");   header["text/html"] "\n" sv read0 ` sv hsym[`..],`geogen.html;
                 first[x] like "?get_json_routes*"; header["application/json"] value .h.uh 1_ first[x];
                 first[x] like "?get_json_places*"; header["application/json"] value .h.uh 1_ first[x];
                 first[x] like "*.css"; .web.zph x;
                 .h.hn["404 Not Found";`txt] .h.uh first x]}

logHandler:{[args]
  idx:`.web.log insert (.z.p;`$"." sv string `int$0x0 vs .z.a;.z.u;.Q.host .z.a;args;());
  result:@[customHandler;args;{"fail: '",(x),"'"}];
  .web.log[idx;`result]:enlist result;
  result
 }
