const {chromium}=require('playwright');
const views=Object.keys(require('./scenes/views.json'));
(async()=>{const b=await chromium.launch({args:['--use-gl=swiftshader','--enable-unsafe-swiftshader']});
for(const v of (process.argv[2]?process.argv.slice(2):views)){const V=require('./scenes/views.json')[v];
 const p=await b.newPage({viewport:{width:V.w||1500,height:V.h||1050},deviceScaleFactor:1});
 p.on('pageerror',e=>console.log(v,'ERR',e.message));
 await p.goto('http://localhost:8766/render.html?v='+v);await p.waitForFunction(()=>document.title==='done',null,{timeout:60000});
 await p.screenshot({path:'out/'+v+'.png'});await p.close();console.log('ok',v);}
await b.close();})();
