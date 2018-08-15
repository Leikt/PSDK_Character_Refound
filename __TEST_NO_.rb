begin
	
	# t = Test.new
	tstart = Time.new
	10000.times do |i|
		# t.update_variables
	end
	d1 = Time.new - tstart
	tstart = Time.new
	10000.times do |i|
		# t.update_counters
	end
	d2 = Time.new - tstart
	puts "Old : #{d1}, New : #{d2}. Ratio d1/d2 : #{((d1/d2)*100).round}% (#{((d1/d2)*100).round > 100 ? 'faster' : 'slower'})"
system("pause")
	
rescue Exception => e
	puts e.message
	puts e.backtrace
	system("pause")
end