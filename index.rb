# //////////////////////////////////////////////////
# /////
# //
# // simple app to take input from client and
# //  register their wireless device via api
# //
# /////
# //////////////////////////////////////////////////


require 'rubygems'
require 'haml'
require 'yaml'
require 'time'
require 'postgres'
require 'ipaddr'
require 'caapi'


# //////////////////////////////////////////////////
# /////
# //
# // pull in secrets
# //

CONFIG = YAML::load(File.read('config/maestro.yaml'))

# //
# /////
# //////////////////////////////////////////////////








# //////////////////////////////////////////////////
# /////
# //
# // return mac address per given ip
# //

def qip(src_addr)
  conn = PGconn.connect("localhost",5432,'','',CONFIG['setup']['db']['dbname'],CONFIG['setup']['db']['user'],CONFIG['setup']['db']['password'])
   begin
    $res  = conn.exec("select src_mac,insert_time from dstil_mac where src_ip='#{src_addr}' order by insert_time desc limit 1;");
   rescue
      # // puts "query failed"
   else
      # // puts "query ok"
   end
  conn.close()
end

# //
# /////
# //////////////////////////////////////////////////








# //////////////////////////////////////////////////
# /////
# //
# // insert request into db
# //  this is just to keep a record or registers
# //

def qreg(firstname,lastname,username,devmake,devmodel,devmac,devprob,devagent)
  conn = PGconn.connect("localhost",5432,'','',CONFIG['setup']['db']['dbname'],CONFIG['setup']['db']['user'],CONFIG['setup']['db']['password'])
   begin
    t = Time.now    
    insert_time = t.strftime("%Y-%m-%d %H:%M:%S")
    $ins = conn.exec("insert into dstil_reg values ('#{firstname}','#{lastname}','#{username}','#{devmake}','#{devmodel}','#{devmac}','#{devprob}','#{insert_time}','#{devagent}');");
   rescue
    puts "insert failed"
   else
    puts "insert ok"
    # // puts "'#{firstname}','#{lastname}','#{username}','#{devmake}','#{devmodel}','#{devmac}','#{devprob}','#{insert_time}','#{devagent}'"
   end
  conn.close()
end

# //
# /////
# //////////////////////////////////////////////////








# //////////////////////////////////////////////////
# /////
# //
# // check for null values
# //

def er_chk(field,value)
  
  if value.nil? or value == ""
   params[:"#{field}"] = nil
  end

end

# //
# /////
# //////////////////////////////////////////////////








# //////////////////////////////////////////////////
# /////
# //
# //
# //

get '/' do

 v801 = IPAddr.new("172.16.16.0/20")
 v803 = IPAddr.new("172.16.32.0/20")

 naddr = @env['REMOTE_ADDR']

 n801 = v801.include?(IPAddr.new(naddr))
 n803 = v803.include?(IPAddr.new(naddr))

 if n801 == true or n803 == true

  $checks_ok = "no"
  $registered = nil
  $loggedin = nil

  qip(@env['REMOTE_ADDR'])
  $devmac = $res[0][0]

  inputs = ["firstname","lastname","username","devmake","devmodel","devprob"]
  
  inputs.each do |value|
   params[:"#{value}"] = ""
  end

  params[:agreement] = "on"

  haml :index

 end

end

# //
# /////
# //////////////////////////////////////////////////








# //////////////////////////////////////////////////
# /////
# //
# // evaluate registration request
# //

post '/' do


 # /////
 # //
 # // set some sort of checks
 # // not sure the proper way todo this
 # // 
 username = nil
 checks_ok = "yes"
 $registered = nil
 $loggedin = nil


 # /////
 # //
 # // grab mac address again  
 # //
 src_addr = @env['REMOTE_ADDR']
 qip(src_addr)
 er_chk("devmac",$res[0][0])


 # /////
 # //
 # // grab user agent
 # //
 er_chk("devagent",@env['HTTP_USER_AGENT'])


 # /////
 # //
 # // massage form data
 # //
 inputs = ["firstname","lastname","username","devmake","devmodel","devprob","agreement"]


 # /////
 # //
 # // validate inputs
 # //
 inputs.each do |value|
  er_chk("#{value}",params[:"#{value}"])
 end


 # /////
 # //
 # // if there was a nil value set checks_ok
 # //
 inputs.each do |value|
   if params[:"#{value}"].nil?
    checks_ok = "no"
   end
 end


 # /////
 # //
 # // to register or not
 # //
 if checks_ok == "yes"

  checkoobmac($res[0][0])
  checkmac($res[0][0])
   puts "mac addr:", $res[0][0]
   puts "registered:", $registered
   puts "logged in:", $loggedin
  
  if $registered == "no" && $loggedin == "no"

   # /////
   # //
   # // throw it in the db
   # //
   qreg(params[:firstname],params[:lastname],params[:username],params[:devmake],params[:devmodel],$res[0][0],params[:devprob],@env['HTTP_USER_AGENT'])
   
   # /////
   # //
   # // register it via api
   # //
   # desc = [ params[:firstname],params[:lastname],params[:username] ]
   desc = "#{params[:username]} (CA API)"
   regmac($res[0][0],desc)
  
  end
  
  haml :reg

 else

  haml :index

 end

end

# //
# /////
# //////////////////////////////////////////////////
