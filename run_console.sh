# run from inside the repo directory


PWD=$(pwd)
PICO_8_PATH=$1
# home dir is where the pico 8 config files are generated
HOME_DIR=$PWD/pico8-home
STARTUP_CART=$HOME_DIR/carts/lab-console.p8
BACKEND_SCREEN_NAME=p8_console_backend
BACKEND_SCRIPT_PATH=$PWD/backend.py

# terminal colors from https://en.wikipedia.org/wiki/ANSI_escape_code
CYAN='\033[0;36m'
NC='\033[0m' # No Color


echo "Running Pico-8 from: $PICO_8_PATH"
echo "Using startup cart: $STARTUP_CART"
echo "Using home dir: $HOME_DIR"

mkdir -p $HOME_DIR

# kill backend screen if one is running
screen -X -S $BACKEND_SCREEN_NAME quit

# start backend screen
screen -dmS $BACKEND_SCREEN_NAME python $BACKEND_SCRIPT_PATH

echo "p8 console backend started on screen: $BACKEND_SCREEN_NAME"

# run pico-8, using our custom home directory and console startup cart
$PICO_8_PATH -home $HOME_DIR -run $STARTUP_CART

# kill backend screen and process
screen -X -S $BACKEND_SCREEN_NAME quit

echo 
echo -e "${CYAN}==================${NC}"
echo -e "Alt-Ctrl-Lab Pico-8 console has shut down."
echo -e "Type ${CYAN}exit${NC} to logout, then log back in with username ${CYAN}p8_console_user${NC} to restart"
echo -e "${CYAN}==================${NC}"