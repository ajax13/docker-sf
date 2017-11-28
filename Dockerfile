###########################################
# Dockerfile to build an nginx image
###########################################

# install base/parent image: FROM <image>[:<tag>]
FROM ubuntu:17.04

# This should place it after the FROM instruction: MAINTAINER <author's detail>
MAINTAINER Abir Brahem <abir.brahem@gmail.com>

# Sets the start up user ID or user Name in the new image: USER <UID>|<UName>
# By default, the containers will be launched with root as the user ID or UID . 
# Essentially, the USER instruction will modify the default user ID from root to the one specified in this instruction
USER www-data

# Run any command: RUN <command>, is always executed by /bin/sh -c
RUN echo 'PS1="\[\033[36m\]\u\[\033[m\]@\[\033[95;1m\]docker-application:\[\033[34m\]\w\[\033[m\]\$ "' >> ~/.bashrc
#RUN ["bash", "-c", "rm", "-rf", "/tmp/abc"] .
RUN echo "alias console='php bin/console'"  >> ~/.bashrc
RUN echo "alias phpunit='php bin/phpunit'" >>  ~/.bashrc

RUN apt-get update && apt-get install -y \
    nginx \
    php5 \
    php5-fpm \
    php5-intl \
    php5-mysql \
    php5-xdebug \
    curl \
    git \
	apt-get clean
RUN docker-php-ext-install zip intl curl xml

###################
### Nginx config ##
###################
# Remove default nginx config file
RUN rm /etc/nginx/sites-enabled/default

# ADD site config file: ADD <src1> <src2> ... <dst>, ADD instruction can handle the TAR files and the remote URLs in addition to COPY
ADD ./config/ngix/vhost.conf /etc/nginx/sites-available/
ADD ./config/ngix/nginx.conf /etc/nginx/

# Copy the files from the Docker host to the filesystem of the new image: COPY <src1> <src2> ... <dst>, <dst> should end by /
COPY config/vhost/vhost.conf /etc/apache2/sites-enabled/

# Enable site config
RUN ln -s /etc/nginx/sites-available/vhost.conf /etc/nginx/sites-enabled/vhost.conf


#####################
### PHP-FPM config ##
#####################
# Add the right Timezone
RUN sed -i -e "s/;\?date.timezone\s*=\s*.*/date.timezone = Europe\/Kiev/g" /etc/php5/fpm/php.ini
ADD ./www.conf /usr/local/etc/php-fpm.d/

# CMD instruction is executed when the container is launched from the newly created image, 
# whereas the RUN instruction is executed during the build time => for providing a default execution
# In the case of multiple CMD instructions, only the last CMD instruction would be effective!!!
CMD service php5-fpm start && nginx


#############################
### Symfony Project config ##
############################
RUN php -r "readfile('https://getcomposer.org/installer');" | php && chmod +x composer.phar && mv composer.phar /usr/local/bin/composer 

# Add global composer bin folder available
RUN export PATH="~/.composer/vendor/bin/:$PATH"
RUN composer install

# Set the working directory to /app, default it is / : WORKDIR <dirpath>
WORKDIR /www/var


ADD ./docker/docker.sh /docker.sh
# Crafting an image for running an application (entry point) during the complete life cycle of the container: ENTRYPOINT <command>
# The build system will ignore all the ENTRYPOINT instructions except the last one.
ENTRYPOINT ["/bin/bash", "/docker.sh"]



# Make port 80 available to the world outside this container: EXPOSE <port>[/<proto>] [<port>[/<proto>]...]
EXPOSE 80 443
# Define environment variable in the new image: ENV <key> <value>
ENV SYMFONY_ENV dev

#VOLUME <mountpoint>

# CMD ["<exec>", "<arg-1>", ..., "<arg-n>"]
# CMD ["python", "app.py"]

# Confirmation message
RUN echo "  [FINAL OK] Container is now available !"