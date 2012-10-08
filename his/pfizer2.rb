# encoding: UTF-8

require 'rubygems'
require 'nokogiri'
require 'open-uri'


p "Encoding is:-"  
p  __ENCODING__



END_PAGE=486  
BASE_URL='http://www.pfizer.com/responsibility/working_with_hcp/payments_report.jsp?enPdNm=All&iPageNo='  
DOC_QUERY_URL='http://www.pfizer.com/responsibility/working_with_hcp/payments_report.jsp?hcpdisplayName='  


#-------------------------------------------------------------------------------------------
#
#                                         general funtions
#
#-------------------------------------------------------------------------------------------


       # Some general functions to deal with strings  
   class String  


     def strip
	self.gsub(/^[\302\240|\s]*|[\302\240|\s]*$/, '').gsub(/[\r\n]/, " ")
     end

     def strip_for_num  
       self.strip.gsub(/[^0-9]/, '')  
     end  
     
     def blank?  
       respond_to?(:empty?) ? empty? : !self  
     end  
   end  
     
     
   def get_doc_query(str)  
     str.match(/hcpdisplayName\=(.+)/)[1]  
   end  
     
   def puts_error(str)  
     err = "#{Time.now}: #{str}"  
     #puts err  
     File.open("errorlog.txt", 'a+'){|f| f.puts(err)}  
   end  


#-------------------------------------------------------------------------------------------
#
#                                         process_row
#
#-------------------------------------------------------------------------------------------



def process_row(row, i, current_entity, arrays)    
   
  tds = row.css('td').collect{|r| r.text.strip}  
   
  if !tds[3].blank?  
    if !tds[1].blank?  
    # new entity  
    #puts tds[0]  
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
        #puts "#{current_entity[:name]}\t#{service_name}"  
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
     


#-------------------------------------------------------------------------------------------
#
#                                         process_local_pages
#
# process_local_pages is a method that will iterate through every page (you can set BASE_URL to 
# either your hard drive if you've downloaded all the pages yourself, or to the Pfizer page), 
# run process_row, and store all the doctor names and payees into separate files, 
# as well as hold all the total amounts
#
#-------------------------------------------------------------------------------------------


  def process_local_pages  
     
     doctors_arr = []  
     entities_arr = []  
     totals_arr =[]  
     
     for i in 1..END_PAGE  
       begin  
          page = Nokogiri::HTML(open("#{BASE_URL}#{i}"))  
          count1, count2 = page.css('#pagination td.alignRight').last.text.match(/([0-9]{1,}) - ([0-9]{1,})/)[1..2].map{|c| c.to_i}  
          count = count2-count1+1  
          puts_error("Page #{i} WARNING: Pagination count is bad") if count < 0  
          #puts("Page #{i}: #{count1} to #{count2}")  
          rows = page.css('#hcpPayments tbody tr')  
          current_entity=nil  
          rows.each do |row|  
            current_entity= process_row(row, i, current_entity, {:doctors=>doctors_arr, :entities=>entities_arr, :totals=>totals_arr})  
          end  
     
          rescue Exception=>e  
 	  #puts "Error getting page #{i}"
          puts_error "Oops, had a problem getting the #{i}-page: #{[e.to_s, e.backtrace.map{|b| "\n\t#{b}"}].join("\n")}"  
          puts_error "**** Error getting page #{i} #{e} *****"
          else  
     
        end  
     end  
     
     File.open("doctors.txt", 'w'){|f| 
       doctors_arr.uniq.each do |d| 
       f.puts(d) 
       end 
     } 
    
     File.open("entities.txt", 'w'){|f| 
       entities_arr.each do |e| 
         e[:services].each do |s| 
           f.puts("#{e[:name]}\t#{e[:page]}\t#{e[:city]}\t#{e[:state]}\t#{s[0]}\t#{s[1]}\t#{s[2]}") 
         end 
       end 
     } 
    
     File.open("entitytotals.txt", 'w'){|f|  
       totals_arr.uniq.each do |d|  
           f.puts(d)  
       end  
     }  
   end  





#-------------------------------------------------------------------------------------------
#
#                                         process_doctor
#
# process_doctor is what we run after we've compiled the list of doctor names that show up on the Pfizer list. 
# Each doctor has his/her own page with detailed spending. The data rows are roughly in the same format as the main 
# list, so we reuse process_row  again
#
#-------------------------------------------------------------------------------------------


#
# SQL table target 
#
#  fromDate  
#  toDate 
#  hcpLastName 
#  hcpFirstName 
#  hcpNameSuffix
#  hcpProfessionalDesignation
#  street
#  city
#  state
#  zip
#  zipext
#  contentArea
#  payeeName
#  numOfEvents
#  amountPaid
#  paymentMethod
#  paymentTypeId
#  geolat
#  geolon

def process_doctor(r, time='')
  begin
    url = "#{DOC_QUERY_URL}#{r}"
    page = Nokogiri::HTML(open("#{url}"))
  rescue Exception => e
    puts_error "Error getting the #{r}-entry: #{[e.to_s, e.backtrace.map{|b| "\n\t#{b}"}].join("\n")}"
    #puts_error "**** Error getting entry #{r} #{e} *****"
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
     vals.push("#{name}\t#{e[:name]}\t#{e[:page]}\t#{e[:city]}\t#{e[:state]}\t#{s[0]}\t#{s[1]}\t#{s[2]}")
   end
  end

   vals.each{|val| File.open("doctordetails.txt", "a"){ |f|
   f.puts val
  }}

  return vals
end



#-------------------------------------------------------------------------------------------
#
#                                         process_doctor_pages
#
# process_doctor_pages is just a function that calls process_doctor  for each name in the pfizer_doctors.txt 
# we previously gathered  - the final result is pfizer_doctor_details.txt, which contains a line for every 
# payment to every doctor.
#
#-------------------------------------------------------------------------------------------



def process_doctor_pages
  time = Time.now

  File.open("doctors.txt", 'r'){|f|
     f.readlines.each do |r|
        vals = process_doctor(r, time)
     end
  }
end

 

#-------------------------------------------------------------------------------------------
#
#                                                 MAIN
#
#-------------------------------------------------------------------------------------------



process_local_pages 
process_doctor_pages
