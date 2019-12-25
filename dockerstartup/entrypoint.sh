
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


sudo chown default ${HOME}/workspace/.vscode/settings.json 

/dockerstartup/vnc_startup.sh &

/usr/bin/code-server \
      --port ${PORT} \
			--user-data-dir ${HOME}/data \
			--extensions-dir ${HOME}/extensions \
			--disable-telemetry \
			--disable-updates \
			${AUTH} ${HOME}/workspace &

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
  echo "started ngrok service"
  
  sleep 60
  echo "list all tunnels:"
  curl --silent http://localhost:4040/api/tunnels | jq -r ".tunnels[0].public_url"
  curl --silent http://localhost:4040/api/tunnels | jq -r ".tunnels[1].public_url"
  curl --silent http://localhost:4040/api/tunnels | jq -r ".tunnels[2].public_url"
  curl --silent http://localhost:4040/api/tunnels | jq -r ".tunnels[3].public_url"
  curl --silent http://localhost:4040/api/tunnels | jq -r ".tunnels[4].public_url"
  curl --silent http://localhost:4040/api/tunnels | jq -r ".tunnels[5].public_url"
  if [ -n "${REDIRECT}" ]; then
    sudo pkill -f portforward
    sudo /dockerstartup/portforward ${REDIRECT} &
    echo "redirect ${REDIRECT} started"
  else
    echo "no redirect port set"
  fi
else
  echo "token is not provided for ngrok, make sure open port 8443 to access"
fi


if [ -n "${CUSTOM}" ]; then
  sudo chmod a+w ${HOME}/workspace/default/startup/codeserver/entrypoint.sh
  exec ${HOME}/workspace/default/startup/codeserver/entrypoint.sh
else
  echo "no custom script found, complete"
  tail -f /dev/null
fi

