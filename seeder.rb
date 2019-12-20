require 'sqlite3'

class Seeder

    def self.seed
        db = connect
        drop_tables(db)
        create_tables(db)
        populate_tables(db)
    end

    def self.connect
        SQLite3::Database.new 'db/db.db'
    end

    def self.drop_tables(db)
        db.execute('DROP TABLE IF EXISTS users;')
        db.execute('DROP TABLE IF EXISTS posts;')
        db.execute('DROP TABLE IF EXISTS comments;')
        db.execute('DROP TABLE IF EXISTS comment_comments;')
        db.execute('DROP TABLE IF EXISTS tags;')
        db.execute('DROP TABLE IF EXISTS taggings;')
    end

    def self.create_tables(db)

        db.execute <<-SQL
            CREATE TABLE "users" (
                "id"	INTEGER,
                "name"	TEXT NOT NULL UNIQUE,
                "pwd_hash"	TEXT NOT NULL,
                "creation_time"	TEXT NOT NULL,
                "is_admin"	INTEGER NOT NULL DEFAULT 0,
                PRIMARY KEY("id")
            );
        SQL

        db.execute <<-SQL
            CREATE TABLE "posts" (
                "id"	INTEGER,
                "title"	TEXT NOT NULL,
                "content"	TEXT,
                "votes"	INTEGER NOT NULL DEFAULT 0,
                "creation_time"	TEXT NOT NULL,
                "user_id"	INTEGER NOT NULL,
                PRIMARY KEY("id")
                );
                SQL
            
        db.execute <<-SQL
            CREATE TABLE "comments" (
                "id"	INTEGER,
                "content"	TEXT NOT NULL,
                "post_id"	INTEGER NOT NULL,
                "user_id"	INTEGER NOT NULL,
                "creation_time"	TEXT NOT NULL,,
                "reply_to_id"	INTEGER,
                PRIMARY KEY("id")
                );
                SQL
                

        db.execute <<-SQL
            CREATE TABLE "tags" (
                "id"	INTEGER,
                "name"	TEXT NOT NULL UNIQUE,
                PRIMARY KEY("id")
            );
        SQL

        db.execute <<-SQL
            CREATE TABLE "taggings" (
                "post_id"	INTEGER NOT NULL,
                "tag_id"	INTEGER NOT NULL
            );
        SQL

        db.execute <<-SQL
        CREATE TABLE "votes" (
            "user_id"	INTEGER NOT NULL,
            "post_id"	INTEGER NOT NULL,
            "score"	INTEGER NOT NULL
        )
        SQL
    end

    def self.populate_tables(db)
        
        users = [
            {name: "Kalle", pwd_hash: "555-1234", creation_time: "time"},
            {name: "Lisa", pwd_hash: "555-2345", creation_time: "time"},
            {name: "Gunnar", pwd_hash: "555-3456", creation_time: "time"},
            {name: "Wolfgang", pwd_hash: "555-4567", creation_time: "time"}
        ]
            
        posts = [
            {title: "Coke 33cl", content: "hello", votes: 25, user_id: 1, creation_time: "time"},
            {title: "Fanta 33cl", content: "hello", votes: 25, user_id: 2, creation_time: "time"},
            {title: "Sprite 33cl", content: "hello", votes: 25, user_id: 2, creation_time: "time"},
            {title: "Salta Nappar", content: "hello", votes: 15, user_id: 3, creation_time: "time"},
            {title: "Colanappar", content: "hello", votes: 15, user_id: 3, creation_time: "time"},
            {title: "Ahlgrens Bilar", content: "hello", votes: 15, user_id: 4, creation_time: "time"},
            {title: "Snickers", content: "hello", votes: 10, user_id: 4, creation_time: "time"},
            {title: "Twix", content: "hello", votes: 10, user_id: 4, creation_time: "time"},
            {title: "Mars", content: "hello", votes: 10, user_id: 4, creation_time: "time"}  
        ]

        comments = [
            {content: "Origovägen 4", post_id: 1, user_id: 1},
            {content: "Sven Hultins Gata 9C", post_id: 1, user_id: 1},
            {content: "Röntgenvägen 9", post_id: 2, user_id: 2},
            {content: "Grillkorvsgränd 3", post_id: 5, user_id: 4},
            {content: "Wavrinskys plats", post_id: 3, user_id: 2}
        ]

        comment_comments = [
            {content: "vägen 4", post_id: 1, comment_id: 1, user_id: 1},
            {content: "Sven Hultins Gata 9C", post_id: 1, comment_id: 2, user_id: 1},
            {content: "Röntgenvägen 9", post_id: 2, comment_id: 1, user_id: 1},
            {content: "Grillkorvsgränd 3", post_id: 5, comment_id: 1, user_id: 3},
            {content: "Wavrinskys plats", post_id: 3, comment_id: 1, user_id: 2}
        ]

        taggings = [
            {post_id: 1, tag_id: 1},
            {post_id: 1, tag_id: 2},
            {post_id: 1, tag_id: 3},
            {post_id: 4, tag_id: 2},
            {post_id: 2, tag_id: 2},
            {post_id: 5, tag_id: 2}
        ]

        tags = [
            {name: "minecraft"},
            {name: "furries"},
            {name: "Adrian"},
            {name: "Sqlite"}
        ]


        
        users.each do |d| 
            db.execute("INSERT INTO users (name, pwd_hash, creation_time) VALUES(?,?,?)", d[:name], d[:pwd_hash], d[:creation_time])
        end        

        posts.each do |post| 
            db.execute("INSERT INTO posts (title, votes, user_id, content, creation_time) VALUES(?,?,?,?,?)", post[:title], post[:votes], post[:user_id], post[:content], post[:creation_time])
        end

        comments.each do |m| 
            db.execute("INSERT INTO comments (content, post_id, user_id) VALUES(?,?,?)", m[:content], m[:post_id], m[:user_id])
        end
        
        comment_comments.each do |m| 
            db.execute("INSERT INTO comment_comments (content, post_id, comment_id, user_id) VALUES(?,?,?,?)", m[:content], m[:post_id], m[:comment_id], m[:user_id])
        end
        
        taggings.each do |m| 
            db.execute("INSERT INTO taggings (post_id, tag_id) VALUES(?,?)", m[:post_id], m[:tag_id])
        end
        
        tags.each do |m| 
            db.execute("INSERT INTO tags (name) VALUES(?)", m[:name])
        end


    end

end

# Seeder.seed