
alias sudo="sudo -S"

(echo ${PASSWD} | sudo echo 'ilvin  ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/ilvin) \
&& (echo ${PASSWD} | sudo chmod 0440 /etc/sudoers.d/ilvin)




