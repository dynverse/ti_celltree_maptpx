FROM dynverse/dynwrap:bioc

RUN apt-get update && apt-get install -y libgsl-dev

RUN R -e 'devtools::install_cran("cellTree")'

LABEL version 0.1.5.1

ADD . /code

ENTRYPOINT Rscript /code/run.R
