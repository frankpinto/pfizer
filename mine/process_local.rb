def process_row(row, i, current_entity, arrays)    
  
  tds = row.css('td').collect{|r| r.text.strip}  
  
   if !tds[3].blank?  
     if !tds[1].blank?  
     # new entity  
     puts tds[0]  
         current_entity = {:name=>tds[0],:city=>tds[1], :state=>tds[2], :page=>i, :services=>[]}  
         arrays[:entities].push(current_entity) if arrays[:entities]  
       current_class = row['class']  
       end  
  
     if tds[3].match(/Total/)  
       arrays[:totals].push([current_entity[:name], tds[4].strip_for_num, tds[5].strip_for_num].join("\t")) if arrays[:totals]  
  
     else  
        # new service  
       services_td = row.css('td')[3]  
       service_name = services_td.css("ul li a")[0].text.strip  
       puts "#{current_entity[:name]}\t#{service_name}"  
       current_entity[:services].push([service_name, tds[4].strip_for_num, tds[5].strip_for_num])   
  
       arrays[:doctors].push(services_td.css("ul li ul li a").map{|a| get_doc_query(a['href']) }.uniq) if arrays[:doctors]  
     end  
   elsif tds.reject{|t| t.blank?}.length == 0  
     #blank row  
   else  
     puts_error "Page #{i}: Encountered a row and didn't know what to do with it: #{tds.join("\t")}"  
   end  
  
   return current_entity  
end  
  
def process_local_pages  
  
  doctors_arr = []  
  entities_arr = []  
  totals_arr =[]  
  
  for i in 1..END_PAGE  
    begin  
       page = Nokogiri::HTML(open("#{BASE_URL}#{i}.html"))  
  
         count1, count2 = page.css('#pagination td.alignRight').last.text.match(/([0-9]{1,}) - ([0-9]{1,})/)[1..2].map{|c| c.to_i}  
         count = count2-count1+1  
  
         puts_error("Page #{i} WARNING: Pagination count is bad") if count < 0  
         puts("Page #{i}: #{count1} to #{count2}")  
  
         rows = page.css('#hcpPayments tbody tr')  
  
         current_entity=nil  
  
         rows.each do |row|  
           current_entity= process_row(row, i, current_entity, {:doctors=>doctors_arr, :entities=>entities_arr, :totals=>totals_arr})  
       end  
  
     rescue Exception=>e  
       puts_error "Oops, had a problem getting the #{i}-page: #{[e.to_s, e.backtrace.map{|b| "\n\t#{b}"}].join("\n")}"  
     else  
  
     end  
  end  
  
  File.open("pfizer_doctors.txt", 'w'){|f| 
    doctors_arr.uniq.each do |d| 
        f.puts(d) 
    end 
  } 
 
  File.open("pfizer_entities.txt", 'w'){|f| 
    entities_arr.each do |e| 
      e[:services].each do |s| 
        f.puts("#{e[:name]}\t#{e[:page]}\t#{e[:city]}\t#{e[:state]}\t#{s[0]}\t#{s[1]}\t#{s[2]}") 
      end 
    end 
  } 
 
  File.open("pfizer_entity_totals.txt", 'w'){|f|  
    totals_arr.uniq.each do |d|  
        f.puts(d)  
    end  
  }  
end  
