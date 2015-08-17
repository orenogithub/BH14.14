require 'rdf'
require 'rdf/ntriples'
require 'rdf/turtle'
#require 'mysql2'
include RDF

file   = ARGV[0] || "sample/LC2ad_snv_reduce.vcf"
sample = ARGV[1] || "TSE000086"


#########################################################
#  define PREFIX
#########################################################
rdf     = RDF::Vocabulary.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
rdfs    = RDF::Vocabulary.new("http://www.w3.org/2000/01/rdf-schema#")
owl     = RDF::Vocabulary.new("http://www.w3.org/2002/07/owl#")
obo     = RDF::Vocabulary.new("http://purl.obolibrary.org/obo/")
dc      = RDF::Vocabulary.new("http://purl.org/dc/terms/")
dbtsse  = RDF::Vocabulary.new("http://dbtss.hgc.jp/rdf/experiment/")
dbtsso  = RDF::Vocabulary.new("http://dbtss.hgc.jp/rdf/ontology/")
faldo   = RDF::Vocabulary.new("http://biohackathon.org/resource/faldo#")
dbsnp   = RDF::Vocabulary.new("http://info.identifiers.org/dbsnp/")
ncbisnp = RDF::Vocabulary.new("http://www.ncbi.nlm.nih.gov/projects/SNP/snp_ref.cgi?rs=")
ensemblvariation = RDF::Vocabulary.new("https://github.com/simonjupp/ensembl-rdf/blob/master/ontology/ensembl_variation_ontology.owl#")
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
puts "@prefix owl: <#{RDF::URI(owl)}> ."
puts "@prefix obo: <#{RDF::URI(obo)}> ."
puts "@prefix dc: <#{RDF::URI(dc)}> ."
puts "@prefix dbtsse: <#{RDF::URI(dbtsse)}> ."
puts "@prefix dbtsso: <#{RDF::URI(dbtsso)}> ."
puts "@prefix faldo: <#{RDF::URI(faldo)}> ."
puts "@prefix dbsnp: <#{RDF::URI(dbsnp)}> ."
puts "@prefix ncbisnp: <#{RDF::URI(ncbisnp)}> ."
puts "@prefix ensembl: <#{RDF::URI(ensemblvariation)}> ."

