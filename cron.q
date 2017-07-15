\d .cron
crontab:([]id:`long$();function:();start:`timestamp$();interval:`timespan$();time:`timestamp$();enabled:`boolean$())
`crontab insert (0;(::);0Np;0Nn;0Np;0b);

add:{[function;start;interval]
  `.cron.crontab insert (count crontab;function;start;interval;start;1b)
 }

.z.ts:{
  ids:exec id,{$[type[x]~10h;value x;x[]]}'[function] from .cron.crontab where enabled,.z.p>=time;
  .cron.crontab[ids`id;`time]+:.cron.crontab[ids`id;`interval];
 }

\t 1
