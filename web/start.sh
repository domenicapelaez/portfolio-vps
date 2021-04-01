#!/bin/bash
set -e


config_hosts(){
    echo  ${HOSTNAME} > /etc/hostname
    cat /root/addhosts >> /etc/hosts
    #hostname ${HOSTNAME}
}

newUser(){
    # ---------------- creación de usuario 
    echo "MAQ2-->usuarioBD-->${USUARIO}" > /root/datos.txt

    useradd -rm -d /home/"${USUARIO}" -s /bin/bash "${USUARIO}" 
    echo "root:${PASSWD}" | chpasswd
    echo "${USUARIO}:${PASSWD}" | chpasswd
}

config_Sudoers(){
    echo "${USUARIO} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
}

config_ssh(){
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
    if [ ! -d /home/${USUARIO}/.ssh ]
    then
        mkdir /home/${USUARIO}/.ssh
        cat /root/id_rsa.pub >> /home/${USUARIO}/.ssh/authorized_keys
    fi
    /etc/init.d/ssh start
}

config_apache(){
    #sed -i "s/\${APACHE_RUN_USER}/\www-data/g" /etc/apache2/apache2.conf
    #sed -i "s/${APACHE_RUN_DIR}/$/g" /etc/apache2/apache2.conf
    #asocia las variables del apache2.conf con los valores definidos en /etc/apache2/envars
    source /etc/apache2/envvars
    # con apache2 -S veremos los valores del las variables asociadas
    # Apache gets grumpy about PID files pre-existing
    #rm -f /var/run/apache2/apache2.pid
}

config_vhost(){
    service apache2 start
    cd /etc/apache2/sites-available
    touch ${PROYECTO}.conf
    echo "<VirtualHost *:80>" > ${PROYECTO}.conf
    echo "DocumentRoot /var/www/html/${PROYECTO}" >> ${PROYECTO}.conf
    echo "ServerName domenicapelaez.site" >> ${PROYECTO}.conf
    echo "ServerAlias www.domenicapelaez.site" >> ${PROYECTO}.conf
    echo "<Directory /var/www/html/${PROYECTO}>" >> ${PROYECTO}.conf
    echo "    AllowOverride All" >> ${PROYECTO}.conf
    echo "    Require all granted" >> ${PROYECTO}.conf
    echo "</Directory>" >> ${PROYECTO}.conf
    echo "</VirtualHost>" >> ${PROYECTO}.conf
    a2ensite ${PROYECTO}.conf
    service apache2 reload
    cd /etc/apache2/sites-enabled
    a2ensite ${PROYECTO}.conf
    service apache2 reload
}

config_git(){
    cd /var/www/html
    if [ ! -d  /var/www/html/.git/ ];
    then 
        echo "no existe .git"
        git init
        git remote add origin https://usuario:pass@github.com/usuario/dist.git
        git checkout -b master
        git config core.sparseCheckout true
        echo "${PROYECTO}/" >> .git/info/sparse-checkout
        git pull origin master
    fi
    #rm -rf ./git
}

main(){
    config_hosts
    newUser
    config_Sudoers
    config_ssh
    config_apache
    config_git
    config_vhost
    tail -f /dev/null
}

main


# Start Apache in foreground
/usr/sbin/apache2 -DFOREGROUND

