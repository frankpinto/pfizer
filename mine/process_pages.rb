def process_doctor_pages  
  time = Time.now  
  
  File.open("pfizer_doctors.txt", 'r'){|f|  
     f.readlines.each do |r|  
        vals = process_doctor(r, time)  
     end  
  }  
end    

