FROM dynverse/dynwrap:bioc

LABEL version 0.1.2

RUN apt-get install -y libgsl-dev

RUN R -e 'devtools::install_cran("cellTree")'

ADD . /code

ENTRYPOINT Rscript /code/run.R
