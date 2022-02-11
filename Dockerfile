FROM openanalytics/r-base:3.6.1

# apt
# COPY aliyun.txt /etc/apt/sources.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 51716619E084DAB9 && \
    apt-get update && \
    apt-get install -y \
    libcurl4-openssl-dev \
    libssh2-1-dev \
    libxml2-dev \
    libssl-dev \
    python3-dev \
    samtools \
    tabix \
    wget && \
    apt-get clean && \
    apt-get purge && \
    apt autoremove -y && \
    rm -rf /var/lib/apt/list/*

# install scarHRD
# scarHRD auto install sequenza v3.0 which can not be used in scarHRD pipeline
RUN Rscript -e 'install.packages("devtools")' -e 'if (!library(devtools, logical.return=T)) quit(status=10)'
RUN Rscript -e 'install.packages("BiocManager")' && \
    Rscript -e 'BiocManager::install("copynumber")' -e 'if (!library(copynumber, logical.return=T)) quit(status=10)' && \
    Rscript -e 'devtools::install_github("cgh2/scarHRD")' -e 'if (!library(scarHRD, logical.return=T)) quit(status=10)'

# install sequenza v2.1.2
RUN Rscript -e 'install.packages("https://bitbucket.org/sequenzatools/sequenza/get/v2.1.2.tar.gz")' && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py && \
    pip install sequenza-utils==2.1.9999b0

# install TITAN
WORKDIR /software
RUN Rscript -e 'install.packages("https://cran.r-project.org/src/contrib/Archive/bit/bit_1.1-15.2.tar.gz")' && \
    Rscript -e 'install.packages("https://cran.r-project.org/src/contrib/Archive/bit64/bit64_0.9-7.1.tar.gz")' && \
    Rscript -e 'install.packages("https://cran.r-project.org/src/contrib/Archive/ff/ff_2.2-14.tar.gz")' && \
    Rscript -e 'BiocManager::install("oligoClasses")' && \
    Rscript -e 'BiocManager::install("SNPchip")'
RUN Rscript -e 'devtools::install_github("gavinha/TitanCNA")' && \
    Rscript -e 'install.packages("optparse")' && \
    Rscript -e 'install.packages("doMC")' && \
    mkdir TitanCNA && \
    cd TitanCNA && \
    wget https://github.com/gavinha/TitanCNA/raw/master/scripts/R_scripts/README.md && \
    wget https://github.com/gavinha/TitanCNA/raw/master/scripts/R_scripts/selectSolution.R && \
    wget https://github.com/gavinha/TitanCNA/raw/master/scripts/R_scripts/titanCNA.R

# install runScarHRD
COPY runScarHRD.py /software/scarHRD/runScarHRD.py
RUN ln -s /software/scarHRD/runScarHRD.py /usr/bin/scarHRD && \
    chmod +x /software/scarHRD/runScarHRD.py

# running environment
WORKDIR /data
RUN chmod +x /software/TitanCNA/titanCNA.R && \
    chmod +x /software/TitanCNA/selectSolution.R
ENV PATH="/software/TitanCNA:${PATH}"
CMD ["scarHRD", "-h"]
