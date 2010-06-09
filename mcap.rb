#!/usr/bin/ruby

require 'rubygems'
require 'time'
require 'packetfu'
require 'postgres'


# ///////////////////////////////////////////////////////////////////////
# //
# // table function that creates monthly tables if necessary
# //
# ///////////////////////////////////////////////////////////////////////
def table(day)

    conn = PGconn.connect("localhost", 5432, '', '', "maestro", "dbusername", "dbpassword")

    # //
    # // get dates for constraint exclusion
    # //
    d = Time.parse("day")
    doy = d.strftime("%Y")
    dom = d.strftime("%m")
    doy = doy.to_i
    dom = dom.to_i
    first_dom = Date.new(doy,dom, +1)
    last_dom = Date.new(doy,dom, -1)
    maestro_day = d.strftime("maestro_mac_%Y%m")
    maestro_day_idx = d.strftime("maestro_mac_%Y%m_idx")

    begin
        res  = conn.exec("SELECT * FROM #{maestro_day};");
    rescue
        puts "table doesn't exit\n"
        res = conn.exec("CREATE TABLE #{maestro_day} ( PRIMARY KEY(src_ip,src_mac,insert_time) , CHECK (insert_time >= '#{first_dom}' AND insert_time <= '#{last_dom}')) INHERITS (maestro_mac);")
        res = conn.exec("CREATE INDEX #{maestro_day_idx} ON #{maestro_day} (src_ip,src_mac,insert_time);")
    else
        puts "table exits\n"
    end

    conn.close()

end

month=nil

cap = PacketFu::Capture.new(:iface => 'eth1.801', :start => true, :promisc => true, :filter => "dst host 172.16.16.49 and dst port 80")

cap.stream.each do |pkt|

      packet = PacketFu::Packet.parse(pkt)
      puts [packet.ip_saddr, packet.eth_saddr]
      src_ip = packet.ip_saddr
      src_mac = packet.eth_saddr

      # //
      # // muck with the date/time
      # //
    
       t = Time.parse(pkt)
       insert_time = t.strftime("%Y-%m-%d %H:%M:%S")
       tmp = t.strftime("%m")
   
       # //
       # //  check for current table
       # //
   
       maestro_day = t.strftime("maestro_mac_%Y%m")
       day = t.strftime("%Y-%m")
       
       if tmp != month
           puts "creating new table\n"
           table(day)
       end
   
       month = t.strftime("%m")

       # //
       # // insert data and supress errors
       # //

       conn = PGconn.connect("localhost", 5432, '', '', "maestro", "dbusername", "dbpassword")

       begin
           res = conn.exec("INSERT INTO #{maestro_day} (src_ip,src_mac,insert_time)
                           VALUES('#{src_ip}','#{src_mac}','#{insert_time}');")
       rescue
           puts "skipping insert, duplicate found."
       else
           puts "inserting data, src_ip: #{src_ip}"
       end

       conn.close()

end

# ///////////////////////////////////////////////////////////////////////
