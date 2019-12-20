require 'sqlite3'


class DbHandler
    
    # attr_accessor :fields, :table_name, :has

    def initialize(hash)
        @hash_fields = {}

        self.class.fields.each do |field|
            instance_variable_set("@#{field}", hash[field])
            singleton_class.class_eval { attr_accessor field }  # creates attr_accessors for each field
            @hash_fields[field] = hash[field]
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
    def self.has_many_joins
        @has_many_joins
    end

    
    # ------------------------------------------------------- Getters
    
    def self.connect()
        @db ||= SQLite3::Database.new('db/db.db') 
        @db.results_as_hash = true
        return @db
    end

    def self.join(joins)
        if !joins
            return ""
        else
            join_string = " "
            joins.each do |join|
                join_string += " " + join[0].to_s + " JOIN " + join[1].to_s + " ON " + join[2].to_s + " = " + join[3].to_s
            end
            return join_string
        end
    end

    def self.hash_to_wheres(hash)
        wheres = []
        hash.each do |ha|
            wheres << [ha[0].to_s, ha[1]]
        end
        wheres
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

    def self.limits(limit)
        if limit
            return " Limit #{limit}"
        else
            return ""
        end
    end 
    
    def self.get(select = "*", joins = nil, wheres = nil, orders = nil, limit = nil, table = @table_name)
        where_string, where_values = where(wheres)
        return connect.execute("SELECT #{select} FROM #{table} #{join(joins)} #{where_string} #{order(orders)} #{limits(limit)}", where_values)
    end

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

    def self.insert(hash, table = @table_name)
        inputs, columns, values = split_hash_to_sqlite_stuff(hash, "insert")
        connect.execute("INSERT INTO #{table} (#{columns}) VALUES(#{inputs})", values)
    end

    def self.get_last_id()
        get("id", nil, nil, [["id", "DESC"]], 1)[0]["id"]
    end

    def save_to_db()
        self.class.connect.transaction
        self.class.insert(@hash_fields)
        @id = self.class.get_last_id()
        self.class.connect.commit

        @hash_fields["id"] = @id
    end

    def self.create(hash)
        instance = self.new(hash)
        instance.save_to_db()
        instance.create_attr_accessors()
        return instance
    end

    def self.fetch_by_id(id)
        data = get("*", nil, [["id", id]])[0]
        instance = self.new(data)
    end

    def self.fetch(hash)
        wheres = hash_to_wheres(hash)
        data = get("*", nil, wheres)
        instances = []
        data.each do |dat|
            instances << self.new(dat)
        end
        return instances
    end

    def self.has_many(table)
        @has ||= []
        @has << table

        @has_many_joins ||= {}
        @has_many_joins[table] = ["left", table, "#{table}.id", "#{table}_id"]

        
    end

    def self.belongs_to(table)

    end

    def self.many_many(table, intermediate)
        @has ||= []
        @has << table

        @has_many_joins ||= {}
        @has_many_joins[table] = [["left", intermediate, "#{intermediate}.id", "#{intermediate}_id"], ["left", table, "#{table}_id", "#{table}.id"]]

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

end

class Post < DbHandler

    set_table_name "post"

    set_field "id"
    set_field "title"
    set_field "content"
    set_field "votes"
    set_field "creation_time"
    set_field "user_id"

    belongs_to "user"

    has_many "comment" #Post#comments => [Comment] (joins) 

    many_many "tag", "tagging"


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

end

# user = Users.create({"name" => "Amanda", "pwd_hash" => "password", "creation_time" => Time.now.to_s, "is_admin" => 1})



po = Post.fetch_by_id(1)

p po.comment
