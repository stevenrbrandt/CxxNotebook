PORT=8004
TOKEN=
echo "Starting notebook"
echo jupyter notebook --ip=0.0.0.0 --port=${PORT} --no-browser --NotebookApp.token="${TOKEN}"
jupyter notebook --ip=0.0.0.0 --port=${PORT} --no-browser --NotebookApp.token="${TOKEN}"
