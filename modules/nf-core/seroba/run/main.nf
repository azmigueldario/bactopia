// Import generic module functions
include { get_resources; initOptions; saveFiles } from '../../../../lib/nf/functions'
RESOURCES   = get_resources(workflow.profile, params.max_memory, params.max_cpus)
options     = initOptions(params.options ? params.options : [:], 'seroba')
publish_dir = params.is_subworkflow ? "${params.outdir}/bactopia-tools/${params.wf}/${params.run_name}" : params.outdir
conda_tools = "bioconda::seroba=1.0.2"
conda_name  = conda_tools.replace("=", "-").replace(":", "-").replace(" ", "-")
conda_env   = file("${params.condadir}/${conda_name}").exists() ? "${params.condadir}/${conda_name}" : conda_tools

process SEROBA_RUN {
    tag "$meta.id"
    label 'process_low'
    publishDir "${publish_dir}/${meta.id}", mode: params.publish_dir_mode, overwrite: params.force,
        saveAs: { filename -> saveFiles(filename:filename, opts:options) }

    conda (params.enable_conda ? conda_env : null)
    container "${ workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seroba:1.0.2--pyhdfd78af_1' :
        'quay.io/biocontainers/seroba:1.0.2--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(reads)

    when:
    meta.single_end == false

    output:
    tuple val(meta), path("results/${prefix}.tsv")                              , emit: tsv
    tuple val(meta), path("results/detailed_serogroup_info.txt"), optional: true, emit: txt
    path "*.{log,err}"                                            , optional: true, emit: logs
    path ".command.*"                                                             , emit: nf_logs
    path "versions.yml"                                                           , emit: versions

    script:
    prefix = options.suffix ? "${options.suffix}" : "${meta.id}"
    """
    seroba \\
        runSerotyping \\
        $reads \\
        results $options.args

    # Avoid name collisions
    mv results/pred.tsv results/${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seroba: \$(seroba version)
    END_VERSIONS
    """
}
