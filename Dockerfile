FROM python:3.8-buster

# Base packages

RUN apt-get update&& \
    apt-get -y install graphviz build-essential python-dev ffmpeg fish
    
RUN pip install --upgrade pip

# Install jupyter notebook
RUN pip3 install jupyter jupyterlab

# Install viz dependencies
RUN pip3 install matplotlib ipyvolume seaborn

# Lock to datajoint 0.12.9
RUN pip3 install datajoint==0.12.9

# Install the outside packages
WORKDIR /src
COPY README.md /microns-nda-access/.
COPY Dockerfile /microns-nda-access/.
COPY docker-compose.yml /microns-nda-access/.
RUN git clone https://github.com/cajal/21617_data_release
RUN pip3 install torch==1.9.0+cpu torchvision==0.10.0+cpu torchaudio==0.9.0 -f https://download.pytorch.org/whl/torch_stable.html
#RUN pip3 install torch==1.8.1
RUN pip3 install -e 21617_data_release/
RUN pip3 install git+https://github.com/AllenInstitute/em_coregistration.git@phase3

# Set up work environment
WORKDIR /notebooks
COPY README.md .
RUN mkdir tutorials/ && cp -r /src/21617_data_release/tutorial_notebooks/. tutorials/.
RUN mkdir workspace/

# Start jupyter notebook
RUN mkdir -p /scripts \
    && mkdir -p /root/.jupyter/custom/

# The configuration files are placed here to avoid more file dependencies. Quite messy, but should work the same.

RUN echo "#!/usr/bin/env bash \n\
\n\
jupyter lab --ip='0.0.0.0' --port=8888 --allow-root --no-browser --ServerApp.token=''\n"\
>> /scripts/run_jupyter.sh

RUN echo ".container { \n\
    width: 75% !important; \n\
} \n\
\n\
div.cell.selected { \n\
    border-left-width: 1px !important; \n\
} \n\
\n\
div.output_scroll { \n\
    resize: vertical !important; \n\
}\n" \
>> /root/.jupyter/custom/custom.css

RUN chmod -R a+x /scripts
ENTRYPOINT ["/scripts/run_jupyter.sh"]
