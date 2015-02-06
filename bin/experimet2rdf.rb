require 'rdf'
require 'rdf/ntriples'
require 'rdf/turtle'
require 'mysql2'
include RDF


graph = RDF::Graph.new

#########################################################
#  define PREFIX
#########################################################
rdf = RDF::Vocabulary.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
rdfs = RDF::Vocabulary.new("http://www.w3.org/TR/rdf-schema/#")
owl = RDF::Vocabulary.new("http://www.w3.org/2002/07/owl#")
obo = RDF::Vocabulary.new("http://purl.obolibrary.org/obo/")
dc = RDF::Vocabulary.new("http://purl.org/dc/terms/")
#bao = RDF::Vocabulary.new("")
dbtsse = RDF::Vocabulary.new("http://dbtss.hgc.jp/rdf/experiment/")
dbtsso = RDF::Vocabulary.new("http://dbtss.hgc.jp/rdf/ontology/")
#faldo = RDF::Vocabulary.new("http://biohackathon.org/resource/faldo#")
#idorg = RDF::Vocabulary.new("http://info.identifiers.org/")
#efo = RDF::Vocabulary.new("http://www.ebi.ac.uk/efo/")
#sio = RDF::Vocabulary.new("http://semanticscience.org/resource/")
#edam = RDF::Vocabulary.new("http://edamontology.org/")
#up = RDF::Vocabulary.new("http://purl.uniprot.org/core/")
#upr = RDF::Vocabulary.new("http://purl.uniprot.org/uniprot/")
#tmo = RDF::Vocabulary.new("http://www.w3.org/2001/sw/hcls/ns/transmed/")
#ncit = RDF::Vocabulary.new("http://ncicb.nci.nih.gov/xml/owl/EVS/Thesaurus.owl#")
#ddbj = RDF::Vocabulary.new("http://ddbj.nig.ac.jp/ontologies/nucleotide/")

puts "@prefix rdf: <#{RDF::URI(rdf)}> ."
puts "@prefix rdfs: <#{RDF::URI(rdfs)}> ."
puts "@prefix dc: <#{RDF::URI(dc)}> ."
puts "@prefix dbtsse: <#{RDF::URI(dbtsse)}> ."
puts "@prefix dbtsso: <#{RDF::URI(dbtsso)}> ."

# retrieve experimental metadata
client = Mysql2::Client.new(:host => 'localhost', :username => 'dbtss', :password => 'dbtss', :database => 'dbtss')
experiments = client.query("SELECT * FROM experiments")

experiments.each do |exp|
  id = "TSE" + sprintf("%06d", exp["id"])
  type = exp["class"]
  type = exp["subclass"] unless exp["subclass"] == ""
  graph << [RDF::URI("http://dbtss.hgc.jp/rdf/experiment/#{id}"), RDF.type, dbtsso.Experiment]
  graph << [RDF::URI("http://dbtss.hgc.jp/rdf/experiment/#{id}"), dbtsso.experimentType, RDF::URI("http://dbtss.hgc.jp/rdf/ontology/#{type}")]
  graph << [RDF::URI("http://dbtss.hgc.jp/rdf/experiment/#{id}"), RDF::DC.identifier, id]
  graph << [RDF::URI("http://dbtss.hgc.jp/rdf/experiment/#{id}"), RDF::RDFS.label, exp["name"]]
  graph << [RDF::URI("http://dbtss.hgc.jp/rdf/experiment/#{id}"), dbtsso.version, "9"]
  graph << [RDF::URI("http://dbtss.hgc.jp/rdf/experiment/#{id}"), dbtsso.resource, exp["name"]]
end

puts graph.dump(:turtle)