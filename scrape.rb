#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)


cablemodem = '192.168.100.1'
cablemodem_url = "http://#{cablemodem}"

ph = Net::Ping::HTTP.new( cablemodem )
agent = Mechanize.new

failed = false

trap( 'SIGINT' ) do
	puts
	exit!
end

options = {}
previous_collect = {}
while true
if ph.ping
	print '.'
	previous_collect = collect_info( cablemodem_url )
	unless options[:monitor]
		puts JSON.generate( previous_collect )
		exit
	end
	sleep 10.0
else
	failed = true
	while failed
		until ph.ping
			print '!'
			sleep 1.0
		end
		print 'x'
		sleep 5.0
		begin
			page = agent.get( cablemodem_url )
			failed = false
		rescue
		end
	end
end


def collect_info( url )
data = {}
page = agent.get( "#{cablemodem_url}/cmSignalData.htm" )
ap page
temp = {}
rows = page.search( '//center[1]/table/tbody/tr' )
rows[1..-1].each do |row|
	cols = row.xpath( './/td' )
	#ap cols[0].text.split(/ \s/)[0]
	key = case cols[0].text.split(/ \s/)[0]
		when 'Channel ID' then 'id'
		when 'Frequency' then 'freq'
		when 'Signal to Noise Ratio' then 'snr'
		when 'Downstream Modulation' then 'mod'
		when 'Power Level' then 'power'
	end
	temp[key.to_sym] = []
	cols[1..-1].each do |col|
		next if col.text =~ /Downstream Power Level/
		# Hacks becuase #strip! is not able to strip the trailing whitespace...
		pos = case key
			when 'id' then -3
			else -2
		end
		value = col.text[0..pos]
		value.strip!
		temp[key.to_sym].push( value )
	end
end

data[:downstream] = []
temp[:id].each_index do |index|
	data[:downstream].push({
		:channel_id  => temp[:id][index].to_i,
		:frequency   => temp[:freq][index],
		:snr         => temp[:snr][index],
		:modulation  => temp[:mod][index],
		:power_level => temp[:power][index],
	})
end

# Process upstream table
temp = {}
rows = page.search( '//center[2]/table/tbody/tr' )
rows[1..-1].each do |row|
	cols = row.xpath( './/td' )
	key = case cols[0].text.split(/ \s/)[0]
		when 'Channel ID' then 'id'
		when 'Frequency' then 'freq'
		when 'Ranging Service ID' then 'rsid'
		when 'Symbol Rate' then 'symrate'
		when 'Power Level' then 'power'
		when 'Upstream Modulation' then 'mod'
		when 'Ranging Status ' then 'ranging_status'
	end
	temp[key.to_sym] = []
	cols[1..-1].each do |col|
		next if col.text =~ /Downstream Power Level/
		# Hacks becuase #strip! is not able to strip the trailing whitespace...
		pos = case key
			when 'id' then -3
			else -2
		end
		value = col.text[0..pos]
		value.strip!
		temp[key.to_sym].push( value )
	end
end

data[:upstream] = []
temp[:id].each_index do |index|
	data[:upstream].push({
		:channel_id  => temp[:id][index].to_i,
		:frequency   => temp[:freq][index],
		:ranging_service_id => temp[:rsid][index],
		:symbol_rate => temp[:symrate][index],
		:power_level => temp[:power][index],
		:modulation  => temp[:mod][index],
		:ranging_status  => temp[:ranging_status][index],
	})
end

# Process upstream table
temp = {}
rows = page.search( '//center[3]/table/tbody/tr' )
rows[1..-1].each do |row|
	cols = row.xpath( './/td' )
	key = case cols[0].text.split(/ \s/)[0]
		when 'Channel ID' then 'id'
		when /Unerrored/ then 'unerrored'
		when /Correctable/ then 'correctable'
		when /Uncorrectable/ then 'uncorrectable'
	end
	temp[key.to_sym] = []
	cols[1..-1].each do |col|
		# Hacks becuase #strip! is not able to strip the trailing whitespace...
		pos = case key
			when 'id' then -3
			else -2
		end
		value = col.text[0..pos]
		value.strip!
		temp[key.to_sym].push( value )
	end
end

data[:signal_stats] = []
temp[:id].each_index do |index|
	data[:signal_stats].push({
		:channel_id  => temp[:id][index].to_i,
		:unerrored => temp[:unerrored][index],
		:correctable  => temp[:correctable][index],
		:uncorrectable  => temp[:uncorrectable][index],
	})
end


page = agent.get( 'http://192.168.100.1/cmAddressData.htm' )

temp = {}
rows = page.search( '//center[1]/table/tbody/tr' )
rows[1..-1].each do |row|
	cols = row.xpath( './/td' )
	key = case cols[0].text.split(/ \s/)[0]
		when 'Serial Number' then 'sn'
		when 'HFC MAC Address' then 'hfc_mac'
		when 'Ethernet IP Address' then 'eth_ip'
		when 'Ethernet MAC Address' then 'eth_mac'
	end
	cols[1..-1].each do |col|
		value = col.text[0..-1]
		value.strip!
		if key =~ /mac/
			value.gsub!( '-', ':' )
		end
		data[key.to_sym] = value
	end
end

temp = {}
data[:cpe] = []
rows = page.search( '//center[2]/table/tbody/tr' )
rows[1..-1].each do |row|
	cols = row.xpath( './/td' )
	data[:cpe].push({
	  :mac => cols[1].text,
	  :status => cols[2].text,
	})
end


## Logs
page = agent.get( 'http://192.168.100.1/cmLogsData.htm' )

data[:logs] = []
rows = page.search( '//center[1]/table/tbody/tr' )
keys = []
headers = rows[0].xpath( './/th' )
headers.each do |heading|
	key = heading.text.split(/ \s/)[0].downcase
	keys.push( key )
end
rows[1..-1].each do |row|
	temp = {}
	cols = row.xpath( './/td' )
	cols.each_with_index do |col,index|
		key = keys[index]
		value = cols[index].text[0..-1]
		value.strip!
		temp[key.to_sym] = value
	end
	data[:logs].push( temp )
end

