# Some general functions to deal with strings  
class String  
  
  alias_method :old_strip, :strip  
  
  def strip  
      self.old_strip.gsub(/^[\302\240|\s]*|[\302\240|\s]*$/, '').gsub(/[\r\n]/, " ")  
  end  
  
  def strip_for_num  
    self.strip.gsub(/[^0-9]/, '')  
  end  
  
  def blank?  
    respond_to?(:empty?) ? empty? : !self  
  end  
end  
  
END_PAGE=486  
BASE_URL=''  
DOC_QUERY_URL='http://www.pfizer.com/responsibility/working_with_hcp/payments_report.jsp?hcpdisplayName='  
  
def get_doc_query(str)  
  str.match(/hcpdisplayName\=(.+)/)[1]  
end  
  
def puts_error(str)  
  err = "#{Time.now}: #{str}"  
  puts err  
  File.open("pfizer_error_log.txt", 'a+'){|f| f.puts(err)}  
end  
