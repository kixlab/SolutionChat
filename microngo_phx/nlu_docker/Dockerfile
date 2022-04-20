FROM ubuntu:latest
RUN apt-get update -y
RUN apt-get install -y git
RUN apt-get install -y python3 python3-pip
RUN apt-get install -y build-essential libssl-dev libffi-dev
RUN DEBIAN_FRONTEND="noninteractive" TZ="America/New_York" apt-get -y install tzdata
RUN apt-get install -y cmake
WORKDIR /root
RUN git clone https://github.com/kakao/khaiii.git
WORKDIR /root/khaiii
RUN mkdir build
WORKDIR /root/khaiii/build
RUN CXXFLAGS="-Wno-error=deprecated-copy" cmake ..
RUN make all
RUN make resource
RUN make large_resource
RUN make install
RUN make package_python
WORKDIR /root/khaiii/build/package_python
RUN pip3 install .
RUN apt-get install -y curl
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN pip3 install setuptools
RUN pip3 install snips-nlu
RUN python3 -m snips_nlu download en
RUN python3 -m snips_nlu download ko
RUN python3 -m pip install Flask
RUN apt-get install -y locales
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8
WORKDIR /root
RUN mkdir nlu
COPY ./nlu /root/nlu
WORKDIR /root/nlu
RUN chmod 755 run.sh
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
EXPOSE 5000/tcp
RUN chmod 755 ./run.sh
ENTRYPOINT "./run.sh"