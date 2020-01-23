require 'sqlite3'

class Hash
    def hash_keys_to_string(hash)
        result = {}
        hash.keys.each do |key|
        result[key.to_s] = hash[key]
        end
        result
    end
end

class DbHandler
    def initialize(hash)
        hash = hash.hash_keys_to_string(hash)
        @hash_fields = {}

        self.class.fields.each do |field|            
            instance_variable_set("@#{field}", hash[field])
            singleton_class.class_eval { attr_accessor field }  # creates attr_accessors for each field
            @hash_fields[field] = hash[field] if hash[field]
        end

        if self.class.has 
            self.class.has.each do |h|
                instance_variable_set("@#{h}", [])
                singleton_class.class_eval { attr_accessor h }
            end
        end
        
    end

    def self.set_table_name(name)
        @table_name = name
    end

    # adds name to a hash representing to columns in the db
    def self.set_field(name)
        @fields ||= []
        @fields << name
    end

    # ------------------------------------------------------- Getters
    def self.table_name
        @table_name
    end
    def self.fields
        @fields
    end
    def self.has
        @has
    end
    def self.has_joins
        @has_joins
    end
    def self.aliases
        @aliases
    end
    # ------------------------------------------------------ /Getters
    
    # connects to the database
    def self.connect()
        @db ||= SQLite3::Database.new('db/db.db') 
        @db.results_as_hash = true
        return @db
    end

    # processess a select string so that the column names is table.columnname if everything is selected
    def self.process_select(select, joins)
        if select == "*" 
            select_str = ""
            self.fields.each_with_index do |field, i|
                i == 0? select_str += "#{self.to_s.downcase}.#{field} as '#{self.to_s.downcase}.#{field}'" : select_str += ", #{self.to_s.downcase}.#{field} as '#{self.to_s.downcase}.#{field}'"
            end 
            if joins != [] && joins
                
                joins.map {|j| [j[1], j[4]]}.each do |table, as| 
                    if as
                        Object.const_get(table.to_s.capitalize).fields.each {|field| select_str += ", #{as}.#{field} as '#{as}.#{field}'"}
                    else
                        Object.const_get(table.to_s.capitalize).fields.each {|field| select_str += ", #{table}.#{field} as '#{table}.#{field}'"}
                    end
                end
            end
        else
            select_str = select
        end

        return select_str
    end

    # processes a join array to join string
    def self.join(joins)
        if !joins
            return ""
        else
            join_string = " "
            joins.each do |join|
                if join[4]
                    join_string += " " + join[0].to_s + " JOIN " + join[1].to_s + " as " + "'#{join[4]}'" + " ON " + join[2].to_s + " = " + join[3].to_s
                else
                    join_string += " " + join[0].to_s + " JOIN " + join[1].to_s + " ON " + join[2].to_s + " = " + join[3].to_s
                end
            end
            return join_string
        end
    end

    # processess a hash to a where array
    #
    # - hash {where this: equals this, and this: equals this}
    #
    # examples
    #   hash_to_wheres({where this: equals this, and this: equals this})
    # =>[[where this, equals this], [and this, equals this]]
    def self.hash_to_wheres(hash)
        wheres = []
        hash.each do |ha|
            wheres << [ha[0].to_s, ha[1]]
        end
        wheres
    end

    # processess a where array to a where string
    def self.where(wheres)
        if !wheres || wheres == []
            return ""
        else
            where_string = " WHERE "
            where_values = []
            wheres.each_with_index do |where, i| 
                where_string += " AND " if i > 0
                where_string += where[0].to_s + " = ?"
                where_values << where[1].to_s
            end
            return where_string, where_values
        end
    end

    # processess an order array into an order string
    def self.order(orders)
        if !orders
            return ""
        else
            order_str = " ORDER BY "
            orders.each_with_index do |order, i|
                order_str += ", " if i > 0
                order_str += order[0] + " " + order[1]
            end

            return order_str
        end 
    end

    # takes an integer and returns " Limit #{integer}"
    def self.limits(limit)
        if limit
            return " Limit #{limit}"
        else
            return ""
        end
    end 
    
    # gets data from the db
    #
    # - select  a string containing the values to select
    # - joins   an array of things to join: [[join type, table, join on this, equal to this]]
    # - wheres  an array of where values:   [[where this, equals this], [and this, equals this]]
    # - orders  an array of order values:   [[column, direction]]
    # - limit   an integer
    # - table   the table
    #
    # returns the data
    def self.get(select = "*", joins = nil, wheres = nil, orders = nil, limit = nil, table = @table_name)   
        where_string, where_values = where(wheres)
        # p "SELECT #{process_select(select, joins)} FROM #{table} #{join(joins)} #{where_string} #{order(orders)} #{limits(limit)}"
        # p where_values
        return connect.execute("SELECT #{process_select(select, joins)} FROM #{table} #{join(joins)} #{where_string} #{order(orders)} #{limits(limit)}", where_values)
    end

    # slits a hash into the necessary components of an insert or update sql statement
    #
    # - hash a hash where the key is the column in the table and the value is the value to be set to that column
    #
    # examples
    #    split_hash_to_sqlite_stuff({title: "woweee", content: "eeewow"}, "insert")
    # => ["?,?", "title = ?, content = ?", ["wowee", "eewow"]]
    #
    # returns an array containing the parts of an insert
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

    # inserts values contained in a hash into a table creating a new row
    #
    # - hash    a hash where the key is the column in the table and the value is the value to be set to that column
    def self.insert(hash, table = @table_name)
        inputs, columns, values = split_hash_to_sqlite_stuff(hash, "insert")
        connect.execute("INSERT INTO #{table} (#{columns}) VALUES(#{inputs})", values)
    end
 
    # updates a row in a table from the values in a hash
    #
    # - hash    a hash where the key is the column in the table and the value is the value to be set to that column
    # - wheres  an array of arrays which contains the parameters of a where statement [[where_this, equals_this], [and this, equals this]]
    # - table   the table to update
    #
    # returns nothing but edits the db
    def self.update(hash, wheres = nil, table = self.name.to_s.downcase)
        inputs, columns, values = split_hash_to_sqlite_stuff(hash, "update")
        where_string, where_values = where(wheres)
        values += where_values if where_values
        
        connect.execute("UPDATE #{table} SET #{columns} #{where_string}", values)
    end

    # deletes row where condition is true
    #
    # - wheres  [[where_this, equals_this], [and this, equals this]]
    def self.delete(wheres, table = self.name.to_s.downcase)
        where_string, where_values = where(wheres)
        connect.execute("DELETE FROM #{table} #{where_string}", where_values)
    end
    def self.get_last_id()
        get("#{self.name.to_s.downcase}.id", nil, nil, [["id", "DESC"]], 1)[0]["id"]
    end

    # saves an instances information to the db
    def save_to_db()
        self.class.connect.transaction
        self.class.insert(@hash_fields)
        @id = self.class.get_last_id()
        self.class.connect.commit

        @hash_fields["id"] = @id
    end

    # creates an instance of a class from a hash containing all values necessary to fill a row in the db
    def self.create(hash)
        instance = self.new(hash)
        instance.save_to_db()
        # instance.create_attr_accessors()
        return instance
    end

    # processess the has_hash
    #
    # - has_hash    a hash containing the tables to join 
    #
    # returns the joins in the format [[join type, table, join on this, equal to this]]
    def self.process_has_hash_to_joins(has_hash)
        joins = []
        has_hash.keys.each do |key|
            if self.has.include? key.to_s 
                joins << self.has_joins[key.to_s]
                joins += Object.const_get(key.to_s.capitalize).process_has_hash_to_joins(has_hash[key]) if has_hash[key] 
                if joins[-1][0].kind_of?(Array)
                    temp = joins[-1]; joins.pop(); joins += temp
                end
            end
        end
        return joins
    end

    # creates instances of the data from the db
    #
    # - data             an array of hashes 
    # - has_hash         a hash containing the tables to join 
    # - caller_class     the name of the class that called the function
    #
    # returns an array of instances 
    def self.process_data(data, has_hash, caller_class)
        reshaped_data = []
        data.each do |row|
            foo = {}
            name = self.name.to_s.downcase
            
            if caller_class && caller_class.aliases
                if caller_class.aliases[name]
                    name = caller_class.aliases[name]
                    
                end
                
            end
            
            self.fields.each do |field|
                foo[field] = row["#{name}.#{field}"]
            end
            reshaped_data << foo
        end
        
        instances = reshaped_data.uniq { |specific| [specific["id"]] }.map {|dat| self.new(dat)}
        
        instances.each_with_index do |instance, index|
            id = instance.id
            if instance.id == nil
                instances[index] = nil
                next
            end
            
            if has_hash 
                has_hash.keys.each do |table|
                    if self.has.include? table.to_s
                        instance.method("#{table.to_s}=").call(Object.const_get(table.to_s.capitalize).process_data(data.select {|x| x["#{self.name.to_s.downcase}.id"] == id}, has_hash[table.to_sym], self))
                    end
                end 
            end
        end
 
        instances = [] if instances == [nil]
        return instances
    end

    # gets and creates instances of a class 
    #
    # - where_hash  {where this: equals this, and this: equals this}
    # - hash_hash   a hash containing the tables to join 
    def self.fetch(where_hash, has_hash={}, orders = nil, limit = nil)
        wheres = hash_to_wheres(where_hash)
        joins = process_has_hash_to_joins(has_hash)
        data = get("*", joins, wheres, orders, limit)
        instances = process_data(data, has_hash, nil)
        return instances
    end

    # removes rows from the db 
    def self.remove(where_hash)
        delete([["#{self.name.to_s.downcase}.#{where_hash.keys[0]}", where_hash[where_hash.keys[0]]]])
        @dependencies.each do |dependency|
            delete([["#{self.name.to_s.downcase}_id", where_hash[where_hash.keys[0]]]], dependency)
        end
    end
    
    # creates several arrays making it easier to joins things later     one to many relationship
    #
    # - as  an alias for the table
    def self.has_many(table, as=nil)
        @has ||= []
        @has << table
        @dependencies ||= []
        @dependencies << table
        @has_joins ||= {}
        @aliases ||= {}
        @aliases[table] = as
        
        if as
            @has_joins[table] = ["left", table, "#{self.to_s.downcase}.id", "#{as}.#{self.to_s.downcase}_id", as]
        else
            @has_joins[table] = ["left", table, "#{self.to_s.downcase}.id", "#{table}.#{self.to_s.downcase}_id"]
        end
    end
    
    # creates several arrays making it easier to joins things later     many to many relationship
    def self.many_many(table, intermediate)
        @has ||= []
        @has << table
        @dependencies ||= []
        @dependencies << intermediate
        
        @has_joins ||= {}
        @has_joins[table] = [["left", intermediate, "#{self.to_s.downcase}.id", "#{intermediate}.#{self.to_s.downcase}_id"], ["left", table, "#{intermediate}.#{table}_id", "#{table}.id"]]
    end
    
    # creates several arrays making it easier to joins things later     many to one relationship
    #
    # - as  an alias for the table
    def self.has_one(table, as=nil)
        @has ||= []
        @has << table
        @aliases ||= {}
        @aliases[table] = as
        
        @has_joins ||= {}
        if as
            @has_joins[table] = ["left", table, "#{as}.id", "#{self.to_s.downcase}.#{table}_id", as]
        else
            @has_joins[table] = ["left", table, "#{table}.id", "#{self.to_s.downcase}.#{table}_id"]
        end
    end

