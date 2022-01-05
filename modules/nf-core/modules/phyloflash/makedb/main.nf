// Import generic module functions
include { get_resources; initOptions; saveFiles } from '../../../../lib/nf/functions'
RESOURCES   = get_resources(workflow.profile, params.max_memory, params.max_cpus)
options     = initOptions(params.options ? params.options : [:], 'phyloflash_makdb')
publish_dir = params.is_subworkflow ? "${params.outdir}/bactopia-tools/${params.wf}/${params.run_name}" : params.outdir

process MAKEDB {
    tag "$meta.id"
    label 'process_low'
    publishDir "${publish_dir}/${meta.id}", mode: params.publish_dir_mode, overwrite: params.force,
        saveAs: { filename -> saveFiles(filename:filename, opts:options) }

    conda (params.enable_conda ? "bioconda::agrvate=1.0.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/agrvate:1.0.1--hdfd78af_2' :
        'quay.io/biocontainers/agrvate:1.0.1--hdfd78af_2' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta.id}-summary.tab"), emit: summary
    path "results/", emit: results_dir
    path "*.{stdout.txt,stderr.txt,log,err}", emit: logs, optional: true
    path ".command.*", emit: nf_logs
    path "versions.yml",emit: versions

    script:
    def prefix = options.suffix ? "${options.suffix}" : "${meta.id}"
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    #TODO

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        phyloFlash: \$(echo \$(phyloFlash.pl -version 2>&1) | sed "s/^.*phyloFlash v//")
    END_VERSIONS
    """
}
