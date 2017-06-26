\d .web

init:{
  initialized:1b;
  zph:.z.ph;
  .web.log:([]timestamp:();ip:();hostname:();user:();args:();result:());
  .z.ph:.web.logHandler;
 }

header:{[html] "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: Keep-Alive\r\nContent-Length: ",string[count html],"\r\n\r\n",html}
customHandler:{$[any first[x]~/:(enlist["?"];"");header[index[]];first[x] like "?genmail*";header value .h.uh 1 _ first x;zph x]}
logHandler:{[args]
  idx:`.web.log insert (.z.p;`$"." sv string `int$0x0 vs .z.a;.z.u;.Q.host .z.a;args;());
  result:@[customHandler;args;{"fail: '",(x),"'"}];
  .web.log[idx;`result]:enlist result;
  result
 }

index:{{ssr[x;"#",string y;z[]]}/["\n" sv read0[`:geogen.html];key translate;value translate]}

/ methods for generating js form and buttons for choosing source and destination
makeJsCheckLoc:{[id;name] "if (document.getElementById(\"",.utils.safeString[id],"_",.utils.safeString[name],"\").checked) {\n ",.utils.safeString[id],"_val = document.getElementById(\"",.utils.safeString[id],"_",.utils.safeString[name],"\").value;\n}\n"}
makeJsCheckLocs:{[id] "\n" sv makeJsCheckLoc[id] each key .data.places}
makeLocationButton:{[id;name;attributes] "<input type=\"radio\" display=\"inline\" name=\"",.utils.safeString[id],"\" id=\"",.utils.safeString[id],"_",{ssr[lower x;" ";"_"]}[.utils.safeString[name]],"\" value=\"",.utils.safeString[name],"\" ",(" " sv {string[x],"=\"",.utils.safeString[y],"\""}'[key attributes;value attributes]),"><label for=\"",.utils.safeString[id],"_",{ssr[lower x;" ";"_"]}[.utils.safeString[name]],"\">",{@[x;where 1b,1_prev " "=x;upper]}[.utils.safeString[name]],"</label>"}
makeLocationButtons:{[id] "\n" sv makeLocationButton[id;;()!()]each key .data.places}
makeLocationForm:{[id] "<form name=\"",.utils.safeString[id],"s\" id=\"form_",.utils.safeString[id],"\" display=\"inline\" action=\"\">\n",makeLocationButtons[id],"\n",makeLocationButton[id;"current location";enlist[`onclick]!enlist["getCurrentLocation()"]],"\n</form>"}

/ methods for translating html tags
translate:(`symbol$())!()
translate[`js_get_routes_src]:{makeJsCheckLoc[`source;"current_location"],makeJsCheckLocs[`source]}
translate[`js_get_routes_dest]:{makeJsCheckLoc[`dest;"current_location"],makeJsCheckLocs[`dest]}
translate[`form_src]:{makeLocationForm[`source]}
translate[`form_dest]:{makeLocationForm[`dest]}
translate[`host]:{string[.z.h]}
translate[`port]:{string system"p"}


