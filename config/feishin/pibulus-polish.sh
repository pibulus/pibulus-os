#!/bin/sh
set -eu

index=/usr/share/nginx/html/index.html
marker="data-pibulus-polish"

if [ -f "$index" ] && [ -w "$index" ] && ! grep -q "$marker" "$index"; then
  tmp="$(mktemp /tmp/feishin-index.XXXXXX)"
  awk '
    { print }
    /<script src="settings.js"><\/script>/ {
      print "        <script data-pibulus-polish>"
      print "        (function(){"
      print "          try{localStorage.setItem(\"version\", JSON.stringify(\"1.11.0\"));}catch(e){}"
      print "          var css = ["
      print "            \".fs-full-screen-player-queue-module-grid-container:before{background:#0000000d;border-radius:3rem;backdrop-filter:blur(60px);}\","
      print "            \".fs-full-screen-player-image-module-image{border-radius:3rem;filter:none!important;}\","
      print "            \".fs-badge-module-root{background-color:#ffffff1c!important;}\","
      print "            \".fs-playerbar-module-controls-grid{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr) minmax(0,1fr);gap:1rem;height:100%;backdrop-filter:blur(40px);background-color:#0000001c;}\","
      print "            \"[data-mantine-color-scheme=dark] .fs-button-module-root[data-variant=subtle]:hover,[data-mantine-color-scheme=dark] .fs-button-module-root[data-variant=subtle]:active,[data-mantine-color-scheme=dark] .fs-button-module-root[data-variant=subtle]:focus-visible{background-color:#00000025;}\","
      print "            \".fs-button-module-root[data-variant=subtle]{border-radius:1rem;}\","
      print "            \".fs-full-screen-player-queue-module-grid-container{padding:1.5rem 3rem;}\","
      print "            \".fs-synchronized-lyrics-module-container,.fs-lyric-line-module-lyric-line.active{text-shadow:0 0 4px #fffffffa;filter:none!important;}\","
      print "            \".fs-lyric-line-module-lyric-line.synchronized{filter:blur(2px);}\","
      print "            \"@media (pointer:coarse),(max-width:700px){.fs-playerbar-module-controls-grid{gap:.5rem}.fs-playerbar-module-controls-grid .fs-button-module-root,.fs-full-screen-player-module-container .fs-button-module-root,.fs-item-card-controls-module-container .fs-button-module-root{min-width:44px;min-height:44px}.fs-full-screen-player-queue-module-grid-container{padding:1rem}}\""
      print "            ,\"@media (max-width:700px){form .mantine-Group-root[data-grow=true]{flex-direction:column;align-items:stretch}form .mantine-Group-root[data-grow=true]>*{flex:1 1 100%!important;width:100%!important;max-width:100%!important}form .mantine-Group-root[data-grow=true] .fs-text-input-module-root{width:100%!important}}\""
      print "          ].join(\"\\n\");"
      print "          var style=document.createElement(\"style\");style.setAttribute(\"data-pibulus-polish-css\",\"\");style.textContent=css;document.head.appendChild(style);"
      print "          function setValue(el,value){if(!el||el.value===value)return;var proto=Object.getPrototypeOf(el);var desc=Object.getOwnPropertyDescriptor(proto,\"value\");if(desc&&desc.set){desc.set.call(el,value)}else{el.value=value}el.dispatchEvent(new Event(\"input\",{bubbles:true}));el.dispatchEvent(new Event(\"change\",{bubbles:true}));}"
      print "          function hideField(label){var root=label.closest(\".fs-text-input-module-root\");if(root)root.style.display=\"none\";}"
      print "          function hideProtocolPicker(label){var n=label;for(var i=0;i<6&&n;i++,n=n.parentElement){var t=n.innerText||\"\";if(t.indexOf(\"Jellyfin\")>-1&&t.indexOf(\"Navidrome\")>-1&&t.indexOf(\"OpenSubsonic\")>-1){n.style.display=\"none\";return;}}}"
      print "          function simplifyCopy(){var walker=document.createTreeWalker(document.body||document.documentElement,NodeFilter.SHOW_TEXT);var node;while((node=walker.nextNode())){if((node.nodeValue||\"\").trim().toLowerCase()===\"server required\"){node.nodeValue=node.nodeValue.replace(/server required/i,\"sign in\");}}}"
      print "          function fillServerForm(){simplifyCopy();document.querySelectorAll(\"label\").forEach(function(label){var text=(label.textContent||\"\").trim();var input=label.htmlFor&&document.getElementById(label.htmlFor);if(/^(Jellyfin|Navidrome|OpenSubsonic)$/.test(text)){hideProtocolPicker(label)}if(/^Server Name/.test(text)){setValue(input,\"Quick Cat Club Music\");hideField(label)}if(/^Url \\*/.test(text)){setValue(input,\"http://pibulus.local:4533\");hideField(label)}if(/^Public Url/.test(text)){hideField(label)}});}"
      print "          var timer=setInterval(fillServerForm,500);var observer=new MutationObserver(fillServerForm);observer.observe(document.documentElement,{childList:true,subtree:true});document.addEventListener(\"DOMContentLoaded\",fillServerForm);setTimeout(function(){clearInterval(timer);observer.disconnect();},15000);fillServerForm();"
      print "        })();"
      print "        </script>"
    }
  ' "$index" > "$tmp"
  cat "$tmp" > "$index"
  rm -f "$tmp"
fi
