#!/bin/bash

echo "install compilation tools and dependencies"
echo "Begining..."
apt-get update -qq
apt-get install -y git nano \
   python3 python3-pip fuse psmisc pkg-config libattr1-dev libfuse-dev libsqlite3-dev libjs-sphinxdoc \
   texlive-latex-base texlive-latex-recommended texlive-latex-extra texlive-generic-extra \
   texlive-fonts-recommended
pip3 install https://github.com/rogerbinns/apsw/releases/download/3.8.2-r1/apsw-3.8.2-r1.zip
pip3 install cython==0.24.1 sphinx pycrypto defusedxml requests "llfuse >= 1.0, < 2.0" "dugong >= 3.4, < 4.0" "pytest >= 2.7" \
    pytest-catchlog prometheus_client
pip3 install --upgrade google-api-python-client
echo "download s3ql code"
git clone https://github.com/segator/s3ql.git -b gdrive
cd s3ql
echo "compile s3ql"
python3 setup.py build_cython
python3 setup.py build_ext --inplace

echo "install s3ql"
python3 setup.py install

echo "cleanup compilations tools"
apt-get remove --purge -y git
apt autoremove -y && apt autoclean -y && apt clean -y
rm -rf /var/lib/apt/lists/*