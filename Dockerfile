FROM dynverse/dynwrap:bioc

RUN apt-get install -y libgsl-dev

RUN R -e 'devtools::install_cran("cellTree")'

LABEL version 0.1.5

ADD . /code

ENTRYPOINT Rscript /code/run.R