end


class User < DbHandler 
    
    set_table_name "user"
    
    set_field "id"       
    set_field "name"           #, type: string, required: true
    set_field "pwd_hash"       
    set_field "creation_time"       
    set_field "is_admin"       
    
    has_many "post"
    has_many "comment"
    has_many "vote"
    many_many "tags", "tagging"
    
    # creates a user if one with the same name doesn't already exist 
    #
    # returns the created user as an instance
    def self.create_user(username, password)
        u = self.fetch({name: username})[0]
        return nil if u 
        
        hashed = BCrypt::Password.create(password)
        user = create({name: username, pwd_hash: hashed, creation_time: Time.now.to_s})
        return user
    end
    
    # authenticates if username and password is correct
    #
    # returns an instance of user on success else returns nil 
    def self.auth_user(username, password)
        u = self.fetch({name: username})[0]
		return false if u == nil
        
		db_hash = BCrypt::Password.new(u.pwd_hash)
        success = db_hash == password
        
		if success
			return u
        else 
            return nil
        end
    end
    
end
class Post < DbHandler
    
    set_table_name "post"
    set_field "id"
    set_field "title"
    set_field "content"
    set_field "vote"
    set_field "creation_time"
    set_field "user_id"
    

    has_many "comment" 
    has_many "vote"
    has_one "user", "poster"
    
    many_many "tag", "tagging"
    
    def initialize(hash)
        super
        @vote << Vote.get_score(self.id)
    end

    # sets the vote in db to a value
    def self.set_score(id, score)
        update({vote: score}, [["id", id]])
    end
    
