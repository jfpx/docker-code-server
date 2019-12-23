
HOME=/headless
PORT=8443

if [ -n "${PASSWORD}" ]; then
  echo "starting with password, make sure se AUTH='--auth \"password\"'"
else
  echo "starting with no password"
fi

if [ -n "${TOKEN}" ]; then
  echo "create tunnel to ngrok, no port need to open in container, use following admin login to access"
  ngrok http -auth="admin:${SUDO_PASSWORD}" -authtoken ${TOKEN} ${PORT} > /dev/null &
  sleep 5
  VSCODEWEB=$(curl http://localhost:4040/api/tunnels | jq -r ".tunnels[0].public_url")
  echo "NGROK_ADMIN_LOGIN: " $VSCODEWEB
  if [ -n "${REDIRECT}" ]; then
    pkill -f redirect
    ${HOME}/toolset/redirect/redirect $VSCODEWEB ${REDIRECT} true &  
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
			${AUTH} /config/workspace &

/dockerstartup/vnc_startup.sh
