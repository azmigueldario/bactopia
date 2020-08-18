#!/bin/bash
set -e
set -u

if [ "!{params.dry_run}" == "true" ]; then
    mkdir -p annotation
    touch annotation/!{sample}.gbk
else
    if [[ !{params.compress} == "true" ]]; then
        gunzip -f !{fasta}
    fi

    if [ "!{renamed}" == "true" ]; then
        echo "Original sample name (!{sample}) not used due to creating a contig ID >37 characters"
    fi

    prokka --outdir annotation \
        --force \
        --prefix '!{sample}' \
        --genus '!{genus}' \
        --species '!{species}' \
        --evalue '!{params.prokka_evalue}' \
        --coverage !{params.prokka_coverage} \
        --cpus !{task.cpus} \
        --centre '!{params.centre}' \
        --mincontiglen !{params.min_contig_len} \
        !{locustag} \
        !{prodigal} \
        !{addgenes} \
        !{compliant} \
        !{proteins} \
        !{rawproduct} \
        !{cdsrnaolap} \
        !{addmrna} \
        !{norrna} \
        !{notrna} \
        !{rnammer} \
        !{rfam} \
        !{gunzip_fasta}

    if [[ !{params.compress} == "true" ]]; then
        find annotation/ -type f -not -name "*.txt" -and -not -name "*.log*" | \
            xargs -I {} pigz -n --best -p !{task.cpus} {}
    fi
fi
