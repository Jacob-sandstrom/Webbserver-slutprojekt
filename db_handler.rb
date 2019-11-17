require 'sqlite3'
require 'bcrypt'

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
    #   array_of_single_object_arrays_to_array_of_contence([["hej"], ["do"]]) 
    #   # => ["hej", "do"]
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
    #   join([["type", "table", "id1", "id2"]])
    #   # => " type JOIN table ON id1 = id2"
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

    
    # does a select query from the database
    #
    # - select  what to select
    # - joins   an array of arrays which contains the parameters of a join statement
    # - wheres  an array of arrays which contains the parameters of a where statement
    # - table   the table to select from
    #
    # returns the sqlite select hash/array
    def self.get(select = "*", joins = nil, wheres = nil, table = self.name.to_s.downcase)
        # table = self.name.to_s.downcase 
        where_string, where_values = where(wheres)
        return connect.execute("SELECT #{select} FROM #{table} #{join(joins)} #{where_string}", where_values)

    end

    # Creates sqlite strings and values from a hash that can later be used in an insert or update sqlite command
    #
    # - hash    a hash where the key is the column in the table and the value is the value to be set to that column
    # - type    a string which decides a slight change in the output data depending on what sqlite command it is to be used for
    #
    # examples
    #   split_hash_to_sqlite_stuff({name: "Admin", is_admin: 1}, "update")
    #   # => [",?", "name = ?, is_admin = ?", ["Admin", 1]]
    #
    # returns an array contaning the correct amount of ? to be put inside VALUES() as well as the columns and values to be put into the columns
    def self.split_hash_to_sqlite_stuff(hash, type = "insert")
        inputs = "?"
        columns = []
        values = []
    
        hash.keys.each_with_index do |key, i|
            inputs += ",?" if i > 0
            columns << key.to_s
            values << hash[key]
        end

        if type == "update"
            columns.each_with_index do |col, i|
                columns[i] = col + " = ?"
            end
        end

        if columns.length > 1
            columns = columns.join(", ")
        else
            columns = columns[0]
        end

        return inputs, columns, values
        
    end
    
    
    # inserts a new row into a table from the values in a hash
    #
    # - hash    a hash where the key is the column in the table and the value is the value to be set to that column
    # - table   the table to update
    #
    # returns nothing but edits the db
    def self.insert(hash, table = self.name.to_s.downcase)
        inputs, columns, values = split_hash_to_sqlite_stuff(hash, "insert")
        
        connect.execute("INSERT INTO #{table} (#{columns}) VALUES(#{inputs})", values)
    end
    
    # updates a row in a table from the values in a hash
    #
    # - hash    a hash where the key is the column in the table and the value is the value to be set to that column
    # - wheres  an array of arrays which contains the parameters of a where statement
    # - table   the table to update
    #
    # returns nothing but edits the db
    def self.update(hash, wheres = nil, table = self.name.to_s.downcase)
        inputs, columns, values = split_hash_to_sqlite_stuff(hash, "update")
        where_string, where_values = where(wheres)
        values += where_values if where_values

        connect.execute("UPDATE #{table} SET #{columns} #{where_string}", values)
    end


    def self.get_row_where(id1, id2)
        get("*", nil, [[id1, id2]])
    end
    
    def self.get_specific(select, id1, id2)
        val = get(select, nil, [[id1, id2]])
        if val != []
            val = val[0][select]
        else
            val = nil
        end
    end
end 

class Users < DbHandler 

    def self.get_id_from_name(username)
        get_specific("id", "name", username)
    end
    
    def self.get_name_from_id(id)
        get_specific("name", "id", id)
    end

    def self.add_user_to_db(username, pwd_hash)
        insert({name: username, pwd_hash: pwd_hash, creation_time: Time.now.to_s})
    end

    def self.fetch_pwd(username)
        get_specific("pwd_hash", "name", username)
    end

	def self.create_user(username, password)
		user_id = get_id_from_name(username)
        return false if user_id != nil
       
        hashed = BCrypt::Password.create(password)
        add_user_to_db(username, hashed)
        return true
    end
   
    def self.auth_user(username, password)
        user_id = get_id_from_name(username)
		return false if user_id == nil
       
		db_hash = BCrypt::Password.new(fetch_pwd(username))
        success = db_hash == password
		
		if success
			return true
        else 
            return false
        end
	end

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

# Users.get_id_from_name("Jacb")
# p Users.get("*", nil, [["id", 1]])
# Users.update({name: "Admin", is_admin: 1}, [["id", 1]])
# p Posts.get("*", [["left", "comments", "posts.id", "post_id"]], [["posts.id", 1]])