FROM python:2.7.14-stretch
MAINTAINER GeoNode development team

RUN mkdir -p /usr/src/sc

WORKDIR /usr/src/sc

RUN apt-get update && apt-get install -y \
		gcc \
		gettext \
		postgresql-client libpq-dev \
		sqlite3 \
                python-gdal python-psycopg2 \
                python-imaging python-lxml \
                python-dev libgdal-dev \
                python-ldap \
                libmemcached-dev libsasl2-dev zlib1g-dev \
                python-pylibmc \
                uwsgi uwsgi-plugin-python \
	--no-install-recommends && rm -rf /var/lib/apt/lists/*

# python-gdal does not seem to work, let's replace it by pygdal
RUN GDAL_VERSION=`gdal-config --version` \
    && PYGDAL_VERSION="$(pip install pygdal==$GDAL_VERSION 2>&1 | grep -oP '(?<=: )(.*)(?=\))' | grep -oh $GDAL_VERSION\.[0-9])" \
    && pip install pygdal==$PYGDAL_VERSION

# fix for known bug in system-wide packages
RUN ln -fs /usr/lib/python2.7/plat-x86_64-linux-gnu/_sysconfigdata*.py /usr/lib/python2.7/

# app-specific requirements
COPY requirements.txt /usr/src/sc/
RUN pip install --upgrade --no-cache-dir --src /usr/src -r requirements.txt

# This should be close to the last step in order to avoid rebuilding image during development.
COPY . /usr/src/sc
RUN pip install --no-deps --upgrade -e .

RUN chmod +x /usr/src/sc/tasks.py \
    && chmod +x /usr/src/sc/entrypoint.sh

COPY wait-for-databases.sh /usr/bin/wait-for-databases
RUN chmod +x /usr/bin/wait-for-databases

ENTRYPOINT ["/usr/src/sc/entrypoint.sh"]
