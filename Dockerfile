FROM rstudio/plumber
ARG R_PLUMBER_HOME
RUN mkdir ${R_PLUMBER_HOME}
RUN R -e "install.packages('tidyverse')"
ENV TZ=Asia/Tokyo
