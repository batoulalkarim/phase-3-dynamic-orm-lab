require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
    #creates a downcased plural table based on class name
    def self.table_name
        self.to_s.downcase.pluralize
    end

    #returns an array of sql column names 
    def self.column_names
        sql = "pragma table_info('#{table_name}')"

        table_info = DB[:conn].execute(sql)
        column_names = []
        table_info.each do |row|
            column_names << row["name"]
        end
        column_names.compact
    end

    #creates new instance of student with attributes
    def initialize(options={})
    options.each do |property, value|
        self.send("#{property}=", value)
        end
    end

    #return table name when called on an instance of student
    def table_name_for_insert 
        self.class.table_name
    end

    #return column name when called on an instance of student and does not include an id column
    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    #formats column names to be used in sql statement
    def values_for_insert
        values = []
        self.class.column_names.each do |col_name|
            values << "'#{send(col_name)}'" unless send(col_name).nil?
        end
        values.join(", ")
    end

    #saves student to db and sets student id
    def save 
        sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    #find a row by name
    def self.find_by_name(name)
        sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
        DB[:conn].execute(sql, name)
    end


    #finds a row by the att passed into method, accounts for if value is integer
    def self.find_by(attribute_hash)
        value = attribute_hash.values.first
        formatted_value = value.class == Fixnum ? value : "'#{value}'"
        sql = "SELECT * FROM #{self.table_name} WHERE #{attribute_hash.keys.first} = #{formatted_value}"
        DB[:conn].execute(sql)
    end
end