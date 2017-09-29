#!/usr/bin/env nextflow

params.bam = "bam/*.bam" 
params.type = "groups.txt"
params.output = "results"

bamset = Channel
	.fromPath(params.bam)
	.map { file -> [ name:file.baseName, file:file]} 
	 

groupInfo = Channel
	.fromPath(params.type)
	.splitCsv()
	.map { row -> [ name:row[0],group:row[1] ] }


comb = bamset.phase(groupInfo) {it -> it.name}
	.map { it -> tuple( it.group[1], it.file[0])}
	.groupTuple(by:0)
	


process mergeBams {
publishDir "$params.output", mode: 'copy'
tag "group: $group"

	input:
	set group, file(ff) from comb

	output:
	file("${group}.merged.bam") 

	script:
	"""
	samtools merge ${group}.merged.bam ${ff.collect { it }.join(' ')}
	"""
}




workflow.onComplete { 
	println ( workflow.success ? "Done!" : "Oops .. something went wrong" )
}




