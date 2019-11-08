require 'sqlite3'

class DbHandler

    def self.connect
        @db = SQLite3::Database.new('db/db.db')
        d = @db.execute("select name from sqlite_master where type='table'")
        p array_of_single_object_arrays_to_array_of_contence(d)
    end


    # turns an array which contains single object arrays into a new array which contains the value of the single object arrays
    # 
    # - array_in an array which contains single object arrays
    #
    # examples
    # array_of_single_object_arrays_to_array_of_contence([["hej"], ["do"]]) 
    # # => ["hej", "do"]
    #
    # returns the new array
    def self.array_of_single_object_arrays_to_array_of_contence(array_in)
        array_out = []
        array_in.each do |x|
            array_out << x[0]
        end
        return array_out
    end

    
    
    
end 

class TableHandler
    
    
    def get
        grill = self.class.to_s.downcase + "s" 
    end

end


class User < TableHandler



end


# User.get()


DbHandler.connect