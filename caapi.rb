# //////////////////////////////////////////////////
# /////
# //
# // clean access api calls, etc...
# //
# /////
# //////////////////////////////////////////////////


require 'rubygems'
require 'curb'
require 'hpricot'




# //////////////////////////////////////////////////
# /////
# //
# // massage api error/count/found results
# //

def error_chk(c)

  $oobcount = nil
  $ooberror = nil
  $oobfound = nil

  oobuserinfo = c.body_str.gsub(/<!--/, '')
  oobuserinfo = oobuserinfo.gsub(/-->/, '')
  oobuserinfo = oobuserinfo.gsub(/,/, "\r\n")
  oobuserinfo = oobuserinfo.split(/\n/)

  count = Regexp.new(/count=\d+/)
  count = count.match(oobuserinfo[1])
  count = count.to_s
  count = count.split(/count=/)
  $oobcount = count[1]

  error = Regexp.new(/error=\d+/)
  error = error.match(oobuserinfo[0])
  error = error.to_s
  error = error.split(/error=/)
  $ooberror = error[1]
 
  found = Regexp.new(/found=\w+/)
  found = found.match(oobuserinfo[1])
  found = found.to_s
  found = found.split(/found=/)
  $oobfound = found[1]
 
end

# //
# /////
# //////////////////////////////////////////////////








# //////////////////////////////////////////////////
# /////
# //
# // where the magic happens
# //

def regmac(mac,desc)

 puts "mac in function"
 puts mac

 c = Curl::Easy.new("https://#{CONFIG['setup']['api']['url']}/admin/cisco_api.jsp") do |curl|
 curl.headers["User-Agent"] = "CA API"
 curl.http_post("https://#{CONFIG['setup']['api']['url']}/admin/cisco_api.jsp",
                             Curl::PostField.content('admin', CONFIG['setup']['api']['user']),
                             Curl::PostField.content('passwd', CONFIG['setup']['api']['password']),
                             Curl::PostField.content('op', 'addmac'),
                             Curl::PostField.content('type', 'userole'),
                             Curl::PostField.content('mac', mac),
                             Curl::PostField.content('role', CONFIG['setup']['api']['role']),
                             Curl::PostField.content('desc', desc))
 end
 
 # /////
 # //
 # // i'm assuming i have enough prior error checking to just register the device
 # //
 c.perform

 # ///// puts c.body_str

end

# //
# /////
# //////////////////////////////////////////////////








# //////////////////////////////////////////////////
# /////
# //
# // check api to see if device has previously registered
# //

def checkmac(mac)

 c = Curl::Easy.new("https://#{CONFIG['setup']['api']['url']}/admin/cisco_api.jsp") do |curl|
 curl.headers["User-Agent"] = "CA API"
 curl.http_post("https://#{CONFIG['setup']['api']['url']}/admin/cisco_api.jsp",
                            Curl::PostField.content('admin', CONFIG['setup']['api']['user']),
                            Curl::PostField.content('passwd', CONFIG['setup']['api']['password']),
                            Curl::PostField.content('op', 'checkmac'),
                            Curl::PostField.content('mac', mac))
 end

 c.perform
 
 # ///// puts c.body_str
 
 # /////
 # //
 # // check api for errors or null results
 # //
 error_chk(c)

 # ///// puts "-======================-"
 # ///// puts "error check for checkmac"
 # ///// puts "ooberror"
 # ///// puts $ooberror
 # ///// puts "oobfound"
 # ///// puts $oobfound
 # ///// puts "registered"
 # ///// puts $registered

 if $ooberror == "0" && $oobfound == "true"
  $registered = "yes"  
 else 
  $registered = "no"
 end

 # ///// puts "registered"
 # ///// puts $registered
 # ///// puts "-======================-"

end

# //
# /////
# //////////////////////////////////////////////////








# //////////////////////////////////////////////////
# /////
# //
# // query api to see if device is logged in
# //  if they are logged in they really shouldn't
# //   need to register
# //

def checkoobmac(mac)

 c = Curl::Easy.new("https://#{CONFIG['setup']['api']['url']}/admin/cisco_api.jsp") do |curl|
 curl.headers["User-Agent"] = "CA API"
 curl.http_post("https://#{CONFIG['setup']['api']['url']}/admin/cisco_api.jsp",
                            Curl::PostField.content('admin', CONFIG['setup']['api']['user']),
                            Curl::PostField.content('passwd', CONFIG['setup']['api']['password']),
                            Curl::PostField.content('op', 'getoobuserinfo'),
                            Curl::PostField.content('qtype', 'mac'),
                            Curl::PostField.content('qval', mac))
 end
 
 # // curl.http_post("https://#{CONFIG['setup']['api']['url']}/admin/cisco_api.jsp",
 # //                            Curl::PostField.content('admin', CONFIG['setup']['api']['user']),
 # //                            Curl::PostField.content('passwd', CONFIG['setup']['api']['password']),
 # //                            Curl::PostField.content('op', 'getoobuserinfo'),
 # //                            Curl::PostField.content('qtype', 'ip'),
 # //                            Curl::PostField.content('qval', ip))
 # //
 # // end

 c.perform

 # ///// puts c.body_str

 # /////
 # //
 # // check api for errors or null results
 # //
 error_chk(c)

 # ///// puts "-======================-"
 # ///// puts "error check for checkoobip"
 # ///// puts "ooberror"
 # ///// puts $ooberror
 # ///// puts "oobcount"
 # ///// puts $oobcount
 # ///// puts "loggedin"
 # ///// puts $loggedin

 if $ooberror == "0" && $oobcount == "1"
  $loggedin = "yes"
 else
  $loggedin = "no"
 end

 # ///// puts "loggedin"
 # ///// puts $loggedin
 # ///// puts "-======================-"

end

# //
# /////
# //////////////////////////////////////////////////
