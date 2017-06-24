\d .wrap

getArity:{[f]
  last $[100h~t:type f;count value[f]1;
                 104h~t; .z.s each value f;
                         '"type"]
 }

wrapfunc:(`int$())!()
wrapfunc[0]:{[wrapper;func]   {[wrapped;x]             .[wrapped;enlist (x)            ]}[wrapper[func]]}
wrapfunc[1]:{[wrapper;func]   {[wrapped;a]             .[wrapped;enlist (a)            ]}[wrapper[func]]}
wrapfunc[2]:{[wrapper;func]   {[wrapped;a;b]           .[wrapped;enlist (a;b)          ]}[wrapper[func]]}
wrapfunc[3]:{[wrapper;func]   {[wrapped;a;b;c]         .[wrapped;enlist (a;b;c)        ]}[wrapper[func]]}
wrapfunc[4]:{[wrapper;func]   {[wrapped;a;b;c;d]       .[wrapped;enlist (a;b;c;d)      ]}[wrapper[func]]}
wrapfunc[5]:{[wrapper;func]   {[wrapped;a;b;c;d;e]     .[wrapped;enlist (a;b;c;d;e)    ]}[wrapper[func]]}
wrapfunc[6]:{[wrapper;func]   {[wrapped;a;b;c;d;e;f]   .[wrapped;enlist (a;b;c;d;e;f)  ]}[wrapper[func]]}
wrapfunc[7]:{[wrapper;func]   {[wrapped;a;b;c;d;e;f;g] .[wrapped;enlist (a;b;c;d;e;f;g)]}[wrapper[func]]}
/ wrapfunc[8]:{[wrapper;func] {[wrapped;a;b;c;d;e;f;g;h] .[wrapped;enlist (a;b;c;d;e;f;g;h)]}[wrapper[func]]}

wrap:{[wrapper;func]
  code:$[-11h~type[func];get $[1~count ` vs func;` sv `.,func;func];func];
  if[not (arity:getArity[code]) in key wrapfunc;'"cannot wrap functions with an arity of '",string[arity],"'"];
  wrapfunc[arity][wrapper;func]
 }

\d .
