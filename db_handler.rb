require 'sqlite3'

class DbHandler

    def self.connect
        @db || @db = SQLite3::Database.new('db/db.db') 
        @db.results_as_hash = true
        return @db
        # d = @db.execute("select name from sqlite_master where type='table'")
        # p array_of_single_object_arrays_to_array_of_contence(d)
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

    def self.tables
        connect.execute("select name from sqlite_master where type='table'")
    end
    
    # creates multiple join sqlite command from an array of arrays of values
    #
    # - joins an array of arrays which contains the parameters of a join statement
    #
    # examples
    # join([["type", "table", "id1", "id2"]])
    # # => " type JOIN table ON id1 = id2"
    #
    # returns the sqlite command as a string
    def self.join(joins)
        if !joins
            return ""
        else
            join_string = " "
            joins.each do |join|
                join_string += join[0].to_s + " JOIN " + join[1].to_s + " ON " + join[2].to_s + " = " + join[3].to_s
            end
            return join_string
        end
    end

    def self.where(wheres)
        if !wheres
            return ""
        else
            where_string = " WHERE "
            where_values = []
            wheres.each_with_index do |where, i| 
                where_string += " AND " if i > 0
                where_string += where[0].to_s + " = ?"
                where_values << where[1]
            end
            return where_string, where_values
        end
    end


    

    def self.get(select = "*", joins = nil, wheres = nil, table = self.name.to_s.downcase)
        # table = self.name.to_s.downcase 
        where_string, where_values = where(wheres)
        return connect.execute("SELECT #{select} FROM #{table} #{join(joins)}#{where_string}", where_values)

    end

    
    def self.insert(hash, table = self.name.to_s.downcase)
        inputs = "?"
        columns = []
        values = []
        hash.keys.each_with_index do |key, i|
            inputs += ",?" if i > 0
            columns << key.to_s
            values << hash[key]
        end
        if columns.length > 1
            columns = columns.join(", ")
        else
            columns = columns[0]
        end

        connect.execute("INSERT INTO #{table} (#{columns}) VALUES(#{inputs})", values)
    end
    
    def self.get_where(id1, id2)
        get("*", nil, [[id1, id2]])
    end
end 

class Users < DbHandler 
end
class Tags < DbHandler
end
class Comments < DbHandler
end
class Comment_comments < DbHandler
end
class Posts < DbHandler
end
class Taggings < DbHandler
end


Tags.insert({name: "senap"})
# p Posts.get("*", [["left", "comments", "posts.id", "post_id"]], [["posts.id", 1]])