end
class Comment < DbHandler

    set_table_name "comment"
    set_field "id"
    set_field "content"
    set_field "post_id"
    set_field "user_id"
    set_field "creation_time"
    set_field "comment_id"

    has_many "comment"
    has_one "user", "commentor"

    # belongs_to "user", as: "commentor"

    # organizes comments so that comments on comments get put inside those comments
    #
    # - comments    an array instances of the class Comment
    # - commet_id   the id the comment belongs to
    def self.organize(comments, comment_id)
        sorted_comments = []
        remaining_comments = []
        comment_ids = []

        comments.each do |comment|
            next if comment == nil
            comment_ids.include?(comment.id)? next : comment_ids << comment.id
            (comment.comment_id == comment_id)? sorted_comments << comment : remaining_comments << comment
        end

        sorted_comments.each {|comment| comment.comment = organize(remaining_comments, comment.id)}

        return sorted_comments
    end

    def self.process_data(data, has_hash, caller_class)
        return organize(super(data, has_hash, caller_class), 0)
    end

end
class Tag < DbHandler

    set_table_name "tag"
    set_field "id"
    set_field "name"
    
    many_many "post", "tagging"

    
end
class Tagging < DbHandler
    
    set_table_name "tagging"
    set_field "post_id"
    set_field "tag_id"
    
    # creates a row in the tagging table
    def self.add(post_id, tag_ids, user_id)
        connect.transaction
        tag_ids.each do |id|
            insert({post_id: post_id, tag_id: id, user_id: user_id})
        end
        connect.commit
    end

end
class Vote < DbHandler
    
    set_table_name "vote"
    
    set_field "user_id"
    set_field "post_id"
    set_field "score"

    # changes the vote for a specific user on a specific post
    def self.change(post_id, user_id, score)
        data = get("user_id, post_id", nil, [["post_id", post_id],["user_id", user_id]])
        if data == []
            insert({post_id: post_id, user_id: user_id, score: score})
        else
            update({post_id: post_id, user_id: user_id, score: score}, [["post_id", post_id],["user_id", user_id]])
        end
    end
    def self.get_score(post_id)
        scores = get("score", nil, [["post_id", post_id]])
        total_score = 0

        scores.each do |score|
            total_score += score["score"]
        end
        return total_score
    end

end
