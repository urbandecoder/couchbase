# linux
if node["virtualization"] && node["virtualization"]["system"] == "vbox"
  interface = node["network"]["interfaces"].select {|key| puts key;key == "eth1"}
  unless interface.empty?
    interface["eth1"]["addresses"].each do |ip, params|
      if params['family'] == ('inet')
        node.automatic["ipaddress"] = ip
      end
    end
  end
# windows
elsif node["kernel"] && node["kernel"]["cs_info"] && node["kernel"]["cs_info"]["model"] == "VirtualBox"
  interfaces = node["network"]["interfaces"]
  interface_key = interfaces.keys.last
  node.automatic["ipaddress"] = interfaces[interface_key]["configuration"]["ip_address"][0]
end
