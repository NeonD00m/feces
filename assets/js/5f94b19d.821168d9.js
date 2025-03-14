"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[845],{7060:(e,n,o)=>{o.r(n),o.d(n,{assets:()=>i,contentTitle:()=>a,default:()=>h,frontMatter:()=>s,metadata:()=>t,toc:()=>c});const t=JSON.parse('{"id":"hooks","title":"Hooks","description":"Hooks allow you to add features tied to the replication process.","source":"@site/docs/hooks.md","sourceDirName":".","slug":"/hooks","permalink":"/feces/docs/hooks","draft":false,"unlisted":false,"editUrl":"https://github.com/NeonD00m/feces/edit/main/docs/hooks.md","tags":[],"version":"current","sidebarPosition":4,"frontMatter":{"sidebar_position":4},"sidebar":"defaultSidebar","previous":{"title":"Advanced Setup","permalink":"/feces/docs/advanced-setup"}}');var d=o(4848),r=o(8453);const s={sidebar_position:4},a="Hooks",i={},c=[{value:"<code>added()</code>",id:"added",level:2},{value:"<code>changed()</code>",id:"changed",level:2},{value:"<code>removed()</code>",id:"removed",level:2},{value:"<code>deleted()</code>",id:"deleted",level:2}];function l(e){const n={a:"a",admonition:"admonition",code:"code",em:"em",h1:"h1",h2:"h2",header:"header",p:"p",pre:"pre",strong:"strong",...(0,r.R)(),...e.components};return(0,d.jsxs)(d.Fragment,{children:[(0,d.jsx)(n.header,{children:(0,d.jsx)(n.h1,{id:"hooks",children:"Hooks"})}),"\n",(0,d.jsx)(n.p,{children:"Hooks allow you to add features tied to the replication process."}),"\n",(0,d.jsxs)(n.admonition,{type:"warning",children:[(0,d.jsx)(n.p,{children:"With any of the hook methods:\r\nOnly one callback can be set at a time and calling again will overwrite the previous callback."}),(0,d.jsx)(n.p,{children:"If you'd like a signal or some sort of scheduler please set that up on your own."})]}),"\n",(0,d.jsx)(n.h2,{id:"added",children:(0,d.jsx)(n.a,{href:"/api/feces#added",children:(0,d.jsx)(n.code,{children:"added()"})})}),"\n",(0,d.jsxs)(n.p,{children:["Hooks onto when a new ",(0,d.jsx)(n.strong,{children:"entity"})," is replicated to the world, not for new components.\r\nThe added callback is called ",(0,d.jsx)(n.em,{children:"after"})," all the components received are set to\r\na newly replicated entity. This is because there has to be at least one replicating\r\ncomponent under an entity for it to be added through feces."]}),"\n",(0,d.jsx)(n.admonition,{type:"warning",children:(0,d.jsxs)(n.p,{children:["This added hook will be called on entities ",(0,d.jsx)(n.em,{children:"after"})," calling changed hooks on each of their components, so do not expect changed to happen after added."]})}),"\n",(0,d.jsx)(n.pre,{children:(0,d.jsx)(n.code,{className:"language-lua",children:'feces.added(function(entity)\r\n    if world:has(entity, PlayerTag) then\r\n        print("new player added", entity)\r\n        return\r\n    end\r\n    print("entity added", entity)\r\nend)\n'})}),"\n",(0,d.jsx)(n.h2,{id:"changed",children:(0,d.jsx)(n.a,{href:"/api/feces#changed",children:(0,d.jsx)(n.code,{children:"changed()"})})}),"\n",(0,d.jsxs)(n.p,{children:["Hooks onto when a ",(0,d.jsx)(n.strong,{children:"component"})," value is changed in the world. Called ",(0,d.jsx)(n.em,{children:"before"})," the component's new value is set in the world. This means that you can get whether the entity has the component or not, and the previous value of the component."]}),"\n",(0,d.jsxs)(n.p,{children:["This also allows you to check for values being set to ",(0,d.jsx)(n.code,{children:"nil"})," and compare previous and current values."]}),"\n",(0,d.jsx)(n.pre,{children:(0,d.jsx)(n.code,{className:"language-lua",children:'feces.changed(function(entity, component, value)\r\n    local had = world:has(entity, component)\r\n    if not had then\r\n        print("component added", component)\r\n        return\r\n    end\r\n    local previous = world:get(entity, component)\r\n    print("component changed", component, previous, "->", value)\r\nend)\n'})}),"\n",(0,d.jsx)(n.h2,{id:"removed",children:(0,d.jsx)(n.a,{href:"/api/feces#removed",children:(0,d.jsx)(n.code,{children:"removed()"})})}),"\n",(0,d.jsxs)(n.p,{children:["Hooks onto when a ",(0,d.jsx)(n.strong,{children:"component"})," is removed from the world. Called ",(0,d.jsx)(n.em,{children:"before"})," removing the component from the world. This means that you can get the previous value of the component."]}),"\n",(0,d.jsx)(n.pre,{children:(0,d.jsx)(n.code,{className:"language-lua",children:'feces.removed(function(entity, component)\r\n    local previous = world:get(entity, component)\r\n    print("component removed", component, "had the value of", previous)\r\nend)\n'})}),"\n",(0,d.jsx)(n.h2,{id:"deleted",children:(0,d.jsx)(n.a,{href:"/api/feces#deleted",children:(0,d.jsx)(n.code,{children:"deleted()"})})}),"\n",(0,d.jsxs)(n.p,{children:["Hooks onto when an ",(0,d.jsx)(n.strong,{children:"entity"})," is deleted in the world. This is called ",(0,d.jsx)(n.em,{children:"before"})," the entity is deleted, allowing you to get the component values and clean up, fairly straightforward."]}),"\n",(0,d.jsx)(n.pre,{children:(0,d.jsx)(n.code,{className:"language-lua",children:'feces.deleted(function(entity)\r\n    if world:has(entity, PlayerTag) then\r\n        print("player has left the game", entity)\r\n        return\r\n    end\r\n    print("entity deleted", entity)\r\nend)\n'})})]})}function h(e={}){const{wrapper:n}={...(0,r.R)(),...e.components};return n?(0,d.jsx)(n,{...e,children:(0,d.jsx)(l,{...e})}):l(e)}},8453:(e,n,o)=>{o.d(n,{R:()=>s,x:()=>a});var t=o(6540);const d={},r=t.createContext(d);function s(e){const n=t.useContext(r);return t.useMemo((function(){return"function"==typeof e?e(n):{...n,...e}}),[n,e])}function a(e){let n;return n=e.disableParentContext?"function"==typeof e.components?e.components(d):e.components||d:s(e.components),t.createElement(r.Provider,{value:n},e.children)}}}]);