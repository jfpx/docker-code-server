
HOME=/headless
PORT=8443

if [ -n "${APTPKG}" ]; then
  echo "install apt package ${APTPKG}"
  sudo apt-get update && sudo apt-get install -y ${APTPKG}
fi

if [ -n "${PIPPKG}" ]; then
  echo "install pip package ${PIPPKG}"
  sudo python3.7 -m pip install -U ${PIPPKG}
  #sudo pip3 install -U ${PIPPKG}
fi

if [ -n "${PASSWORD}" ]; then
  echo "starting with password, make sure se AUTH='--auth \"password\"'"
else
  echo "starting with no password"
fi

if [ -n "${TOKEN}" ]; then
  echo "create tunnel to ngrok, no port need to open in container, use following admin login to access"
  
  echo "authtoken: $TOKEN" >> ${HOME}/ngrok.yml
  echo "tunnels:" >> ${HOME}/ngrok.yml
  echo "  codeserver:" >> ${HOME}/ngrok.yml
  echo "    proto: http" >> ${HOME}/ngrok.yml
  echo "    addr: 8443" >> ${HOME}/ngrok.yml
  echo "    auth: \"admin:${SUDO_PASSWORD}\"" >> ${HOME}/ngrok.yml
  echo "  vnc:" >> ${HOME}/ngrok.yml
  echo "    proto: http" >> ${HOME}/ngrok.yml
  echo "    addr: 6901" >> ${HOME}/ngrok.yml
  echo "    auth: \"admin:${SUDO_PASSWORD}\"" >> ${HOME}/ngrok.yml
  ngrok start -config ${HOME}/ngrok.yml --all > /dev/null &

  sleep 5
  #echo "list all tunnels:"
  #VSCODEWEB=$(curl --silent http://localhost:4040/api/tunnels | jq -r ".tunnels[0].public_url")
  #curl --silent http://localhost:4040/api/tunnels | jq -r ".tunnels[0].public_url"
  #curl --silent http://localhost:4040/api/tunnels | jq -r ".tunnels[1].public_url"
  #echo "vs code 8443 tunnel: " $VSCODEWEB
  if [ -n "${REDIRECT}" ]; then
    #sudo python3 /dockerstartup/portforward.py ${REDIRECT} &
    pkill -f portforward
    sudo /dockerstartup/portforward ${REDIRECT} &
  fi
else
  echo "token is not provided for ngrok, make sure open port 8443 to access"
fi

/usr/bin/code-server \
      --port ${PORT} \
			--user-data-dir ${HOME}/data \
			--extensions-dir ${HOME}/extensions \
			--disable-telemetry \
			--disable-updates \
			${AUTH} ${HOME}/workspace &

/dockerstartup/vnc_startup.sh
