require 'sqlite3'
require 'bcrypt'

class DbHandler

    def self.set_table_name(name)
        @table_name = name
    end

    def self.fields(name)
        @fields ||= []
        @fields << name
    end


    def self.connect
        @db ||= SQLite3::Database.new('db/db.db') 
        @db.results_as_hash = true
        return @db
        # d = @db.execute("select name from sqlite_master where type='table'")
        # p array_of_single_object_arrays_to_array_of_content(d)
    end


    # turns an array which contains single object arrays into a new array which contains the value of the single object arrays
    # 
    # - array_in an array which contains single object arrays
    #
    # examples
    #   array_of_single_object_arrays_to_array_of_content([["hej"], ["do"]]) 
    #   # => ["hej", "do"]
    #
    # returns the new array
    def self.array_of_single_object_arrays_to_array_of_content(array_in)
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
                join_string += " " + join[0].to_s + " JOIN " + join[1].to_s + " ON " + join[2].to_s + " = " + join[3].to_s
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
    
    # does a select query from the database
    #
    # - select  what to select
    # - joins   an array of arrays which contains the parameters of a join statement
    # - wheres  an array of arrays which contains the parameters of a where statement
    # - table   the table to select from
    #
    # returns the sqlite select hash/array
    def self.get(select = "*", joins = nil, wheres = nil, orders = nil, limit = nil, table = self.name.to_s.downcase)
        # table = self.name.to_s.downcase 
        where_string, where_values = where(wheres)
        return connect.execute("SELECT #{select} FROM #{table} #{join(joins)} #{where_string} #{order(orders)} #{limits(limit)}", where_values)
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

    def self.delete(wheres, table = self.name.to_s.downcase)
        where_string, where_values = where(wheres)
        connect.execute("DELETE FROM #{table} #{where_string}", where_values)
    end



    # def self.get_row_where(id1, id2)
    #     get("*", nil, [[id1, id2]])[0]
    # end
    # def self.get_by_id(id)
    #     get_row_where("id", id)
    # end
    
    def self.get_specific(select, id1, id2)
        val = get(select, nil, [[id1, id2]])
        if val != []
            val = val[0][select]
        else
            val = nil
        end
    end

    def self.get_where(select, id1, id2)
        get(select, nil, [[id1, id2]])
    end

end 

class User < DbHandler 

    # set_table_name "user"
    # fields "id"       
    # fields "name"           #, type: string, required: true
    # fields "pwd_hash"       
    # fields "creation_time"       
    # fields "is_admin"       


 

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
    
    def self.delete_at(id)
        delete([["id", id]])
        delete([["user_id", id]], "post")
        delete([["user_id", id]], "comment")
    end

end
class Tag < DbHandler

    def self.get_all
        tag = get("name, id")
        tag.each_with_index do |tag, i|
            t = []
            tag.to_a.each do |x|
                t << x[1]
            end
            tag[i] = t
        end
        return tag
    end

end
class Comment < DbHandler

    def self.get_all_for_post(id)
        get("*", nil, [["post_id", id]])
    end

    def self.create(content, creation_time, user_id, post_id, reply_to_id = 0)
        hash = {content: content, creation_time: creation_time, user_id: user_id, post_id: post_id, reply_to_id: reply_to_id}
        insert(hash)
    end

    def self.delete_at(id)
        delete([["comment.id", id]])
        delete([["reply_to_id", id]])
    end

end

