require 'rdf'
require 'rdf/ntriples'
require 'rdf/turtle'
#require 'mysql2'
include RDF

file = ARGV[0] || "sample/DBTSS_definition.tsv"

#########################################################
#  define PREFIX
#########################################################
rdf = RDF::Vocabulary.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
rdfs = RDF::Vocabulary.new("http://www.w3.org/TR/rdf-schema/#")
owl = RDF::Vocabulary.new("http://www.w3.org/2002/07/owl#")
obo = RDF::Vocabulary.new("http://purl.obolibrary.org/obo/")
dc = RDF::Vocabulary.new("http://purl.org/dc/terms/")
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

graph = RDF::Graph.new

File.open(file).each do |line|
  id, name, type, a_num, dist, cat_num, ethnicity, gender, age, smoking, medium, dish, exp_class, subclass = line.chomp.split("\t")

  id = "TSE" + sprintf("%06d", id)
  exp_class = subclass if subclass
  
  graph << [RDF::URI("http://dbtss.hgc.jp/rdf/experiment/#{id}"), RDF.type, dbtsso.Experiment]
  graph << [RDF::URI("http://dbtss.hgc.jp/rdf/experiment/#{id}"), dbtsso.experimentType, RDF::URI("http://dbtss.hgc.jp/rdf/ontology/#{exp_class}")]
  graph << [RDF::URI("http://dbtss.hgc.jp/rdf/experiment/#{id}"), RDF::DC.identifier, id]
  graph << [RDF::URI("http://dbtss.hgc.jp/rdf/experiment/#{id}"), RDF::RDFS.label, name]
  graph << [RDF::URI("http://dbtss.hgc.jp/rdf/experiment/#{id}"), dbtsso.version, "9"]
  graph << [RDF::URI("http://dbtss.hgc.jp/rdf/experiment/#{id}"), dbtsso.resource, RDF::URI("http://dbtss.hgc.jp/rdf/sample/#{name}")]
end

puts graph.dump(:turtle)