File.open(file).each do |line|
  unless line =~ /^#/
    graph = RDF::Graph.new
    
    chrom, pos, id, ref, alt, qual, filter, info, format, value = line.chomp.split("\t")
    chrom = chrom.delete("c\.fa")
    
    experiment = RDF::URI("http://dbtss.hgc.jp/rdf/experiment/#{sample}")
    subject    = RDF::URI("http://dbtss.hgc.jp/rdf/data/#{sample}/#{chrom}:#{pos}")
    
    graph << [experiment, dbtsso.has_SNV, subject]
    graph << [subject, RDF.type, obo.SO_0001483]
    graph << [subject, DC.identifier, "#{chrom}:#{pos}"]
    graph << [subject, RDFS.label, "variation on chr#{chrom}:#{pos} from #{sample}"]
    
    if id =~ /^rs\d+/
      graph << [subject, RDFS.seeAlso, RDF::URI("http://info.identifiers.org/dbsnp/#{id}")]
      graph << [subject, RDFS.seeAlso, RDF::URI("http://www.ncbi.nlm.nih.gov/projects/SNP/snp_ref.cgi?rs=#{id}")]
      graph << [subject, dbtsso.dbsnpID, id]
    end
    
    
    # FALDO
    faldo_region    = RDF::URI("http://dbtss.hgc.jp/rdf/location/chromosome:GRCh38:#{chrom}:#{pos}-#{pos}:1")
    faldo_position  = RDF::URI("http://dbtss.hgc.jp/rdf/location/chromosome:GRCh38:#{chrom}:#{pos}:1")
    faldo_reference = RDF::URI("http://dbtss.hgc.jp/rdf/location/chromosome:GRCh38:#{chrom}")

    graph << [subject, faldo.location, faldo_region]
    graph << [faldo_region, RDF.type, faldo.Region]
    graph << [faldo_region, DC.identifier, "chromosome:GRCh38:#{chrom}:#{pos}-#{pos}:1"]
    graph << [faldo_region, RDFS.label, "GRCh38 chr#{chrom}:#{pos}-#{pos} Forward"]
    graph << [faldo_region, faldo.begin, faldo_position]
    graph << [faldo_region, faldo.end, faldo_position]
    graph << [faldo_region, faldo.reference, faldo_reference]
    
    graph << [faldo_position, RDF.type, faldo.ExactPosition]
    graph << [faldo_position, RDF.type, faldo.ForwardStrandPosition]
    graph << [faldo_position, DC.identifier, "chromosome:GRCh38:#{chrom}:#{pos}:1"]
    graph << [faldo_position, RDFS.label, "GRCh38 chr#{chrom}:#{pos} Forward"]
    graph << [faldo_position, faldo.position, pos.to_i]
    graph << [faldo_position, faldo.reference, faldo_reference]
    
    
    # Allele
    ref_allele = RDF::URI(subject + "#" + ref)
    alt_allele = RDF::URI(subject + "#" + alt)
    
    graph << [subject, ensemblvariation.has_allele, ref_allele]
    graph << [ref_allele, RDF.type, ensemblvariation.reference_allele]
    graph << [ref_allele, RDF.type, ensemblvariation.ancestral_allele]
    graph << [ref_allele, DC.identifier, "#{chrom}:#{pos}##{ref}"]
    graph << [ref_allele, RDFS.label, "#{sample} chr#{chrom}:#{pos} allele #{ref}"]

    graph << [subject, ensemblvariation.has_allele, alt_allele]
    graph << [alt_allele, RDF.type, ensemblvariation.derived_allele]
    graph << [alt_allele, DC.identifier, "#{chrom}:#{pos}##{alt}"]
    graph << [alt_allele, RDFS.label, "#{sample} chr#{chrom}:#{pos} allele #{alt}"]
    
    
    # others
    graph << [subject, dbtsso.quality, qual.to_f]
    graph << [subject, dbtsso.filter, filter] unless filter == "."
    
    
    # info
    graph << [subject, dbtsso.additionalInfomation, info]
    
    information = Hash.new
    info.split(";").each do |i|
      k, v = i.split("=")
      information[k] = v
    end
    
    graph << [subject, dbtsso.alleleFrequency, information["AF"].to_f] if information["AF"]
    
    
    # format
    graph << [subject, dbtsso.genotypeData, "#{format}|#{value}"]
    
    format = format.split(":")
    value  = value.split(":")
    detail = Hash.new
    format.length.times do |i|
      detail[format[i]] = value[i]
    end
    
    graph << [subject, dbtsso.allelicDepths, detail["AD"]] if detail["AD"]
    graph << [subject, dbtsso.genotype, detail["GT"]] if detail["GT"]
    graph << [subject, dbtsso.genotypeQuality, detail["GQ"].to_f] if detail["GQ"]
    
    graph = graph.dump(:ttl, prefixes:
    {
      rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      rdfs: "http://www.w3.org/2000/01/rdf-schema#",
      obo: "http://purl.obolibrary.org/obo/",
      dc: "http://purl.org/dc/terms/",
      dbtsse: "http://dbtss.hgc.jp/rdf/experiment/",
      dbtsso: "http://dbtss.hgc.jp/rdf/ontology/",
      faldo: "http://biohackathon.org/resource/faldo#",
      dbsnp: "http://info.identifiers.org/dbsnp/",
      ncbisnp: "http://www.ncbi.nlm.nih.gov/projects/SNP/snp_ref.cgi?rs=",
      ensemblvariation: "https://github.com/simonjupp/ensembl-rdf/blob/master/ontology/ensembl_variation_ontology.owl#"
    })
    puts graph.gsub(/^@.+\n/, "")
    graph.clear
  end
end

