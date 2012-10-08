def process_doctor(r, time='')  
  begin  
    url = "#{DOC_QUERY_URL}#{r}"  
    page = Nokogiri::HTML(open("#{url}"))  
  rescue  
       puts_error "Oops, had a problem getting the #{r}-entry: #{[e.to_str, e.backtrace.map{|b| "\n\t#{b}"}].join("\n")}"  
  end  
  
  rows = page.css('#hcpPayments tbody tr')  
  entities_arr = []  
  current_entity=nil  
  
   rows.each do |row|  
     current_entity= process_row(row, '', current_entity, {:entities=>entities_arr})  
   end  
  
   name = r.split('+')  
   puts_error("Should've been a last name at #{r}") if !name[0].match(/,$/)  
   name = "#{name[0].gsub(/,$/, '')}\t#{name[1..-1].join(' ')}"  
  
   vals=[]  
   entities_arr.each do |e|  
     e[:services].each do |s|  
       vals.push("#{name}\t#{e[:name]}\t#{e[:page]}\t#{e[:city]}\t#{e[:state]}\t#{s[0]}\t#{s[1]}\t#{s[2]}\t#{url}\t#{time}")  
    end  
   end  
  
  vals.each{|val| File.open("pfizer_doctor_details.txt", "a"){ |f|  
    f.puts val  
  }}  
  
  puts vals  
  return vals  
end  

