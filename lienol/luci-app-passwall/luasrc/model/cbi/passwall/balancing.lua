local e = require "nixio.fs"
local e = require "luci.sys"
local net = require"luci.model.network".init()
local uci = require"luci.model.uci".cursor()
local appname = "passwall"

local n = {}
uci:foreach(appname, "nodes", function(e)
    if e.type and e.remarks and e.port and e.address and e.address ~= "127.0.0.1" then
        if e.address:match("[\u4e00-\u9fa5]") and e.address:find("%.") and e.address:sub(#e.address) ~= "." then
            e.remark = "%s：[%s] %s:%s" % {translate(e.type), e.remarks, e.address, e.port}
            n[e[".name"]] = e
        end
    end
end)

local key_table = {}
for key, _ in pairs(n) do table.insert(key_table, key) end
table.sort(key_table)

m = Map(appname)

-- [[ Haproxy Settings ]]--
s = m:section(TypedSection, "global_haproxy", translate("Load Balancing"))
s.anonymous = true

s:append(Template("passwall/haproxy/status"))

---- Multiprocess Enable
o = s:option(Flag, "Multiprocess_enable", translate("Enable MultiProcess"))
o.rmempty = false
o.default = false


---- Balancing1 Enable
o = s:option(Flag, "balancing1_enable", translate("Enable Load Balancing Session one"))
o.rmempty = false
o.default = false


---- Balancing2 Enable
o = s:option(Flag, "balancing2_enable", translate("Enable Load Balancing Session two"))
o.rmempty = false
o.default = false

---- Console Username
o = s:option(Value, "console_user", translate("Console Username"))
o.default = "admin"
o:depends("balancing1_enable", 1)

---- Console Password
o = s:option(Value, "console_password", translate("Console Password"))
o.password = true
o.default = "admin"
o:depends("balancing1_enable", 1)

---- Console Port
o = s:option(Value, "console_port", translate("Console Port"), translate(
                 "In the browser input routing IP plus port access, such as:192.168.1.1:1188"))
o.default = "1188"
o:depends("balancing1_enable", 1)

---- Haproxy Port1
o = s:option(Value, "haproxy_port1", translate("Haproxy Port Session 1"),
             translate("Configure this node with 127.0.0.1: this port"))
o.default = "1181"
o:depends("balancing1_enable", 1)

---- Haproxy Port2
o = s:option(Value, "haproxy_port2", translate("Haproxy Port Session 2"),
             translate("Configure this node with 127.0.0.1: this port"))
o.default = "1182"
o:depends("balancing2_enable", 1)

-- [[ Balancing Settings Session 1]]--
s = m:section(TypedSection, "balancingsession1", translate("Load Balancing Setting"),
              translate(
                  "Add a node, Export Of Multi WAN Only support Multi Wan. Load specific gravity range 1-256. Multiple primary servers can be load balanced, standby will only be enabled when the primary server is offline!"))
s.template = "cbi/tblsection"
s.sortable = true
s.anonymous = true
s.addremove = true

---- Enable1
o = s:option(Flag, "enabled1", translate("Enable"))
o.default = 1
o.rmempty = false

---- Node Address1
o = s:option(Value, "lbss1", translate("Node Address"))
for _, key in pairs(key_table) do
    o:value(n[key].address .. ":" .. n[key].port, n[key].remark)
end
o.rmempty = false

---- Node Port1
o = s:option(Value, "lbort1", translate("Node Port"))
o:value("default", translate("Default"))
o.default = "default"
o.rmempty = false

---- Node Weight1
o = s:option(Value, "lbweight1", translate("Node Weight"))
o.default = "5"
o.rmempty = false

---- Export1
o = s:option(ListValue, "export1", translate("Export Of Multi WAN"))
o:value(0, translate("Auto"))
local ifaces = e.net:devices()
for _, iface in ipairs(ifaces) do
    if (iface:match("^br") or iface:match("^eth*") or iface:match("^pppoe*")) then
        local nets = net:get_interface(iface)
        nets = nets and nets:get_networks() or {}
        for k, v in pairs(nets) do nets[k] = nets[k].sid end
        nets = table.concat(nets, ",")
        o:value(iface, ((#nets > 0) and "%s (%s)" % {iface, nets} or iface))
    end
end
o.default = 0
o.rmempty = false

---- Mode1
o = s:option(ListValue, "backup", translate("Mode"))
o:value(0, translate("Primary"))
o:value(1, translate("Standby"))
o.rmempty = false

-- [[ Balancing Settings Session 2 ]]--
s = m:section(TypedSection, "balancingsession2", translate("Load Balancing Setting"),
              translate(
                  "Add a node, Export Of Multi WAN Only support Multi Wan. Load specific gravity range 1-256. Multiple primary servers can be load balanced, standby will only be enabled when the primary server is offline!"))
s.template = "cbi/tblsection"
s.sortable = true
s.anonymous = true
s.addremove = true

---- Enable2
o = s:option(Flag, "enabled2", translate("Enable"))
o.default = 0
o.rmempty = false

---- Node Address2
o = s:option(Value, "lbss2", translate("Node Address"))
for _, key in pairs(key_table) do
    o:value(n[key].address .. ":" .. n[key].port, n[key].remark)
end
o.rmempty = false

---- Node Port2
o = s:option(Value, "lbort2", translate("Node Port"))
o:value("default", translate("Default"))
o.default = "default"
o.rmempty = false

---- Node Weight2
o = s:option(Value, "lbweight2", translate("Node Weight"))
o.default = "5"
o.rmempty = false

---- Export2
o = s:option(ListValue, "export2", translate("Export Of Multi WAN"))
o:value(0, translate("Auto"))
local ifaces = e.net:devices()
for _, iface in ipairs(ifaces) do
    if (iface:match("^br") or iface:match("^eth*") or iface:match("^pppoe*")) then
        local nets = net:get_interface(iface)
        nets = nets and nets:get_networks() or {}
        for k, v in pairs(nets) do nets[k] = nets[k].sid end
        nets = table.concat(nets, ",")
        o:value(iface, ((#nets > 0) and "%s (%s)" % {iface, nets} or iface))
    end
end
o.default = 0
o.rmempty = false

---- Mode2
o = s:option(ListValue, "backup2", translate("Mode"))
o:value(0, translate("Primary"))
o:value(1, translate("Standby"))
o.rmempty = false

return m
