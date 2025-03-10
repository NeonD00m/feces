"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[214],{3341:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>a,contentTitle:()=>c,default:()=>p,frontMatter:()=>i,metadata:()=>r,toc:()=>d});const r=JSON.parse('{"id":"setup","title":"Setup","description":"Simple","source":"@site/docs/setup.md","sourceDirName":".","slug":"/setup","permalink":"/feces/docs/setup","draft":false,"unlisted":false,"editUrl":"https://github.com/NeonD00m/feces/edit/main/docs/setup.md","tags":[],"version":"current","sidebarPosition":2,"frontMatter":{"sidebar_position":2},"sidebar":"defaultSidebar","previous":{"title":"Introduction","permalink":"/feces/docs/intro"},"next":{"title":"Advanced Setup","permalink":"/feces/docs/advanced-setup"}}');var s=n(4848),o=n(8453);const i={sidebar_position:2},c="Setup",a={},d=[{value:"Simple",id:"simple",level:2}];function l(e){const t={code:"code",h1:"h1",h2:"h2",header:"header",p:"p",pre:"pre",...(0,o.R)(),...e.components};return(0,s.jsxs)(s.Fragment,{children:[(0,s.jsx)(t.header,{children:(0,s.jsx)(t.h1,{id:"setup",children:"Setup"})}),"\n",(0,s.jsx)(t.h2,{id:"simple",children:"Simple"}),"\n",(0,s.jsx)(t.p,{children:"This option reduces code written and tools needed. In most cases, developers don't need to implement anything more complex than this unless they will be using feces to replicate large amounts of data often."}),"\n",(0,s.jsx)(t.pre,{children:(0,s.jsx)(t.code,{className:"language-lua",children:"if RunService:IsServer() then\r\n\trequestFullPacket.OnServerEvent:Connect(function(player)\r\n\t\tremote:FireClient(player, full())\r\n\tend)\r\nelse\r\n\trequestFullpacket:FireServer()\r\n\tremote.OnClientEvent:Connect(function(data)\r\n\t\tapply(data)\r\n\tend)\r\nend\r\n\r\nlocal function replicate()\r\n\tlocal changes, deleted = delta()\r\n\tif not next(changes) and not next(deleted) then\r\n\t\treturn\r\n\tend\r\n\r\n\tfor player, packet in group(changes, deleted) do\r\n\t\tremote:FireClient(player, packet)\r\n\tend\r\nend\n"})})]})}function p(e={}){const{wrapper:t}={...(0,o.R)(),...e.components};return t?(0,s.jsx)(t,{...e,children:(0,s.jsx)(l,{...e})}):l(e)}},8453:(e,t,n)=>{n.d(t,{R:()=>i,x:()=>c});var r=n(6540);const s={},o=r.createContext(s);function i(e){const t=r.useContext(o);return r.useMemo((function(){return"function"==typeof e?e(t):{...t,...e}}),[t,e])}function c(e){let t;return t=e.disableParentContext?"function"==typeof e.components?e.components(s):e.components||s:i(e.components),r.createElement(o.Provider,{value:t},e.children)}}}]);