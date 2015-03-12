#require 'optparse'
require 'mysql2'

db   = ARGV[0] || "dbtss"
user = ARGV[1] || "dbtss"
pass = ARGV[2] || "dbtss"
pfix = ARGV[3] || "http://dbtss.hgc.jp/rdf/"

map_file = File.open("ontology/ontop_dbtss.obda", "w")
ontology = File.open("ontology/ontop_dbtss.owl", "w")

client = Mysql2::Client.new(:host => 'localhost', :username => user, :password => pass, :database => db)



# [PrefixDeclaration]
map_file.puts "[PrefixDeclaration]
:\t\t#{pfix}ontology#
xsd:\t\thttp://www.w3.org/2001/XMLSchema#
owl:\t\thttp://www.w3.org/2002/07/owl#
rdf:\t\thttp://www.w3.org/1999/02/22-rdf-syntax-ns#
rdfs:\t\thttp://www.w3.org/TR/rdf-schema/#\n\n"


# [SourceDeclaration]
map_file.puts "[SourceDeclaration]
sourceUri       dbtss-connection
connectionUrl   jdbc:mysql://localhost:3306/#{db}
username        #{user}
password        #{pass}
driverClass     com.mysql.jdbc.Driver\n\n"


# [MappingDeclaration]
mappings   = Array.new
classes    = Array.new
properties = Array.new

client.query("SHOW tables").each do |table|
  table = table['Tables_in_dbtss']
  classes << table
  
  unless table == "group_id2refseq" || table == "refGene_9606"
  id = ""
  client.query("SHOW COLUMNS FROM #{table}").each do |col|
    #p col
    map = ""
    if col["Key"] == "PRI"
      id   = col['Field']
      map  = "mappingId\t#{table} #{id}\n"
      map += "target\t\t<#{pfix}/ontology##{table}/{#{id}}> a :#{table} .\n"
      map += "source\t\tSELECT #{id} FROM #{table}\n"
      mappings << map
    else
      field = col["Field"]
      properties << field
      
      map  = "mappingId\t#{table} #{field}\n"
      map += "target\t\t<#{pfix}/ontology##{table}/{#{id}}> :#{field} {#{field}} .\n"
      map += "source\t\tSELECT #{id},#{field} FROM #{table}\n"
      mappings << map
    end
  end
end
end


map_file.puts "[MappingDeclaration] @collection [["
map_file.puts mappings.join("\n")
map_file.puts "]]"


ontology.puts "<?xml version=\"1.0\"?>
<!DOCTYPE rdf:RDF [
   <!ENTITY owl \"http://www.w3.org/2002/07/owl#\" >
   <!ENTITY xsd \"http://www.w3.org/2001/XMLSchema#\" >
   <!ENTITY rdf \"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" >
   <!ENTITY rdfs \"http://www.w3.org/2000/01/rdf-schema#\" >
]>
<rdf:RDF xmlns=\"http://dbtss.hgc.jp/rdf/ontology#\"
    xml:base=\"http://dbtss.hgc.jp/rdf/ontology\"
    xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\"
    xmlns:owl=\"http://www.w3.org/2002/07/owl#\"
    xmlns:xsd=\"http://www.w3.org/2001/XMLSchema#\"
    xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">
   <owl:Ontology rdf:about=\"http://dbtss.hgc.jp/rdf/ontology\"/>"

properties = properties.sort.uniq
properties.each do |prop|
  ontology.puts "   <owl:DatatypeProperty rdf:about=\"http://dbtss.hgc.jp/rdf/ontology##{prop}\"/>"
end

classes.each do |c|
  ontology.puts "   <owl:Class rdf:about=\"http://dbtss.hgc.jp/rdf/ontology##{c}\"/>"
end

ontology.puts "</rdf:RDF>"


map_file.close
ontology.close