class Post < DbHandler




    def self.join_tag
        return [["inner", "tagging", "post.id", "tagging.post_id"], ["inner", "tag", "tagging.tag_id", "tag.id"]]
    end

    def self.sort_comment(comment, reply_to_id)
        sorted_comment = []
        remaining_comment = []
        comment_ids = []
    
        comment.each_with_index do |comment, i|
            if comment_ids.include?(comment["c.id"])
                next
            else
                comment_ids << comment["c.id"]
            end
            if comment["c.reply_to_id"] == reply_to_id
                sorted_comment << comment   
            else
                remaining_comment << comment
            end  
        end
    
        sorted_comment.each_with_index do |comment, i|
            comment["comment"] = sort_comment(remaining_comment, comment["c.id"])
        end
    
        return sorted_comment
    end

    def self.top
        get("*", nil, nil, [["vote", "DESC"]])
    end
    def self.bottom
        get("*", nil, nil, [["vote", "ASC"]])
    end
    def self.newest
        get("*", nil, nil, [["id", "DESC"]])
    end
    def self.oldest
        get("*", nil, nil, [["id", "ASC"]])
    end
    
    def self.ordered(order_arr)
        get("post.id AS 'p.id', post.title, post.content, post.vote, post.creation_time, post.user_id", nil, nil, order_arr)
    end
    
    def self.with_tag(order_arr, tag)
        get("post.id AS 'p.id', post.title, post.content, post.vote, post.creation_time, post.user_id, tag.name", join_tag, [["tag.name", tag]], order_arr)
    end

    def self.get_with_tag(order, tag)
        order_arr = nil
        case order
        when "top"
            order_arr = [["vote", "DESC"]]
        when "newest"
            order_arr = [["post.id", "DESC"]]
        end

        if tag
            out = with_tag(order_arr, tag)
        else
            out = ordered(order_arr)
        end

    end
    

    def self.get_last_id()
        get("id", nil, nil, [["id", "DESC"]], 1)[0]["id"]
    end

    def self.create(title, content, creation_time, user_id, tag)
        hash = {title: title, content: content, creation_time: creation_time, user_id: user_id}
        
        connect.transaction
        insert(hash)

        post_id = get_last_id()
        connect.commit

        Tagging.add(tag, post_id)


    end

    def self.get_blank_with_tag_where(select, where1, where2)
        get(select, [["inner", "tagging", "post.id", "tagging.post_id"],["inner", "tag", "tagging.tag_id", "tag.id"]], [[where1, where2]])
    end

    def self.get_specific_by_id(id)
        get("post.id AS 'p.id', post.title AS 'p.title', post.content AS 'p.content', post.vote AS 'p.vote', post.creation_time AS 'p.creation_time', post.user_id AS 'p.user_id', comment.id AS 'c.id', comment.content AS 'c.content', comment.post_id AS 'c.post_id', comment.user_id AS 'c.user_id', comment.creation_time AS 'c.creation_time', comment.reply_to_id AS 'c.reply_to_id', poster.name AS 'p.name', poster.is_admin AS 'p.is_admin', commentor.name AS 'c.name', commentor.is_admin AS 'c.is_admin', tag.name AS 't.name'", [["left", "comment", "post.id", "comment.post_id"], ["left", "user AS 'poster'", "post.user_id", "poster.id"], ["left", "user AS 'commentor'", "comment.user_id", "commentor.id"], ["left", "tagging", "tagging.post_id", "post.id"], ["left", "tag", "tag.id", "tagging.tag_id"]],[["post.id", id]])
    end
    

    def self.get_sorted_by_id(id)
        data = get_specific_by_id(id)
        tag = []
        data.each do |x|
            # break if !tag.include?(x["t.name"])              # breaks if tag already exists in list(might not work if the comment are sorted in some way)
            tag << x["t.name"] if !tag.include?(x["t.name"])
        end
        if data[0]["c.id"] 
            sorted = sort_comment(data, 0)
            return sorted[0], sorted, tag
        else
            return data[0], [], tag
        end
    end

    def self.set_score(id, score)
        update({vote: score}, [["id", id]])
    end

    def self.delete_at(id)  
        delete([["post.id", id]])
        delete([["post_id", id]], "comment")
        delete([["post_id", id]], "tagging")
    end

end

class Tagging < DbHandler
    def self.add(tag_ids, post_id)
        connect.transaction
        tag_ids.each do |id|
            insert({"post_id" => post_id, "tag_id" => id})
        end
        connect.commit
    end
end

class Vote < DbHandler

    def self.change(post_id, user_id, score)

        data = get("user_id, post_id", nil, [["post_id", post_id],["user_id", user_id]])
        if data == []
            insert({post_id: post_id, user_id: user_id, score: score})
            p "insert"
        else
            p "update"
            update({post_id: post_id, user_id: user_id, score: score}, [["post_id", post_id],["user_id", user_id]])
        end

    end

    def self.increase(post_id, user_id)
        change(post_id, user_id, 1)
    end
    
    def self.decrease(post_id, user_id)
        change(post_id, user_id, -1)
    end
    
    def self.remove(post_id, user_id)
        change(post_id, user_id, 0)
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



# p Tag.get_all()
# p Post.get_last_id()

# p Vote.get_score(1)

# Post.delete_at(45)