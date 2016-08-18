#!/usr/bin/env ruby
#

require 'awesome_print'
require 'mechanize'

data = {}
agent = Mechanize.new


page = agent.get( 'http://192.168.100.1/cmSignalData.htm' )

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


ap data
