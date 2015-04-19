if node["kernel"]["cs_info"]["model"] == "VirtualBox"
  interfaces = node["network"]["interfaces"]
  ik = interfaces.keys
  node.automatic["ipaddress"] = interfaces[ik.last]["configuration"]["ip_address"][0]
end
